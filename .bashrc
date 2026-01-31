# ~/.bashrc
# ----------------------------------------------------------------------
# Bash interactive shell configuration (non-login shells).
#
# Most terminal emulators (including QTerminal in many setups) start an
# interactive *non-login* shell. In that case:
#   - ~/.bashrc is read
#   - ~/.bash_profile / ~/.profile are NOT read
#
# This file is based on Debian's default ~/.bashrc, with your custom Guix
# and direnv bits preserved, and an added PATH section so ~/.local/bin is
# available in QTerminal.
# ----------------------------------------------------------------------

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac

# ----------------------------------------------------------------------
# PATH: make sure personal/Guix bins are reachable in interactive terminals
# ----------------------------------------------------------------------
# We add common user bin directories here because non-login shells won't
# read ~/.profile. We also avoid disturbing PATH precedence inside `guix shell`:
#   - Outside a Guix environment: prepend (user tools first).
#   - Inside a Guix environment: append (environment keeps priority).
path_add_front() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}
path_add_back() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$PATH:$1" ;;
  esac
}

if [[ -n "$GUIX_ENVIRONMENT" ]]; then
  # In `guix shell`, keep the environment's bins first.
  path_add_back "$HOME/bin"
  path_add_back "$HOME/.local/bin"
  path_add_back "$HOME/.bin"
  path_add_back "$HOME/.guix-profile/bin"
  path_add_back "$HOME/.config/guix/current/bin"
else
  # Normal interactive shell: prefer user/Guix tools first.
  path_add_front "$HOME/.config/guix/current/bin"
  path_add_front "$HOME/.guix-profile/bin"
  path_add_front "$HOME/bin"
  path_add_front "$HOME/.local/bin"
  path_add_front "$HOME/.bin"
fi

export PATH
unset -f path_add_front path_add_back

# ----------------------------------------------------------------------
# History behavior
# ----------------------------------------------------------------------
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# ----------------------------------------------------------------------
# lesspipe integration (Debian default)
# ----------------------------------------------------------------------
# Make less more friendly for non-text input files, see lesspipe(1)
if [[ ":$PATH:" == *":/usr/bin:"* ]] && [[ ":$PATH:" == *":/bin:"* ]]; then
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
fi

# ----------------------------------------------------------------------
# Prompt / chroot detection (Debian default)
# ----------------------------------------------------------------------
# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
  xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
  *) ;;
esac

# ----------------------------------------------------------------------
# Aliases
# ----------------------------------------------------------------------
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
if [ -f "$HOME/.bash_aliases" ]; then
  . "$HOME/.bash_aliases"
fi

# ----------------------------------------------------------------------
# Bash completion (Debian default)
# ----------------------------------------------------------------------
# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ----------------------------------------------------------------------
# Guix: prompt hint when inside `guix shell`
# ----------------------------------------------------------------------
if [ -n "$GUIX_ENVIRONMENT" ]; then
  export PS1="\u@\h \w [guix]\$ "
fi

# ----------------------------------------------------------------------
# direnv integration + virtualenv indicator in prompt
# ----------------------------------------------------------------------
if [ -x "$(command -v direnv)" ]; then
  eval "$(direnv hook bash)"

  show_virtual_env() {
    if [[ -n "$VIRTUAL_ENV" && -n "$DIRENV_DIR" ]]; then
      echo "($(basename "$VIRTUAL_ENV"))"
    fi
  }
  export -f show_virtual_env
  PS1='$(show_virtual_env)'$PS1
fi
