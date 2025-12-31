export EDITOR="/Users/pritam/.local/bin/nvim"

if [ -f "$DOT_FILE/config/zsh/alias.zsh" ]; then
	source "$DOT_FILE/config/zsh/alias.zsh"
fi

if [ -f "$DOT_FILE/config/zsh/functions.sh" ]; then
	source "$DOT_FILE/config/zsh/functions.sh"
fi

if [ -f "$HOME/.bash_profile" ]; then
	source "$HOME/.bash_profile"
fi

# aliases ---------------------------------------------------
alias erc="$EDITOR ~/.bashrc"
alias eenv="$EDITOR ~/.bashenv"
alias hc="cat /dev/null > ~/.bash_history"
alias which="which -a"
# -----------------------------------------------------------

#  For setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100
HISTFILESIZE=200

#  PS1 variable
PS1=" \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

function bash() {
	if [ -f "$DOT_FILE/config/zsh/alias.zsh" ]; then
		source "$DOT_FILE/config/zsh/alias.zsh"
	fi

	if [ -f "$DOT_FILE/config/zsh/functions.sh" ]; then
		source "$DOT_FILE/config/zsh/functions.sh"
	fi

	if [ -f "$HOME/.bashenv" ]; then
		source "$HOME/.bashenv"
	fi

	if [ -f "$HOME/.bashrc" ]; then
		source "$HOME/.bashrc"
	fi
}
