# sudo su; cp sudo_su-bashrc.sh /var/root/.bashrc

# Change root shell to bash (or /bin/zsh)
# sudo su; dscl . -change /Users/root UserShell /bin/sh /bin/bash
# Or for zsh: sudo dscl . -change /Users/root UserShell /bin/sh /bin/zsh

# sudo visudo
# ==== For nnn file manger ====
# Defaults	env_keep += "NNN_ORDER NNN_PLUG NNN_COLORS NNN_OPENER NNN_OPTS NNN_ARCHIVE NNN_FCOLORS"

export EDITOR="/Users/pritam/.local/bin/nvim"

PS1=" \[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "


# aliases ---------------------------------------------------
alias erc="$EDITOR ~/.bashrc"
alias hc="cat /dev/null > ~/.bash_history"
alias which="which -a"

#  For setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100
HISTFILESIZE=200
# -----------------------------------------------------------

export NNN_COLORS="5236"
# export NNN_OPENER="/usr/bin/open"
export NNN_OPTS="AUBRdiefagxpH"
# export NNN_OPTS="ANUdixefaog"
export NNN_SEL="/tmp/root-nnn.sel"
export NNN_TMPFILE="/tmp/root-nnn.lastd"
export NNN_FIFO="/tmp/root-nnn.fifon"
# export NNN_TRASH="/usr/bin/trash"
export NNN_HELP="cat $DOT_FILE/../global/nnn_help.txt"
export NNN_ARCHIVE="\\.(7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|rar|rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)$"
export NNN_FCOLORS="c1e2272e006033f7c6d6abc4"

#  Some more ls aliases
alias ls="command ls --color=auto"
alias grep="command grep --color=auto"
alias fgrep="command fgrep --color=auto"
alias egrep="command egrep --color=auto"

alias ll="command ls -lh"
alias la="command ls -A"
alias l="command ls -lAh"

#  SOME MORE ALIES
alias cp="command cp -ip"
alias mv="command mv -i"
alias du="command du -h"

export GPG_TTY=$(tty)

function n () {
	[ "${NNNLVL:-0}" -eq 0 ] || {
		echo "nnn is already running"
		return
	}

	/Users/pritam/.local/bin/nnn "$@"

	[ ! -f "$NNN_TMPFILE" ] || {
		. "$NNN_TMPFILE"
	}
}

function bash() {
	if [ -f "$HOME/.bashrc" ]; then
		source "$HOME/.bashrc"
	fi
}
