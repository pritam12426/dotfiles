# printf "Importing \t %s \n" "$HOME/.config/zsh/zshrc.zsh"

# ============================================================================================================
# REFERENCES
#	https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html
#	https://github.com/spicycode/ze-best-zsh-config
#	https://gist.github.com/elliottminns/09a598082d77f795c88e93f7f73dba61
#	See this dir "/usr/lib/zsh/5.9"
#	https://www.youtube.com/watch?v=3fVAtaGhUyU
#   https://www.reddit.com/r/zsh/comments/nm2vun/a_guide_to_the_zsh_autocompletion_with_examples/
# ============================================================================================================


# ~/.zshrc — Minimal, single-file zsh configuration

# Return early if not running interactively
[[ $- != *i* ]] && return

# ============================================================================================================
# IMPORTING EXTERNAL FILES AND PLUGINS
# ============================================================================================================
export __ZSH_PULGINS_DIR="$HOME/.local/share/zsh/plugins"
# # Load Apple’s default interactive zsh environment (fixes most issues)
# [ -f /etc/zshrc ] && source /etc/zshrc

# Load aliases (you already use this)
if [[ -f "$HOME/.config/zsh/alias.zsh" ]]; then
	source "$HOME/.config/zsh/alias.zsh"
fi

# fzf history widget
if [[ -f "$__ZSH_PULGINS_DIR/fzf/__fzf-history__" ]]; then
	source "$__ZSH_PULGINS_DIR/fzf/__fzf-history__"
	source "$__ZSH_PULGINS_DIR/fzf/fzf-tab-master/fzf-tab.zsh"
	bindkey '^F' fzf-history-widget
else
	if hash fzf 2>/dev/null; then
		printf "Warning: fzf history widget not installed (%s:%d)\n" "$HOME/.zshrc" $LINENO
		# To install: mkdir -p "$__ZSH_PULGINS_DIR/fzf"
		# fzf --zsh > "$__ZSH_PULGINS_DIR/fzf/__fzf-history__"
		# wget "https://github.com/Aloxaf/fzf-tab/archive/refs/heads/master.zip" -P "$__ZSH_PULGINS_DIR/fzf"
		# bsdtar -vxf "$__ZSH_PULGINS_DIR/fzf/master.zip" -C "$__ZSH_PULGINS_DIR/fzf" && rm "$__ZSH_PULGINS_DIR/fzf/master.zip"
	fi
fi

# navi widget
if [[ -f "$__ZSH_PULGINS_DIR/__navi_widget__" ]]; then
	source "$__ZSH_PULGINS_DIR/__navi_widget__"
else
	if hash navi 2>/dev/null; then
		printf "Warning: navi widget not installed (%s:%d)\n" "$HOME/.zshrc" $LINENO
		# To install: navi widget zsh > "$__ZSH_PULGINS_DIR/__navi_widget__"
	fi
fi

# zoxide widget
if [[ -f "$__ZSH_PULGINS_DIR/__zoxide__" ]]; then
	source "$__ZSH_PULGINS_DIR/__zoxide__"
else
	if hash zoxide 2>/dev/null; then
		printf "Warning: zoxide widget not installed (%s:%d)\n" "$HOME/.zshrc" $LINENO
		# To install: zoxide init --cmd cd zsh > "$__ZSH_PULGINS_DIR/__zoxide__"
	fi
fi

# zsh-you-should-use (actively used)
if [[ -f "$__ZSH_PULGINS_DIR/zsh-you-should-use/you-should-use.plugin.zsh" ]]; then
	source "$__ZSH_PULGINS_DIR/zsh-you-should-use/you-should-use.plugin.zsh"
fi

# fast-syntax-highlighting — currently disabled (uncomment if you want it later)
# if [[ -f "$__ZSH_PULGINS_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
#   source "$__ZSH_PULGINS_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
# fi

# zsh-autosuggestions — currently disabled (uncomment if you want it later)
# if [[ -f "$__ZSH_PULGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
#   source "$__ZSH_PULGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
# fi

# ============================================================================================================
# zmv - ADVANCED BATCH RENAME/MOVE
# -------------------------------------------
# Enable zmv
autoload -Uz zmv

# Usage examples:
# zmv '(*).log' '$1.txt'           # Rename .log to .txt
# zmv -w '*.log' '*.txt'           # Same thing, simpler syntax
# zmv -n '(*).log' '$1.txt'        # Dry run (preview changes)
# zmv -i '(*).log' '$1.txt'        # Interactive mode (confirm each)

# Helpful aliases for zmv
alias zcp='zmv -C'  # Copy with patterns
alias zln='zmv -L'  # Link with patterns

