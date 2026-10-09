"""Apply portable LXQt preferences; maintained directly, not tangled.

LXQt and xfconf rewrite their files, so keep writable local copies rather
than Stow links. Run while logged out of the graphical session.
"""

import argparse
import configparser
import difflib
import io
import os
from pathlib import Path
import shutil
import sys
import tempfile
from urllib.parse import unquote
import xml.etree.ElementTree as ET


PRESETS = Path(__file__).resolve().parents[1] / "share/dotfiles/lxqt"


def ini(text=""):
    config = configparser.RawConfigParser(delimiters=("=",), strict=False)
    config.optionxform = str
    config.read_string(text)
    return config


def serialize(config):
    output = io.StringIO()
    config.write(output, space_around_delimiters=False)
    return output.getvalue()


def read(path):
    return path.read_text() if path.exists() else ""


def merge(original, preferences):
    config = ini(original)
    changed = False
    for section in preferences.sections():
        if not config.has_section(section):
            config.add_section(section)
        for key, value in preferences[section].items():
            if config[section].get(key) != value:
                config[section][key] = value
                changed = True
    return serialize(config) if changed else original


def application_dirs():
    home = Path.home()
    data = [Path(os.environ.get("XDG_DATA_HOME", home / ".local/share"))]
    data += [home / path for path in (
        ".guix-extra-profiles/desktop/desktop/share", ".guix-home/profile/share",
        ".guix-profile/share")]
    data += [Path(path) for path in os.environ.get(
        "XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") if path]
    return [directory / "applications" for directory in data]


def panel(original):
    config = ini((PRESETS / "panel.conf").read_text())
    previous = ini(original)
    # Retain this machine's output selection, matched by panel edge. The
    # preset contains no output names, resolutions, or multi-monitor layout.
    old_panels = [name.strip() for name in previous.get(
        "General", "panels", fallback="panel1").split(",")]
    for target in ("panel1", "panel2"):
        for section in previous.sections():
            if unquote(section) not in old_panels:
                continue
            if previous.get(section, "position", fallback="Bottom") != config[target]["position"]:
                continue
            for key in ("screen", "monitor", "screenName"):
                if key in previous[section]:
                    config[target][key] = previous[section][key]
            break
    # Resolve Guix and distro launchers on this host, not under /home/peter.
    launch = config["quicklaunch"]
    names = [launch[f"apps\\{i}\\desktop"] for i in range(1, int(launch["apps\\size"]) + 1)]
    for key in list(launch):
        if key.startswith("apps\\"):
            del launch[key]
    paths = []
    for name in names:
        found = next((directory / name for directory in application_dirs()
                      if (directory / name).is_file()), None)
        if found:
            paths.append(found)
        else:
            print(f"Skipping unavailable panel launcher: {name}", file=sys.stderr)
    for index, path in enumerate(paths, 1):
        launch[f"apps\\{index}\\desktop"] = str(path)
    launch["apps\\size"] = str(len(paths))
    return serialize(config)


def shortcuts(original, config_dirs):
    # When no user file exists, seed distro shortcuts (notably laptop
    # brightness keys) before adding our two terminal bindings.
    if not original:
        for directory in config_dirs:
            base = directory / "lxqt/globalkeyshortcuts.conf"
            source = base / base.name if base.is_dir() else base
            if source.is_file():
                original = source.read_text()
                break
    config = ini(original)
    before = serialize(config)
    for binding in ("Control%2BAlt%2BT", "Meta%2BReturn"):
        matches = [section for section in config.sections()
                   if section.rsplit(".", 1)[0] == binding]
        for section in matches[1:]:
            config.remove_section(section)
        suffixes = [int(section.rsplit(".", 1)[-1]) for section in config.sections()
                    if section.rsplit(".", 1)[-1].isdigit()]
        section = matches[0] if matches else f"{binding}.{max(suffixes, default=0) + 1}"
        config[section] = {"Comment": "Kitty", "Enabled": "true", "Exec": "kitty"}
    updated = serialize(config)
    return original if updated == before else updated


