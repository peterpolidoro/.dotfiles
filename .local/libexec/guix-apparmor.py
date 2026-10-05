"""Synchronize Guix's AppArmor policy without restarting the daemon.

Maintained directly; Systems.org generates the setup-guix-apparmor launcher.
Only the daemon's local compatibility block is owned by dotfiles.
"""

import argparse
import datetime
import difflib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


POLICY_DIR = Path("/etc/apparmor.d")
SOURCE = Path("/var/guix/profiles/per-user/root/current-guix/etc/apparmor.d")
ENABLED = Path("/sys/module/apparmor/parameters/enabled")
GUIX_SYSTEM = Path("/run/current-system")
BACKUPS = Path("/var/backups/guix-apparmor")
PACKAGED = ("tunables/guix", "guix-daemon", "guix")
LOCAL = "local/guix-daemon"
BEGIN = "# BEGIN dotfiles Guix daemon compatibility\n"
END = "# END dotfiles Guix daemon compatibility\n"


def run(*args, **kwargs):
    return subprocess.run([str(arg) for arg in args], check=True, **kwargs)


def privileged(*args):
    return run(*args) if os.geteuid() == 0 else run("sudo", *args)


def daemon_mode():
    """Cover both the configured service and a daemon not yet restarted."""
    result = run("systemctl", "show", "guix-daemon.service", "--no-pager",
                 "-p", "LoadState", "-p", "User", "-p", "MainPID",
                 capture_output=True, text=True)
    fields = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    if fields.get("LoadState") != "loaded" or "User" not in fields:
        raise ValueError("Cannot identify the Guix service; use --daemon-mode root or rootless.")
    mode = "root" if fields["User"] in ("", "root", "0") else "rootless"
    pid = fields.get("MainPID", "0")
    if pid != "0":
        try:
            status = Path(f"/proc/{int(pid)}/status").read_text()
            uid = next(line for line in status.splitlines() if line.startswith("Uid:"))
            if uid.split()[2] == "0":
                mode = "root"
        except (OSError, StopIteration) as error:
            raise ValueError("Cannot inspect the running daemon; use --daemon-mode explicitly.") from error
    return mode


def local_rules(original, mode):
    if BEGIN in original or END in original:
        if original.count(BEGIN) != 1 or original.count(END) != 1:
            raise ValueError("Malformed dotfiles compatibility block in local/guix-daemon.")
        before, rest = original.split(BEGIN)
        if END not in rest:
            raise ValueError("Malformed dotfiles compatibility block in local/guix-daemon.")
        _, after = rest.split(END)
        original = before + after
    block = BEGIN
    if mode == "root":
        block += "# Switching to the guixbuild users requires CAP_SETUID.\ncapability setuid,\n"
    else:
        block += "# Rootless daemon: no additional capabilities.\n"
    block += END
    return original + ("\n" if original and not original.endswith("\n") else "") + block


def parser_path():
    for candidate in ("/usr/sbin/apparmor_parser", "/sbin/apparmor_parser"):
        if os.access(candidate, os.X_OK):
            return candidate
    parser = shutil.which("apparmor_parser")
    if not parser:
        raise ValueError("AppArmor is enabled but apparmor_parser is missing; install your distro's AppArmor package.")
    return parser


def synchronize(source, mode, dry_run):
    parser = parser_path()
    for relative in PACKAGED:
        if not (source / relative).is_file():
            raise ValueError(f"Missing Guix policy: {source / relative}; use --source with a complete policy directory.")
    for profile in ("guix-daemon", "guix"):
        for directory in ("disable", "force-complain"):
            if os.path.lexists(POLICY_DIR / directory / profile):
                raise ValueError(f"{profile} is listed in {directory}; resolve that local override before setup.")
    daemon_policy = (source / "guix-daemon").read_text()
    if "include if exists <local/guix-daemon>" not in daemon_policy:
        raise ValueError("Guix's daemon policy lacks the local/guix-daemon include; refusing to install an ineffective fix.")

    original_local = (POLICY_DIR / LOCAL).read_text() if (POLICY_DIR / LOCAL).exists() else ""
    desired = {relative: (source / relative).read_bytes() for relative in PACKAGED}
    desired[LOCAL] = local_rules(original_local, mode).encode()
    changed = []
    for relative, content in desired.items():
        target = POLICY_DIR / relative
        # A symlinked local policy should keep its existing configuration owner.
        if target.is_symlink() or target.parent.is_symlink():
            raise ValueError(f"Refusing to replace symlinked policy {target}; update its owner instead.")
        old = target.read_bytes() if target.exists() else b""
        if not target.exists() or old != content:
            changed.append(relative)
            if dry_run:
                print("".join(difflib.unified_diff(
                    old.decode().splitlines(keepends=True), content.decode().splitlines(keepends=True),
                    fromfile=str(target), tofile=f"{target} (proposed)")), end="")

    print(f"Guix daemon mode: {mode}; policy source: {source}", flush=True)
    with tempfile.TemporaryDirectory(prefix="guix-apparmor-") as temporary:
        stage = Path(temporary) / "apparmor.d"
        # Resolve includes against a complete candidate tree, including site rules.
        shutil.copytree(POLICY_DIR, stage, ignore=shutil.ignore_patterns("cache", "disable", "force-complain"))
        for relative, content in desired.items():
            target = stage / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                target.unlink()  # Copied packaged policies may be mode 0444.
            target.write_bytes(content)
        run(parser, "--skip-kernel-load", "--skip-cache", "--warn=all",
            "--base", stage, "--Include", stage, stage / "guix-daemon", stage / "guix")
        print("Both candidate profiles compile successfully.", flush=True)
        if dry_run:
            print(f"Would install {len(changed)} changed file(s), save backups, and reload guix-daemon and guix.")
            return

        if changed:
            stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
            backup = BACKUPS / stamp
            privileged("install", "-d", "-m", "0700", backup)
            for relative in changed:
                target = POLICY_DIR / relative
                if target.exists():
                    privileged("install", "-d", "-m", "0700", (backup / relative).parent)
                    privileged("cp", "-a", "--", target, backup / relative)
            print(f"Previous files saved under {backup}; newly created files have no backup.", flush=True)
            for relative in changed:
                privileged("install", "-D", "-m", "0644", stage / relative, POLICY_DIR / relative)

        # Compile afresh: an old binary cache must not hide the local override.
        privileged(parser, "--replace", "--skip-cache", "--warn=all",
                   POLICY_DIR / "guix-daemon", POLICY_DIR / "guix")
        print("Guix AppArmor profiles reloaded. The daemon was not restarted.")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--dry-run", action="store_true", help="show differences and compile in a temporary directory; no sudo or system changes")
    parser.add_argument("--daemon-mode", choices=("auto", "root", "rootless"), default="auto",
                        help="auto checks the systemd service and running daemon")
    parser.add_argument("--source", type=Path, default=SOURCE, help="Guix's packaged apparmor.d directory")
    args = parser.parse_args(argv)
    try:
        if GUIX_SYSTEM.exists():
            print("Guix System: manage the daemon through the system configuration; skipping AppArmor setup.")
            return 0
        if not ENABLED.exists() or ENABLED.read_text().strip() != "Y":
            print("AppArmor is not enabled; no policy changes needed.")
            return 0
        mode = daemon_mode() if args.daemon_mode == "auto" else args.daemon_mode
        synchronize(args.source.resolve(), mode, args.dry_run)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Guix AppArmor setup failed: {error}", file=sys.stderr)
        print("No daemon restart was attempted. If installation had begun, use the printed backup directory to recover prior files.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