# ============================================================================================================
# BOOKMARKS & CUSTOM WIDGETS
# ============================================================================================================

# Directory bookmark
hash -d go=~/Developer/go_lang
hash -d DOT_FILE=$DOT_FILE
hash -d dl=~/Downloads

# Copy current command buffer to clipboard (macOS)
function copy-buffer-to-clipboard() {
	printf "%s" "$BUFFER" | pbcopy
	zle -M "Copied current command to clipboard"
}
zle -N copy-buffer-to-clipboard
bindkey '^Zc' copy-buffer-to-clipboard

# Edit command line in $EDITOR (Ctrl+E)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^Ze' edit-command-line  # Esc key (you had this as '^E')

# Perform history expansion on space (e.g. !docker)
bindkey ' ' magic-space

# Auto-activate/deactivate Python virtualenvs when changing directories
chpwd() {
	if [[ -d .venv ]]; then
		source .venv/bin/activate 2>/dev/null
	elif [[ -d venv ]]; then
		source venv/bin/activate 2>/dev/null
	# elif [[ -n "$VIRTUAL_ENV"  ]]; then
	# 	deactivate 2>/dev/null
	fi
}

# ============================================================================================================
# COMPLETION SYSTEM
# ============================================================================================================

zmodload -i zsh/parameter
autoload -Uz compinit && compinit
zmodload -i zsh/complist
setopt MENU_COMPLETE AUTO_MENU

zle -C alias-expension complete-word _generic
bindkey '^a' alias-expension
zstyle ':completion:alias-expension:*' completer _expand_alias

zstyle ':fzf-tab:*' fzf-flags --height=60% --bind=tab:accept
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Cache completion data
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh/cache"

# Group completion menus nicely
zstyle ':completion:*' file-list all
zstyle ':completion:*' menu select
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more%s'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# format completion menus nicely
#zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
#zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
#zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
#zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
#zstyle ':completion:*:descriptions' format '%U%K{yellow} %F{green}-- %F{red} %BNICE!1! %b%f %d --%f%k%u'

# Matching and ordering
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*' single-ignored show

# Kill command coloring
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# SSH/SCP completion ordering
zstyle ':completion:*:scp:*' tag-order files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP Address *'
zstyle ':completion:*:scp:*' group-order files all-files users hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP Address *'
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr

# ============================================================================================================
# HISTORY CONFIGURATION
# ============================================================================================================

export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo|history|cd -|cd ..|cd ...|clean|cdi|n)"
export HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
export HISTSIZE=100000
export SAVEHIST=100000

setopt INC_APPEND_HISTORY      # Append to history file immediately
setopt HIST_IGNORE_DUPS        # Ignore consecutive duplicates
setopt HIST_FIND_NO_DUPS       # Don't cycle through duplicates when searching
setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks
setopt INTERACTIVE_COMMENTS    # Allow comments in interactive shell

# ============================================================================================================
# GENERAL SHELL OPTIONS
# ============================================================================================================

setopt AUTO_CD              # cd by typing directory name alone
setopt COMPLETE_IN_WORD     # Complete from cursor position
setopt ALWAYS_TO_END        # Move cursor to end after completion
setopt PROMPT_SUBST         # Enable substitutions in prompt
setopt AUTO_MENU            # Show completion menu on successive tab press

# ============================================================================================================
# PROMPT & COMMAND TIMER
# ============================================================================================================
# Show more detailed Git status in prompt
#export GIT_PS1_SHOWUNTRACKEDFILES=1       # % if untracked files
#export GIT_PS1_SHOWCOLORHINTS=1           # Colored output (works great in Zsh)
#export GIT_PS1_DESCRIBE_STYLE="describe"  # Optional: use describe if no branch
#export GIT_PS1_SHOWDIRTYSTATE=1           # * for unstaged, + for staged
#export GIT_PS1_SHOWSTASHSTATE=1           # $ if something is stashed
#export GIT_PS1_SHOWUPSTREAM="auto"        # < behind, > ahead, <> diverged, = equal


#RPROMPT="${superdim}[ ${timer_show} ]%f%b \$(__git_ps1 '(%s) ')"
#source "/Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh"
# curl "https://raw.githubusercontent.com/git/git/refs/heads/master/contrib/completion/git-prompt.sh" \
# 	-o "$__ZSH_PULGINS_DIR/git-prompt.sh"

zmodload zsh/datetime
autoload -Uz add-zsh-hook

# Track command execution time
preexec() { timer=$EPOCHREALTIME }

