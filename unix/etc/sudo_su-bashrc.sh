# sudo su; cp sudo_su-bashrc.sh /var/root/.bashrc
# Change root shell to bash (or zsh)
# sudo su
# dscl . -change /Users/root UserShell /bin/sh /bin/bash
# sudo visudo
# Defaults env_keep += "NNN_PLUG NNN_OPTS"

# Environment ---------------------------------------------------------
export PAGER='less'
export LESS='-Rir --tabs=2 -j5'

export EDITOR="/Users/pritam/.local/bin/hx"
export ZED_ALLOW_ROOT=true
export GPG_TTY="$(tty)"

# Prompt ---------------------------------------------------------
PS1=" \[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "


# nnn ---------------------------------------------------------
export NNN_COLORS="5236" # make the color theme red
# export NNN_OPTS="AUBREodefg"
export NNN_SEL="/tmp/root-nnn.sel"
export NNN_TMPFILE="/tmp/root-nnn.lastd"
export NNN_FIFO="/tmp/root-nnn.fifo"
export NNN_FCOLORS="c1e2272e006033f7c6d6abc4" # make the color theme red
# ---------------------------------------------------------

# History ---------------------------------------------------------
HISTSIZE=5000
HISTFILESIZE=10000

# Interactive shell only ---------------------------------------------------------
[[ $- != *i* ]] && return

# Aliases  ---------------------------------------------------------
alias erc='$EDITOR ~/.bashrc'
alias hc='history -c && history -w'
alias which='which -a'
# Search tools
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias rg='grep --exclude-dir={.git,venv,node_modules,build} --color=auto -rnE'
# Diff / sync
alias diff='diff --color=auto'
alias rsync='rsync -vrPlu'
alias rclone='rclone -vP'
# File listing
alias ls='ls -GFh'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -lA'
alias lh='ls -ld .[^.]*'
# File operations
alias cp='cp -ipP'
alias mv='mv -vi'
alias scp='scp -pr'
# Utilities
alias du='du -hs'
alias df='df -h'
alias bc='bc -ql'
alias mime='file --mime --mime-type'
alias nl='nl -ba'
alias af='alias | grep -i --'
# Finder
alias o='open .'
# ---------------------------------------------------------


# Functions
# Launch nnn and restore cwd afterwards
n() {
	[ "${NNNLVL:-0}" -eq 0 ] || {
		echo "nnn is already running"
		return
	}

	/Users/pritam/.local/bin/nnn "$@"

	[ ! -f "$NNN_TMPFILE" ] || . "$NNN_TMPFILE"
}

# Reload shell configuration
reload() {
	[ -f ~/.bash_profile ] && source ~/.bash_profile
	[ -f ~/.bashrc ] && source ~/.bashrc
}

# Find files by partial name
ffind() {
	find . -type f -iname "*$1*"
}

# Find executable files
findexe() {
	find . -type f -perm -111 "$@"
}

# Copy absolute path to clipboard
pc() {
	if [ $# -eq 0 ]; then
		printf '%s' "$PWD" | pbcopy
	else
		/Users/pritam/.local/bin/pathCopy "$@" | pbcopy
	fi
}

# Quick directory size summary
dus() {
	du -sh ./* 2> /dev/null | sort -h
}
