"""Exercise update orchestration with fake Guix/sudo tools; never upgrade the host."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class UpgradeScripts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="upgrade scripts ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "dotfiles checkout"
        self.bin = self.repo / ".local/bin"
        self.bin.mkdir(parents=True)
        shutil.copytree(REPO / ".local/libexec", self.repo / ".local/libexec")
        for name in ["activate-profiles", "upgrade-profiles", "upgrade-system", "upgrade-guix-root",
                     "upgrade-guix-system", "upgrade-guix-user", "upgrade-workstation",
                     "upgrade-guix", "upgrade-all", "upgrade-dotfiles"]:
            shutil.copy2(REPO / ".local/bin" / name, self.bin / name)
        self.tools = self.root / "tools"
        self.tools.mkdir()
        self.log = self.root / "calls.jsonl"
        self.profiles = self.root / "extra profiles"
        for name in ["desktop", "emacs"]:
            (self.profiles / name).mkdir(parents=True)
        self.manifests = self.root / "manifests"
        self.manifests.mkdir()
        for name in ["desktop", "emacs", "music"]:
            (self.manifests / f"{name}.scm").write_text("(specifications->manifest '())\n")
        self.channels = self.root / "channels.scm"
        self.canonical = self.root / "canonical.scm"
        self.channels.write_text("pinned channels\n")
        self.canonical.write_text(self.channels.read_text())
        self.default_profile = self.root / "default profile"
        self.default_profile.mkdir()
        self.user_guix = self.root / "current/bin/guix"
        self.user_guix.parent.mkdir(parents=True)
        self.initial = self.make_tool("initial-guix", "initial-guix")
        self.pulled = self.make_tool("pulled-guix", "pulled-guix")
        self.user_guix.symlink_to(self.initial)
        self.make_tool("guix", "wrong-guix")
        for tool in ["sudo", "emacs", "make"]:
            self.make_tool(tool, tool)
        self.env = dict(os.environ, PATH=str(self.tools) + os.pathsep + os.environ["PATH"],
                        GUIX_UPDATE_GUIX=str(self.user_guix),
                        GUIX_UPDATE_CHANNELS=str(self.channels),
                        GUIX_UPDATE_CANONICAL_CHANNELS=str(self.canonical),
                        GUIX_UPDATE_PROFILE_ROOT=str(self.profiles),
                        GUIX_UPDATE_MANIFEST_DIR=str(self.manifests),
                        GUIX_UPDATE_DEFAULT_PROFILE=str(self.default_profile),
                        GUIX_UPDATE_SYSTEM_KIND="debian",
                        UPGRADE_TEST_LOG=str(self.log), UPGRADE_TEST_NEXT_GUIX=str(self.pulled))
        self.env.pop("UPGRADE_TEST_FAIL", None)

    def make_tool(self, name, role):
        path = self.tools / name
        path.write_text(f'''#!{sys.executable}
import json, os, sys
from pathlib import Path
role = {role!r}
with open(os.environ['UPGRADE_TEST_LOG'], 'a') as f:
    f.write(json.dumps([role, sys.argv[1:], os.getcwd()]) + '\\n')
if role == 'wrong-guix':
    sys.exit(91)
if os.environ.get('UPGRADE_TEST_FAIL') and os.environ['UPGRADE_TEST_FAIL'] in ' '.join(sys.argv[1:]):
    sys.exit(13)
if role == 'initial-guix' and sys.argv[1:2] == ['pull']:
    current = Path(os.environ['GUIX_UPDATE_GUIX'])
    current.unlink()
    current.symlink_to(os.environ['UPGRADE_TEST_NEXT_GUIX'])
''')
        path.chmod(0o755)
        return path

    def run_script(self, name, *args):
        return subprocess.run([str(self.bin / name), *args], env=self.env, cwd=self.root,
                              text=True, capture_output=True, timeout=10)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_only_requested_profile_with_spaces_in_paths(self):
        result = self.run_script("upgrade-profiles", "emacs")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(self.calls()[0][:2], ["initial-guix", ["package",
            f"--profile={self.profiles}/emacs/emacs", f"--manifest={self.manifests}/emacs.scm"]])

    def test_no_arguments_rebuilds_installed_profiles(self):
        result = self.run_script("upgrade-profiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 2)
        self.assertIn("desktop.scm", self.calls()[0][1][-1])
        self.assertIn("emacs.scm", self.calls()[1][1][-1])

    def test_missing_manifest_fails_before_any_profile_is_changed(self):
        result = self.run_script("upgrade-profiles", "emacs", "missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_empty_installation_does_not_pass_literal_glob_to_guix(self):
        shutil.rmtree(self.profiles)
        result = self.run_script("upgrade-profiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.profiles.exists())

    def test_activation_requires_and_respects_selection(self):
        result = self.run_script("activate-profiles")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])
        result = self.run_script("activate-profiles", "music")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn("music.scm", self.calls()[0][1][-1])
        self.assertTrue((self.profiles / "music").is_dir())

    def test_dry_run_previews_children_without_invoking_tools_or_mkdir(self):
        result = self.run_script("upgrade-workstation", "--dry-run", "--root-guix", "music")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("<apt> <full-upgrade>", result.stdout)
        self.assertIn("<-i> <guix> <pull>", result.stdout)
        self.assertIn(f"<--channels={self.channels}>", result.stdout)
        self.assertIn("music.scm", result.stdout)
        self.assertEqual(self.calls(), [])
        self.assertFalse((self.profiles / "music").exists())

    def test_workstation_uses_newly_pulled_user_guix_and_skips_root_by_default(self):
        result = self.run_script("upgrade-workstation")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertEqual(calls[0][1], ["apt", "update", "-y"])
        self.assertEqual([c[0] for c in calls if c[1][0] == "pull"], ["initial-guix"])
        packages = [c for c in calls if c[1][0] == "package"]
        self.assertEqual(len(packages), 3)
        self.assertTrue(all(c[0] == "pulled-guix" for c in packages))
        self.assertFalse(any(c[1][:3] == ["-i", "guix", "pull"] for c in calls))

    def test_targeted_user_update_leaves_default_and_other_profiles_alone(self):
        result = self.run_script("upgrade-guix-user", "emacs")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 2)
        self.assertEqual(self.calls()[1][0], "pulled-guix")
        self.assertIn("emacs.scm", self.calls()[1][1][-1])

    def test_apt_failure_stops_before_root_pull_or_user_changes(self):
        self.env["UPGRADE_TEST_FAIL"] = "apt full-upgrade"
        result = self.run_script("upgrade-workstation", "--root-guix")
        self.assertEqual(result.returncode, 13)
        self.assertEqual([c[1][1] for c in self.calls()], ["update", "full-upgrade"])

    def test_pull_failure_stops_before_profile_changes(self):
        self.env["UPGRADE_TEST_FAIL"] = "pull"
        result = self.run_script("upgrade-guix-user")
        self.assertEqual(result.returncode, 13)
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(self.calls()[0][1][0], "pull")

    def test_pin_drift_stops_before_even_apt_runs(self):
        self.channels.write_text("different pins\n")
        result = self.run_script("upgrade-workstation")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Channel files differ", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_legacy_name_preserves_root_update_through_symlink(self):
        link = self.root / "upgrade-link"
        link.symlink_to(self.bin / "upgrade-guix")
        result = subprocess.run([str(link), "emacs"], env=self.env, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(c[1] == ["-i", "guix", "pull"] for c in self.calls()))

    def test_guix_system_uses_selected_cli_and_avoids_foreign_distro_root_pull(self):
        self.env["GUIX_UPDATE_SYSTEM_KIND"] = "guix"
        config = self.root / "system config.scm"
        config.write_text("system config\n")
        self.env["GUIX_UPDATE_SYSTEM_CONFIG"] = str(config)
        result = self.run_script("upgrade-guix", "emacs")
        self.assertEqual(result.returncode, 0, result.stderr)
        sudo = [c[1] for c in self.calls() if c[0] == "sudo"]
        self.assertEqual(sudo, [[str(self.user_guix), "system", "reconfigure", str(config)]])

    def test_dotfiles_upgrade_runs_from_checkout_root(self):
        result = self.run_script("upgrade-dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([c[0] for c in self.calls()], ["emacs", "make"])
        self.assertTrue(all(c[2] == str(self.repo) for c in self.calls()))

    def test_bad_profile_names_and_options_fail_before_commands(self):
        for argument in ["../emacs", "a b", "--unknown"]:
            result = self.run_script("upgrade-profiles", argument)
            self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