precmd() {
	if [[ -n $timer ]]; then
		local exit_code=${pipestatus[1]}
		local now=$EPOCHREALTIME
		local start_int=${timer%.*} start_frac=${timer#*.}
		local now_int=${now%.*}     now_frac=${now#*.}

		(( elapsed_ms = (now_int - start_int) * 1000 + (10#${now_frac:0:3} - 10#${start_frac:0:3}) ))
		(( elapsed_ms < 0 )) && (( elapsed_ms += 1000 ))

		local ms=$(( elapsed_ms % 1000 ))
		local total_s=$(( elapsed_ms / 1000 ))
		local s=$(( total_s % 60 ))
		local m=$(( total_s / 60 ))

		local timer_show
		if (( total_s == 0 )); then
			timer_show="${ms}ms"
		elif (( m == 0 )); then
			timer_show="${s}.$(printf '%03d' $ms)s"
		else
			timer_show="${m}m ${s}.$(printf '%03d' $ms)s"
		fi

		local dim="%F{245}" superdim="%F{240}" err="%B%F{red}" err_time="%B%F{208}"

		if (( exit_code == 0 )); then
			RPROMPT="${superdim}[ ${timer_show} ]%f%b"
		else
			RPROMPT="${dim}[ ERR ${err}${exit_code}${dim} ] : ${err_time}${timer_show}%f%b"
		fi

		unset timer
	else
		RPROMPT=""
	fi
}

# Simple, clean prompt: user@host:dir $
PROMPT="%F{green}%B%n@%m%b%f:%F{blue}%B%~%b%f%(#.#.$) "
# https://github.com/jarun/nnn/wiki/Basic-use-cases#shell-depth-indicator
[ -n "$NNNLVL" ] && PS1="N$NNNLVL $PS1"

# Simple, clean prompt: user@host:dir (git) $
# PROMPT="%F{green}%B%n@%m%b%f:%F{blue}%B%~%b%f\$(__git_ps1 \" (%s)\")%(#.#.$) "

# ============================================================================================================
# KEY BINDINGS & ALIASES
# ============================================================================================================

# Quick edit config files
alias erc="$EDITOR  ~/.zshrc"
alias ezp="$EDITOR  ~/.zprofile"
alias eenv="$EDITOR ~/.zshenv"

# Clear history file
alias hc=': > "$HISTFILE"; fc -p'

# Handy global aliases
alias -g ...="../.."
alias -g R=" | rg --smart-case "
alias -g J=" | jq"
alias -g L=" |& less"
alias -g C=" | pbcopy"
alias -g P="\"pbpaste\""
alias -g DN=" > /dev/null"
alias -g NE=" 2> /dev/null"
alias -g H=" --help L"
alias -g NULL=" > /dev/null 2>&1"

# Suffix alias: open .json files with jless
alias -s json=jless
alias -s txt=less
alias -s md=bat
alias -s log=bat
alias -s html=open  # macOS: open in default browser

bindkey "^K"      kill-whole-line    # ctrl-k
# bindkey "^[[3~"   kill-whole-line    # delete key
bindkey "^[[1;2D" beginning-of-line  # shift + left
bindkey "^[[1;2C" end-of-line        # shift + right

# ============================================================================================================
# Hotkey Insertions - Text Snippets
# ============================================================================================================
# Insert git commit template (Ctrl+X, G, C)
# \C-b moves cursor back one position
# bindkey -s '^Xgc' 'git commit -m ""'

# More examples:
# bindkey -s '^Xgp' 'git push origin '
# bindkey -s '^Xgs' 'git status\n'
# bindkey -s '^Xgl' 'git log --oneline -n 10\n'

# ============================================================================================================
# NOTES ON ZSH STARTUP ORDER (kept for reference)
# ============================================================================================================

# When a new interactive zsh starts on macOS, the order is:
# ~/.zshenv → ~/.zprofile → ~/.zshrc → ~/.zlogin
# You mentioned a zsh() function that sources .zshenv/.zprofile again — that's redundant and potentially dangerous.
# It has been removed to keep things clean and avoid double-sourcing environment variables.
# If you need private env vars, put them in ~/.zshenv (sourced first and always).

function zsh() {
	if [ -f "$HOME/.zshenv" ]; then
		# THIS FILE WILL CONTAIN ALL THE PRIVATE CONFIGURATION, WHICH I CAN'T PUBLISH ON git hub
		source "$HOME/.zshenv"

		#THIS FILE WILL CONTAIN ALL THE ENVIRONMENT VARIABLE AND THE CONFIGURATION WHICH I COMFORTABLE TO PUBLISH ON GITHUB
		# source "$HOME/.config/zsh/zshenv-footer.zsh"
	fi

	if [ -f "$HOME/.zprofile" ]; then
		source "$HOME/.zprofile"
	fi
}
# ============================================================================================================
