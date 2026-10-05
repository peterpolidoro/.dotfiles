"""Policy repair tests; privilege operations affect only a disposable tree."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


REPO = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("guix_apparmor", REPO / ".local/libexec/guix-apparmor.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class AppArmorSetup(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="apparmor tests ")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.policy = self.root / "etc/apparmor.d"
        self.source = self.root / "Guix source"
        self.backups = self.root / "backups"
        self.enabled = self.root / "enabled"
        self.enabled.write_text("Y\n")
        for directory in (self.policy, self.source):
            (directory / "tunables").mkdir(parents=True)
            (directory / "local").mkdir()
            (directory / "tunables/guix").write_text("@{guix_storedir} = /gnu/store\n")
            (directory / "guix").write_text("profile guix /gnu/store/*/bin/guix { }\n")
            (directory / "guix-daemon").write_text(
                "profile guix-daemon /gnu/store/*/bin/guix-daemon {\n"
                "include if exists <local/guix-daemon>\n}\n")
        self.local = self.policy / helper.LOCAL
        self.local.write_text("# Host-specific rule\n/opt/site/ r,\n")
        self.original = self.local.read_text()
        self.privileged = []
        self.compiles = []
        for name, value in [("POLICY_DIR", self.policy), ("BACKUPS", self.backups),
                            ("ENABLED", self.enabled), ("GUIX_SYSTEM", self.root / "guix-system")]:
            self.enterContext(patch.object(helper, name, value))
        self.enterContext(patch.object(helper, "parser_path", return_value="apparmor_parser"))
        self.enterContext(patch.object(helper, "run", side_effect=self.compile))
        self.enterContext(patch.object(helper, "privileged", side_effect=self.install))
        self.output = self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.errors = self.enterContext(contextlib.redirect_stderr(io.StringIO()))

    def compile(self, *args, **kwargs):
        self.compiles.append(args)
        self.assertIn("--skip-kernel-load", args)
        self.assertIn("--skip-cache", args)
        self.assertEqual(Path(args[-2]).parent, Path(args[-1]).parent)
        self.assertTrue((Path(args[-2]).parent / helper.LOCAL).is_file())

    def install(self, *args):
        self.privileged.append(args)
        if args[0] == "install" and "-d" in args:
            Path(args[-1]).mkdir(parents=True, exist_ok=True)
        elif args[0] in ("install", "cp"):
            target = Path(args[-1])
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(args[-2], target)
        else:
            self.assertEqual(args[0], "apparmor_parser")
            self.assertIn("--replace", args)
            self.assertIn("--skip-cache", args)

    def setup(self, *args):
        return helper.main(["--source", str(self.source), "--daemon-mode", "root", *args])

    def test_dry_run_compiles_candidate_but_never_writes_or_escalates(self):
        self.assertEqual(self.setup("--dry-run"), 0, self.errors.getvalue())
        self.assertEqual(self.local.read_text(), self.original)
        self.assertFalse(self.backups.exists())
        self.assertEqual(self.privileged, [])
        self.assertEqual(len(self.compiles), 1)
        self.assertIn("+capability setuid,", self.output.getvalue())

    def test_root_repair_preserves_site_rules_and_backs_up_once(self):
        self.assertEqual(self.setup(), 0, self.errors.getvalue())
        self.assertTrue(self.local.read_text().startswith(self.original))
        self.assertIn("capability setuid,", self.local.read_text())
        backups = list(self.backups.glob("*/local/guix-daemon"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), self.original)
        self.assertEqual(self.setup(), 0)
        self.assertEqual(self.local.read_text().count(helper.BEGIN), 1)
        self.assertEqual(len(list(self.backups.iterdir())), 1)
        self.assertFalse(any("systemctl" in call for call in self.privileged))

    def test_rootless_removes_only_managed_permission(self):
        self.local.write_text(self.original + "capability setuid, # manual\n")
        self.assertEqual(self.setup(), 0)
        self.assertEqual(self.setup("--daemon-mode", "rootless"), 0)
        text = self.local.read_text()
        self.assertIn("capability setuid, # manual", text)
        self.assertNotIn("capability setuid,\n", text)
        self.assertIn("no additional capabilities", text)

    def test_disabled_apparmor_and_guix_system_are_noops(self):
        self.enabled.write_text("N\n")
        self.assertEqual(self.setup(), 0)
        self.enabled.write_text("Y\n")
        helper.GUIX_SYSTEM.mkdir()
        self.assertEqual(self.setup(), 0)
        self.assertEqual(self.compiles, [])
        self.assertEqual(self.privileged, [])

    def test_parser_failure_leaves_installed_files_untouched(self):
        with patch.object(helper, "run", side_effect=subprocess.CalledProcessError(1, "parser")):
            self.assertEqual(self.setup(), 1)
        self.assertEqual(self.local.read_text(), self.original)
        self.assertEqual(self.privileged, [])

    def test_missing_source_and_missing_include_fail_before_changes(self):
        (self.source / "guix-daemon").write_text("profile guix-daemon { }\n")
        self.assertEqual(self.setup(), 1)
        (self.source / "guix-daemon").unlink()
        self.assertEqual(self.setup(), 1)
        self.assertEqual(self.privileged, [])

    def test_malformed_managed_block_is_not_overwritten(self):
        self.local.write_text(self.original + helper.BEGIN)
        self.assertEqual(self.setup(), 1)
        self.assertEqual(self.privileged, [])

    def test_symlinked_policy_and_disabled_profile_fail_before_changes(self):
        self.local.unlink()
        self.local.symlink_to(self.source / "guix")
        self.assertEqual(self.setup(), 1)
        self.local.unlink()
        (self.policy / "disable").mkdir()
        (self.policy / "disable/guix-daemon").symlink_to("../guix-daemon")
        self.assertEqual(self.setup(), 1)
        self.assertEqual(self.privileged, [])

    def test_reload_failure_returns_failure_and_retains_backup(self):
        install = self.install

        def fail_reload(*args):
            if args[0] == "apparmor_parser":
                raise subprocess.CalledProcessError(1, args)
            install(*args)

        with patch.object(helper, "privileged", side_effect=fail_reload):
            self.assertEqual(self.setup(), 1)
        self.assertEqual(len(list(self.backups.glob("*/local/guix-daemon"))), 1)
        self.assertIn("backup directory", self.errors.getvalue())

    def test_actual_parser_accepts_candidate_and_preserved_local_rules(self):
        parser = "/usr/sbin/apparmor_parser"
        if not os.access(parser, os.X_OK):
            self.skipTest("AppArmor parser not installed")
        with patch.object(helper, "parser_path", return_value=parser), patch.object(
                helper, "run", side_effect=lambda *args, **kw: subprocess.run(
                    [str(arg) for arg in args], check=True, **kw)):
            self.assertEqual(self.setup("--dry-run"), 0, self.errors.getvalue())
        self.assertEqual(self.privileged, [])


class DaemonMode(unittest.TestCase):
    def mode(self, user, pid="0", status=None):
        output = subprocess.CompletedProcess([], 0, f"LoadState=loaded\nUser={user}\nMainPID={pid}\n")
        with patch.object(helper, "run", return_value=output), patch.object(Path, "read_text", return_value=status):
            return helper.daemon_mode()

    def test_root_and_rootless_configuration(self):
        for user in ("", "root", "0"):
            self.assertEqual(self.mode(user), "root")
        self.assertEqual(self.mode("guix-daemon"), "rootless")

    def test_root_daemon_still_running_after_rootless_service_change(self):
        self.assertEqual(self.mode("guix-daemon", "123", "Uid:\t0\t0\t0\t0\n"), "root")
        self.assertEqual(self.mode("guix-daemon", "123", "Uid:\t900\t900\t900\t900\n"), "rootless")

    def test_missing_service_is_an_error(self):
        result = subprocess.CompletedProcess([], 0, "LoadState=not-found\nUser=\nMainPID=0\n")
        with patch.object(helper, "run", return_value=result), self.assertRaises(ValueError):
            helper.daemon_mode()


if __name__ == "__main__":
    unittest.main()
