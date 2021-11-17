export GUIX_LOCPATH=$HOME/.guix-extra-profiles/desktop/desktop/lib/locale

# Load additional Guix profiles
GUIX_EXTRA_PROFILES=$HOME/.guix-extra-profiles
for i in $GUIX_EXTRA_PROFILES/*; do
  profile=$i/$(basename "$i")
  if [ -f "$profile"/etc/profile ]; then
    GUIX_PROFILE="$profile"
    . "$GUIX_PROFILE"/etc/profile
  fi
  unset profile
done

# Load the default Guix profile
GUIX_PROFILE="$HOME/.guix-profile"
. "$GUIX_PROFILE"/etc/profile

# Load the current Guix profile Note, that the “current” profile should be
# sourced the last. Thus the latest guix (fetched by guix pull) will have a
# priority.
GUIX_PROFILE="$HOME/.config/guix/current"
. "$GUIX_PROFILE/etc/profile"

# Export the path to IcedTea so that tools pick it up correctly
# export JAVA_HOME=$(dirname $(dirname $(readlink $(which java))))

# Make sure we can reach the GPG agent for SSH auth
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Make sure `ls` collates dotfiles first (for dired)
export LC_COLLATE="C"

# Many build scripts expect CC to contain the compiler command
export CC="gcc"

# Ensure that font folders are loaded correctly
# xset +fp $(dirname $(readlink -f ~/.guix-extra-profiles/desktop/desktop/share/fonts/truetype/fonts.dir))

export VISUAL=emacs
export EDITOR="$VISUAL"

alias mrstatus="mr -m run git status -s"

# guix install nss-certs
export SSL_CERT_DIR="$HOME/.guix-extra-profiles/desktop/desktop/etc/ssl/certs"
export SSL_CERT_FILE="$HOME/.guix-extra-profiles/desktop/desktop/etc/ssl/certs/ca-certificates.crt"
export GIT_SSL_CAINFO="$SSL_CERT_FILE"
export CURL_CA_BUNDLE="$SSL_CERT_FILE"

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.bin" ] ; then
    PATH="$HOME/.bin:$PATH"
fi

