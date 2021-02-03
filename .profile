# Augment PATH
# export PATH="$HOME/.bin:$HOME/.npm-global/bin:$PATH"

# Load the default Guix profile
GUIX_PROFILE="$HOME/.guix-profile"
. "$GUIX_PROFILE"/etc/profile

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

# Don't use the system-wide PulseAudio configuration
# unset PULSE_CONFIG
# unset PULSE_CLIENTCONFIG

# Export the path to IcedTea so that tools pick it up correctly
# export JAVA_HOME=$(dirname $(dirname $(readlink $(which java))))

# Make sure we can reach the GPG agent for SSH auth
# export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Make sure `ls` collates dotfiles first (for dired)
export LC_COLLATE="C"

# Many build scripts expect CC to contain the compiler command
export CC="gcc"

# Make Flatpak apps visible to launcher
# export XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/.local/share/flatpak/exports/share"

# Make applications in other profiles visible to launcher
# export XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/.guix-extra-profiles/music/music/share"
# export XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/.guix-extra-profiles/video/video/share"
# export XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/.guix-extra-profiles/browsers/browsers/share"

# Ensure that font folders are loaded correctly
# xset +fp $(dirname $(readlink -f ~/.guix-extra-profiles/desktop/desktop/share/fonts/truetype/fonts.dir))

# We're in Emacs, yo
# export VISUAL=emacsclient
# export EDITOR="$VISUAL"

# export KILIBS=$HOME/git/kicad/kicad-libraries
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
# alias teensy_loader_cli='/home/polidorop/teensy/teensy_loader_cli/teensy_loader_cli'
#source /usr/share/vcstool-completion/vcs.bash
# alias mrstatus="mr -m run git status -s"
# alias arduino='/home/polidorop/ArduinoIde/arduino-1.8.13/arduino'
# vterm_printf(){
#     if [ -n "$TMUX" ]; then
#         # Tell tmux to pass the escape sequences through
#         # (Source: http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324)
#         printf "\ePtmux;\e\e]%s\007\e\\" "$1"
#     elif [ "${TERM%%-*}" = "screen" ]; then
#         # GNU screen (screen, screen-256color, screen-256color-bce)
#         printf "\eP\e]%s\007\e\\" "$1"
#     else
#         printf "\e]%s\e\\" "$1"
#     fi
# }

# Load .bashrc to get login environment

# guix install nss-certs
export SSL_CERT_DIR="$HOME/.guix-profile/etc/ssl/certs"
export SSL_CERT_FILE="$HOME/.guix-profile/etc/ssl/certs/ca-certificates.crt"
export GIT_SSL_CAINFO="$SSL_CERT_FILE"

[ -f ~/.bashrc ] && . ~/.bashrc
