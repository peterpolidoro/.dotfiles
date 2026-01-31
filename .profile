# ~/.profile
# ----------------------------------------------------------------------
# Session / login environment (POSIX sh).
#
# This file is intended to be *portable* and safe to source from any POSIX
# shell. It is commonly read by:
#   - sh/bash login shells
#   - graphical login/session startup (depends on display manager / PAM)
#
# Keep this file focused on environment variables and PATH setup.
# Put interactive-only things (aliases, prompt tweaks, completions) in
# ~/.bashrc or ~/.bash_aliases.
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Guix: locale archive path (GUIX_LOCPATH)
# ----------------------------------------------------------------------
# Prefer a Guix-provided locale archive (from your "desktop" profile),
# if it exists. This helps applications find locales when using Guix
# packages on a foreign distro.
if [ -d "$HOME/.guix-extra-profiles/desktop/desktop/lib/locale" ]; then
  export GUIX_LOCPATH="$HOME/.guix-extra-profiles/desktop/desktop/lib/locale"
fi

# ----------------------------------------------------------------------
# Guix: load profiles
# ----------------------------------------------------------------------
# 1) Extra profiles under ~/.guix-extra-profiles/<name>/<name>
# 2) Default profile: ~/.guix-profile
# 3) Current profile (from `guix pull`): ~/.config/guix/current  (source LAST)
#
# Sourcing the "current" profile last ensures the newest Guix has priority.
GUIX_EXTRA_PROFILES="$HOME/.guix-extra-profiles"
if [ -d "$GUIX_EXTRA_PROFILES" ]; then
  for i in "$GUIX_EXTRA_PROFILES"/*; do
    [ -d "$i" ] || continue
    name=${i##*/}
    profile="$i/$name"
    if [ -r "$profile/etc/profile" ]; then
      GUIX_PROFILE="$profile"
      . "$GUIX_PROFILE/etc/profile"
    fi
  done
  unset i name profile
fi

# Default profile
GUIX_PROFILE="$HOME/.guix-profile"
if [ -r "$GUIX_PROFILE/etc/profile" ]; then
  . "$GUIX_PROFILE/etc/profile"
fi

# Current profile (from `guix pull`) — source last
GUIX_PROFILE="$HOME/.config/guix/current"
if [ -r "$GUIX_PROFILE/etc/profile" ]; then
  . "$GUIX_PROFILE/etc/profile"
fi

# ----------------------------------------------------------------------
# SSH: use GnuPG's agent as an SSH agent (if available)
# ----------------------------------------------------------------------
# This points SSH_AUTH_SOCK to gpg-agent's ssh socket. Guarded so shells
# don't print errors if gpgconf isn't installed.
if command -v gpgconf >/dev/null 2>&1; then
  sock=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
  if [ -n "$sock" ]; then
    export SSH_AUTH_SOCK="$sock"
  fi
  unset sock
fi

# ----------------------------------------------------------------------
# Build / tooling defaults
# ----------------------------------------------------------------------
# Make `ls` collate dotfiles first (useful for Emacs/dired)
export LC_COLLATE="C"

# Many build scripts expect CC to contain the compiler command
export CC="gcc"

# Editors
export VISUAL="emacs"
export EDITOR="$VISUAL"

# ----------------------------------------------------------------------
# TLS/SSL certificates (Guix-provided nss-certs), if present
# ----------------------------------------------------------------------
# Only set these variables if the Guix certificate bundle exists, so we
# don't accidentally break HTTPS on systems where the profile path changed.
cert_dir="$HOME/.guix-extra-profiles/desktop/desktop/etc/ssl/certs"
cert_bundle="$cert_dir/ca-certificates.crt"
if [ -r "$cert_bundle" ]; then
  export SSL_CERT_DIR="$cert_dir"
  export SSL_CERT_FILE="$cert_bundle"
  export GIT_SSL_CAINFO="$SSL_CERT_FILE"
  export CURL_CA_BUNDLE="$SSL_CERT_FILE"
fi
unset cert_dir cert_bundle

# ----------------------------------------------------------------------
# PATH: personal executables
# ----------------------------------------------------------------------
# These are *session-wide* PATH tweaks. Your terminal emulator may start
# a non-login shell (which reads ~/.bashrc but not ~/.profile), so we also
# add these in ~/.bashrc (see that file).
path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) : ;;          # already there
    *) PATH="$1:$PATH" ;;
  esac
}

path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.bin"
unset path_prepend

export PATH

# ----------------------------------------------------------------------
# Flatpak: ensure exported apps are discoverable
# ----------------------------------------------------------------------
# Ensure XDG_DATA_DIRS is exported and has sensible defaults.
if [ -z "${XDG_DATA_DIRS:-}" ]; then
  XDG_DATA_DIRS="/usr/local/share:/usr/share"
fi
export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
