"""Exercise LXQt setup in disposable config trees, never in the live desktop."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("lxqt_settings", REPO / ".local/libexec/lxqt-settings.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class LXQtSetup(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="lxqt settings ")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.config = self.root / "config"
        self.defaults = self.root / "xdg"
        self.apps = self.root / "Guix desktop/share/applications"
        self.apps.mkdir(parents=True)
        (self.apps / "kitty.desktop").write_text("[Desktop Entry]\nName=Kitty\n")
        self.enterContext(patch.dict(os.environ, XDG_CONFIG_HOME=str(self.config),
                                     XDG_CONFIG_DIRS=str(self.defaults)))
        self.enterContext(patch.object(helper, "application_dirs", return_value=[self.apps]))
        self.enterContext(patch.object(helper.shutil, "which", side_effect=lambda program: "/bin/" + program))
        self.writers = self.enterContext(patch.object(helper, "running_settings_writers", return_value=[]))
        self.output = self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.errors = self.enterContext(contextlib.redirect_stderr(io.StringIO()))

    def file(self, relative, text):
        path = self.config / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def snapshot(self):
        return {str(path.relative_to(self.config)): path.read_bytes()
                for path in self.config.rglob("*") if path.is_file()}

    def apply(self, *args):
        return helper.main(list(args))

    def test_preview_does_not_create_config_or_backups(self):
        self.assertEqual(self.apply("--dry-run"), 0, self.errors.getvalue())
        self.assertFalse(self.config.exists())
        self.assertIn("window_manager=xfwm4", self.output.getvalue())
        self.writers.assert_not_called()

    def test_fresh_laptop_uses_local_launchers_and_keeps_distro_brightness_keys(self):
        # Debian 13 installs the default inside a directory with the same name.
        default = self.defaults / "lxqt/globalkeyshortcuts.conf/globalkeyshortcuts.conf"
        default.parent.mkdir(parents=True)
        default.write_text("[XF86MonBrightnessUp.1]\nExec=lxqt-config-brightness, -i\n")
        self.assertEqual(self.apply(), 0, self.errors.getvalue())
        panel = helper.ini((self.config / "lxqt/panel.conf").read_text())
        self.assertEqual(panel["General"]["panels"], "panel1, panel2")
        self.assertEqual(panel["panel1"]["position"], "Bottom")
        self.assertEqual(panel["panel2"]["position"], "Top")
        self.assertNotIn("screen", panel["panel1"])
        self.assertEqual(panel["quicklaunch"]["apps\\size"], "1")
        self.assertEqual(panel["quicklaunch"]["apps\\1\\desktop"], str(self.apps / "kitty.desktop"))
        keys = helper.ini((self.config / "lxqt/globalkeyshortcuts.conf").read_text())
        self.assertEqual(keys["XF86MonBrightnessUp.1"]["Exec"], "lxqt-config-brightness, -i")
        self.assertEqual(sum(values.get("Exec") == "kitty" for values in keys.values()), 2)
        self.assertFalse((self.config / "lxqt/lxqt-powermanagement.conf").exists())
        root = ET.parse(self.config / "xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml")
        self.assertEqual(root.find(".//property[@name='workspace_count']").get("value"), "6")

    def test_host_settings_backups_and_repeated_apply(self):
        power = self.file("lxqt/lxqt-powermanagement.conf", "[General]\nenableLidWatcher=true\n")
        monitors = self.file("lxqt/lxqt-config-monitor.conf", "[Monitor]\noutput=eDP-1\n")
        displays = self.file("xfce4/xfconf/xfce-perchannel-xml/displays.xml", "<host-display/>\n")
        geometry = self.file("lxqt/filedialog.conf", "[Sizes]\nWindowSize=@Size(800 400)\n[View]\nShowHidden=false\n")
        original = geometry.read_bytes()
        self.file("lxqt/session.conf", "[General]\nwindow_manager=openbox\n[Environment]\nQT_SCALE_FACTOR=2\n")
        self.file("lxqt/panel.conf", "[General]\npanels=panel1, panel_{old}\n[panel1]\nposition=Bottom\nscreen=1\n[panel_%7Bold%7D]\nposition=Top\nscreen=2\n")
        before = {path: path.read_bytes() for path in (power, monitors, displays)}
        self.assertEqual(self.apply(), 0, self.errors.getvalue())
        for path, content in before.items():
            self.assertEqual(path.read_bytes(), content)
        self.assertIn("QT_SCALE_FACTOR=2", (self.config / "lxqt/session.conf").read_text())
        self.assertIn("WindowSize=@Size(800 400)", geometry.read_text())
        panel = helper.ini((self.config / "lxqt/panel.conf").read_text())
        self.assertEqual(panel["panel1"]["screen"], "1")
        self.assertEqual(panel["panel2"]["screen"], "2")
        backup = geometry.with_name(geometry.name + ".before-dotfiles-lxqt")
        self.assertEqual(backup.read_bytes(), original)
        first = self.snapshot()
        self.assertEqual(self.apply(), 0, self.errors.getvalue())
        self.assertEqual(self.snapshot(), first)
        geometry.write_text(geometry.read_text().replace("ShowHidden=true", "ShowHidden=false"))
        self.assertEqual(self.apply(), 0, self.errors.getvalue())
        self.assertEqual(backup.read_bytes(), original)

    def test_shortcuts_consolidate_duplicates_without_losing_custom_bindings(self):
        path = self.file("lxqt/globalkeyshortcuts.conf", "[Control%2BAlt%2BT.1]\nExec=qterminal\n[Control%2BAlt%2BT.5]\nExec=kitty\n[Meta%2BX.6]\nExec=my-command\n")
        qtxdg = self.file("lxqt-qtxdg.conf", "TerminalEmulator=qterminal.desktop\nBrowser=firefox.desktop\n")
        self.assertEqual(self.apply(), 0, self.errors.getvalue())
        config = helper.ini(path.read_text())
        self.assertEqual(sum(section.startswith("Control%2BAlt%2BT.") for section in config), 1)
        self.assertEqual(config["Meta%2BX.6"]["Exec"], "my-command")
        self.assertIn("Browser=firefox.desktop", qtxdg.read_text())

    def test_running_desktop_prevents_any_writes(self):
        self.writers.return_value = ["lxqt-panel", "xfconfd"]
        self.assertEqual(self.apply(), 1)
        self.assertFalse(self.config.exists())
        self.assertIn("Log out", self.errors.getvalue())

    def test_missing_window_manager_prevents_any_writes(self):
        with patch.object(helper.shutil, "which", return_value=None):
            self.assertEqual(self.apply(), 1)
        self.assertFalse(self.config.exists())

    def test_symlink_or_invalid_input_prevents_partial_updates(self):
        linked = self.file("lxqt/panel.conf", "[General]\npanels=panel1\n")
        destination = self.root / "external-panel.conf"
        linked.rename(destination)
        linked.symlink_to(destination)
        self.assertEqual(self.apply(), 1)
        self.assertFalse((self.config / "lxqt/session.conf").exists())
        self.assertEqual(destination.read_text(), "[General]\npanels=panel1\n")
        linked.unlink()
        linked.write_text("not a settings file\n")
        self.assertEqual(self.apply(), 1)
        self.assertFalse((self.config / "lxqt/session.conf").exists())


if __name__ == "__main__":
    unittest.main()
