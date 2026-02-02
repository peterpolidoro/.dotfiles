# ~/.bash_aliases
# ----------------------------------------------------------------------
# Aliases for interactive shells.
#
# This file is sourced by ~/.bashrc (Debian default behavior).
# Keep "alias" statements and other interactive helpers here.
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Color support and common ls/grep conveniences (Debian default-ish)
# ----------------------------------------------------------------------
if [[ ":$PATH:" == *":/usr/bin:"* ]] && [ -x /usr/bin/dircolors ]; then
  test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"

  alias ls='ls --color=auto'
  #alias dir='dir --color=auto'
  #alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# ----------------------------------------------------------------------
# Extra ls aliases
# ----------------------------------------------------------------------
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# ----------------------------------------------------------------------
# Notification helper for long-running commands
# ----------------------------------------------------------------------
# Use like:  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ----------------------------------------------------------------------
# Multi-repo helper
# ----------------------------------------------------------------------
alias mrstatus='mr -m run git status -s'

# ----------------------------------------------------------------------
# Your project/tool shortcuts
# ----------------------------------------------------------------------
alias qm='~/qp/qm-5.2.3/bin/qm.sh'
alias qspy='~/qp/qtools-6.9.3/bin/qspy'
alias blender='~/bin/blender-5.0.1-linux-x64/blender'

# ----------------------------------------------------------------------
# Emacs config shortcuts
# ----------------------------------------------------------------------
alias e='emacs-config-peter-personal'
alias ee='emacs-config-peter-email'
