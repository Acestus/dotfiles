# ~/.bashrc: executed by bash(1) for interactive shells.

case $- in
    *i*) ;;
    *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
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

case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias k='kubectl'
alias python='python3'
alias emacs='emacsclient -c -n'
alias dn="$HOME/git/dotfiles/scripts/bash/dn.cs"
alias claude='/home/acestus/git/scripts/claude-shell.cs'
alias rt='/home/acestus/git/scripts/claude-shell.cs'
alias pwshdot='pwsh -NoProfile -File /home/acestus/git/dotfiles/Microsoft.PowerShell_profile.ps1'
alias editbashrc='code /home/acestus/git/dotfiles/.bashrc'
alias editvscodesettings='code /home/acestus/git/dotfiles/vscode/settings.json'
alias editvscodekeys='code /home/acestus/git/dotfiles/vscode/keybindings.json'
alias editvscodesnippets='code /home/acestus/git/dotfiles/vscode/snippets/snippets.code-snippets'
alias gd='/home/acestus/git/dotfiles/scripts/git-daily.cs'
alias em='emacsclient -c -n -a ""'


if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/git/dotfiles/scripts:$PATH"
export PATH="$PATH:/home/acestus/dotnet"
export PATH="$HOME/.local/opt/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
. "$HOME/.cargo/env"


[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
export EDITOR="code -w"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.local/npm-global/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/share/pnpm:$PATH"

PNPM_HOME="/home/acestus/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export OPENCLAW_URL="ws://192.168.1.100:18789"
if [ -f "$HOME/.openclaw_token" ]; then
  export OPENCLAW_TOKEN="$(cat "$HOME/.openclaw_token")"
fi

# Alias for emacsclient
alias em='emacsclient -t -a "" "$@"'

alias editfishconfig='code /home/acestus/git/dotfiles/fish.config'

# opencode
export PATH=/home/acestus/.opencode/bin:$PATH

if [[ $- == *i* ]] && command -v fish >/dev/null 2>&1 && [ -z "${FISH_VERSION-}" ]; then
    exec fish
fi
