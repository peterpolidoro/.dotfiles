# ~/.bash_profile
# ----------------------------------------------------------------------
# Bash *login* shell initialization.
#
# Bash reads this file for login shells (e.g. on a TTY, via SSH, or if your
# terminal emulator is configured to start a login shell).
#
# Design:
#   - Keep session-wide environment variables in ~/.profile (POSIX sh).
#   - Keep interactive-only settings (prompt, aliases, completion, etc.) in
#     ~/.bashrc.
#
# Note about Guix:
#   - When you're inside `guix shell`, Guix sets up an ephemeral environment
#     and sets $GUIX_ENVIRONMENT. In that case we avoid sourcing ~/.profile
#     from here because ~/.profile sources your “permanent” Guix profiles and
#     can accidentally reorder PATH, de-prioritizing the ephemeral shell.
# ----------------------------------------------------------------------

# Load the POSIX login environment (works for both sh and bash), unless
# we're in a Guix ephemeral environment.
if [ -z "${GUIX_ENVIRONMENT:-}" ] && [ -r "$HOME/.profile" ]; then
  . "$HOME/.profile"
fi

# If this is an interactive login shell, also load interactive bash settings.
case "$-" in
  *i*)
    if [ -r "$HOME/.bashrc" ]; then
      . "$HOME/.bashrc"
    fi
    ;;
esac