def terminal(original):
    # qtxdg stores this key outside a section. Preserve unrelated settings.
    lines = original.splitlines()
    end = next((i for i, line in enumerate(lines) if line.startswith("[")), len(lines))
    if [line for line in lines[:end] if line.startswith("TerminalEmulator=")] == ["TerminalEmulator=kitty.desktop"]:
        return original
    head = [line for line in lines[:end] if not line.startswith("TerminalEmulator=")]
    return "\n".join([*head, "TerminalEmulator=kitty.desktop", *lines[end:]]) + "\n"


def window_manager(original):
    root = ET.fromstring(original) if original else ET.Element(
        "channel", name="xfwm4", version="1.0")
    changed = False
    general = root.find("./property[@name='general']")
    if general is None:
        general = ET.SubElement(root, "property", name="general", type="empty")
    # The differences from Debian's xfwm4 defaults on the source desktop.
    preferences = {"theme": ("string", "Default"), "workspace_count": ("int", "6"),
                   "repeat_urgent_blink": ("bool", "false"),
                   "urgent_blink": ("bool", "false"), "show_dock_shadow": ("bool", "true")}
    for name, (kind, value) in preferences.items():
        prop = general.find(f"./property[@name='{name}']")
        if prop is None:
            prop = ET.SubElement(general, "property", name=name)
        if prop.get("type") != kind or prop.get("value") != value:
            prop.set("type", kind)
            prop.set("value", value)
            changed = True
    if not changed:
        return original
    ET.indent(root, space="  ")
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="unicode") + "\n"


def running_settings_writers():
    names = {"lxqt-session", "lxqt-panel", "lxqt-globalkeys", "pcmanfm-qt", "xfconfd", "xfwm4"}
    active = set()
    for process in Path("/proc").glob("[0-9]*"):
        try:
            if process.stat().st_uid == os.getuid():
                name = (process / "comm").read_text().strip()
                if name in names:
                    active.add(name)
        except (FileNotFoundError, ProcessLookupError):
            pass
    return sorted(active)


def changes(config_home, config_dirs):
    result = {}
    for relative in ("lxqt/session.conf", "lxqt/lxqt.conf", "lxqt/filedialog.conf",
                     "pcmanfm-qt/lxqt/settings.conf"):
        path = config_home / relative
        result[path] = merge(read(path), ini((PRESETS / relative).read_text()))
    for relative, transform in (
        ("lxqt/panel.conf", panel),
        ("lxqt/globalkeyshortcuts.conf", lambda text: shortcuts(text, config_dirs)),
        ("lxqt-qtxdg.conf", terminal),
        ("xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml", window_manager),
    ):
        path = config_home / relative
        result[path] = transform(read(path))
    return {path: content for path, content in result.items() if content != read(path)}


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    backup = path.with_name(path.name + ".before-dotfiles-lxqt")
    if path.exists() and not backup.exists():
        shutil.copy2(path, backup)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(content)
        if path.exists():
            shutil.copymode(path, temporary)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="show diffs without writing")
    args = parser.parse_args(argv)
    try:
        config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
        config_dirs = [Path(path) for path in os.environ.get("XDG_CONFIG_DIRS", "/etc/xdg").split(":") if path]
        proposed = changes(config_home, config_dirs)
        # Validate every destination before making the first change.
        for path in proposed:
            if any(parent.is_symlink() for parent in (path, *path.parents)):
                raise ValueError(f"Expected writable local settings, found a symlink: {path}")
        if args.dry_run:
            for path, content in proposed.items():
                print("".join(difflib.unified_diff(read(path).splitlines(True), content.splitlines(True),
                                                 fromfile=str(path), tofile=str(path) + " (proposed)")), end="")
            print(f"{len(proposed)} file(s) would change; no settings written.")
            return 0
        if proposed:
            active = running_settings_writers()
            if active:
                raise ValueError("Log out of the graphical session and run from a TTY; active: " + ", ".join(active))
            for program in ("lxqt-session", "xfwm4", "kitty"):
                if not shutil.which(program):
                    raise ValueError(f"Missing {program}; install LXQt/xfwm4 and activate the Guix desktop profile first.")
        for path, content in proposed.items():
            write(path, content)
            print(f"Updated {path}")
        print(f"LXQt preferences applied ({len(proposed)} changed files). Log in to LXQt to load them.")
        return 0
    except (OSError, ValueError, configparser.Error, ET.ParseError) as error:
        print(f"setup-lxqt: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
