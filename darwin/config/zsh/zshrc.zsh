# printf "Importing \t %s \n" "$HOME/.config/zsh/zshrc.zsh"

# ============================================================================================================
# REFERENCES
#	https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html
#	https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html
#	https://github.com/antonio/zsh-config/tree/master/help

#	https://github.com/spicycode/ze-best-zsh-config
#	https://gist.github.com/elliottminns/09a598082d77f795c88e93f7f73dba61
#	See this dir "/usr/lib/zsh/5.9"
#	https://www.youtube.com/watch?v=3fVAtaGhUyU
#	https://www.reddit.com/r/zsh/comments/nm2vun/a_guide_to_the_zsh_autocompletion_with_examples/
#	https://thevaluable.dev/zsh-completion-guide-examples/
#	man zshmodules
# ============================================================================================================

# zmodload zsh/net/socket <Learn about this>

# Return early if not running interactively
[[ $- != *i* ]] && return

# # Load Apple's default interactive zsh environment (fixes most issues)
# [ -f /etc/zshrc ] && source /etc/zshrc

DISABLE_AUTO_UPDATE=true
DISABLE_MAGIC_FUNCTIONS=true
DISABLE_COMPFIX=true

# Autosuggest settings
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#663399,standout'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='10'
ZSH_AUTOSUGGEST_USE_ASYNC=1

# Load aliases (you already use this)
[ -f "$HOME/.config/zsh/alias.zsh" ]    && source "$HOME/.config/zsh/alias.zsh"
[ -f "$HOME/.config/zsh/plugins.zsh" ]  && source "$HOME/.config/zsh/plugins.zsh"

[[ $COLORTERM = *(24bit|truecolor)* ]] || zmodload -i zsh/nearcolor

# ============================================================================================================
# zmv - ADVANCED BATCH RENAME/MOVE
# ============================================================================================================

# autoload -Uz zmv
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

# Directory bookmarks — use as ~dl, ~cfg, ~proj etc. anywhere, including completion
hash -d DOT_FILE=$DOT_FILE
hash -d dl=~/Downloads
hash -d yt-dlp=~/Downloads/yt_dlp
hash -d YouTube=~/Downloads/yt_dlp/Youtube
hash -d cfg=~/.config         # quick access to config dir

# Copy current command buffer to clipboard (macOS)
function copy-buffer-to-clipboard() {
	printf '%s' "$BUFFER" | pbcopy
	zle -M 'Copied current command to clipboard'
}
zle -N copy-buffer-to-clipboard
bindkey '^Zc' copy-buffer-to-clipboard

# Edit command line in $EDITOR (Ctrl+E)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^Ze' edit-command-line  # Esc key (you had this as '^Z e')

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
# Smarter completion initialization — rebuild dump if older than 20 hours,
# otherwise load from cache with -C (skip security check for speed)
# https://scottspence.com/posts/speeding-up-my-zsh-shell#fixing-the-completion-system-3076--10
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
	compinit
else
	compinit -C
fi

# ══════════════════════════════════════════════════════════════════════════════
#  ZSH COMPLETION CONFIG
# ══════════════════════════════════════════════════════════════════════════════

# ── Modules ───────────────────────────────────────────────────────────────────
zmodload -i zsh/parameter
zmodload -i zsh/complist

# ── Options ───────────────────────────────────────────────────────────────────
setopt MENU_COMPLETE        # auto-select first completion on tab
setopt AUTO_MENU            # show completion menu on second tab press
setopt AUTO_PUSHD           # push dirs onto stack (enables dir history in cd)
setopt PUSHD_IGNORE_DUPS    # no duplicates in dir stack
setopt COMPLETE_IN_WORD     # complete from both ends of a word
setopt ALWAYS_TO_END        # move cursor to end after completion
setopt NO_FLOW_CONTROL      # frees up Ctrl+S for forward history search

# ── Alias expansion (Ctrl+A) ──────────────────────────────────────────────────
# Ctrl+A expands an alias inline in the buffer (ll → ls -la)
zle -C alias-expansion complete-word _generic
bindkey '^a' alias-expansion
zstyle ':completion:alias-expansion:*' completer _expand_alias

# ── History word completion (Alt+/) ───────────────────────────────────────────
# Alt+/ completes the current word from your command history
zle -C hist-complete complete-word _generic
bindkey '^[/' hist-complete
zstyle ':completion:hist-complete:*' completer _history

# ── Cache ─────────────────────────────────────────────────────────────────────
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh/cache"

# ── Completer pipeline ────────────────────────────────────────────────────────
# Order: alias first → expand globs → complete → fuzzy approximate
zstyle ':completion:*' completer _expand _complete _ignored _approximate

# ── Tag ordering: aliases → functions → commands ──────────────────────────────
zstyle ':completion:*:-command-:*' tag-order 'aliases functions commands'

# ── Fuzzy / progressive matching ──────────────────────────────────────────────
# Pass 1: exact
# Pass 2: case-insensitive
# Pass 3: partial-word (gitpu → git-push)
# Pass 4: substring (anywhere in word)
zstyle ':completion:*' matcher-list \
    '' \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# ── Menu & display ────────────────────────────────────────────────────────────
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''        # enable group separators
zstyle ':completion:*' verbose yes
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt   '%F{cyan}%S  at %p — tab for more  %s%f'
zstyle ':completion:*' select-prompt '%F{magenta}%S  %p  %s%f'

# Show ls -l style listing for small result sets (≤10 on list, ≤5 on insert)
zstyle ':completion:*' file-list list=10 insert=5

# ── Group header colors ───────────────────────────────────────────────────────
zstyle ':completion:*:descriptions' format '%F{cyan}%B┌─ %d ─%b%f'
zstyle ':completion:*:messages'     format '%F{blue}  %d%f'
zstyle ':completion:*:warnings'     format '%F{red}%B  ✗ no matches for: %d%b%f'
zstyle ':completion:*:corrections'  format '%F{yellow}  ± %d (errors: %e)%f'

# ── Expand & ignored ──────────────────────────────────────────────────────────
zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*'          single-ignored show

# ── cd: directory stack & ignore self ─────────────────────────────────────────
# Never suggest . and .. when completing cd
zstyle ':completion:*:cd:*' ignore-parents parent pwd
# Prioritize local dirs → dir stack → path dirs
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
# Color dir stack entries (index number highlighted)
zstyle ':completion:*:directory-stack' list-colors '=(#b) #([0-9]#)*( *)==95=38;5;12'

# ── Kill: red PID + yellow process name ──────────────────────────────────────
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;31=0=01;33'

# ── rm/rmdir: highlight targets in red ───────────────────────────────────────
zstyle ':completion:*:*:rm:*:*'    list-colors '=(#b) #(*)==01;31'
zstyle ':completion:*:*:rmdir:*:*' list-colors '=(#b) #(*)==01;31'

# ── man: group completions by section ─────────────────────────────────────────
zstyle ':completion:*:manuals'       separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections   true

# ── SSH / SCP ─────────────────────────────────────────────────────────────────
zstyle ':completion:*:(ssh|scp|sftp):*' auto-description 'remote: %d'
zstyle ':completion:*:scp:*' tag-order   'files users hosts:-host hosts:-domain:domain hosts:-ipaddr'
zstyle ':completion:*:scp:*' group-order  files all-files users hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order   'users hosts:-host hosts:-domain:domain hosts:-ipaddr'
zstyle ':completion:*:ssh:*' group-order  hosts-domain hosts-host users hosts-ipaddr

# ── sudo: inherit parent completions ─────────────────────────────────────────
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                                            /usr/sbin /usr/bin /sbin /bin

# ── ZLE highlight ─────────────────────────────────────────────────────────────
# No highlight flash when pasting; highlight active region in blue
zle_highlight=('paste:none' 'region:bg=blue,fg=white')

# ============================================================================================================
# HISTORY CONFIGURATION
# ============================================================================================================

export HISTORY_IGNORE='(ls|cd|pwd|exit|sudo|history|cd -|cd ..|cd ...|clean|cdi|n)'
export HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
export HISTSIZE=10000
export SAVEHIST=50000           # larger than HISTSIZE so file retains more than what's in memory
bindkey '^R' history-incremental-search-backward  # shell flipped into vi-mode coz we have $EDITOR = vim-helix
# bindkey '^S' history-incremental-search-forward

setopt INC_APPEND_HISTORY       # Append to history file immediately
setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicate anywhere in history (upgrade from HIST_IGNORE_DUPS)
setopt HIST_FIND_NO_DUPS        # Don't cycle through duplicates when searching
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks
setopt HIST_IGNORE_SPACE        # Don't save commands prefixed with a space (useful for secrets)
setopt SHARE_HISTORY            # All open terminals share the same history in real time
setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell

# ============================================================================================================
# GENERAL SHELL OPTIONS
# ============================================================================================================

setopt AUTO_CD              # cd by typing directory name alone
setopt PROMPT_SUBST         # Enable substitutions in prompt
setopt EXTENDED_GLOB        # Enable extended glob: ^pattern, **/glob, (#q...) etc.
                            # NOTE: already used implicitly in zstyles above — now explicit
setopt NULL_GLOB            # No error if a glob pattern matches nothing
setopt NO_BEEP              # Silence error bells on failed completion or no match

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

zmodload -i zsh/datetime
autoload -Uz add-zsh-hook

# Track command execution time
# Using add-zsh-hook instead of plain preexec/precmd so plugins can't clobber these
_timer_preexec() { timer=$EPOCHREALTIME }

_timer_precmd() {
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

add-zsh-hook preexec _timer_preexec
add-zsh-hook precmd  _timer_precmd

# Simple, clean prompt: user@host:dir $
PROMPT="%F{green}%B%n@%m%b%f:%F{blue}%B%~%b%f%(#.#.$) "
# https://github.com/jarun/nnn/wiki/Basic-use-cases#shell-depth-indicator
[ -n "$NNNLVL" ] && PS1="N$NNNLVL $PS1"

# Simple, clean prompt: (git) user@host:dir$
#PROMPT="\$(__git_ps1 \"(%s)\")%F{green}%B%n@%m%b%f:%F{blue}%B%~%b%f%(#.#.$) "

# ============================================================================================================
# KEY BINDINGS & ALIASES
# ============================================================================================================

# Quick edit config files
alias erc='$EDITOR  ~/.zshrc'
alias ezp='$EDITOR  ~/.zprofile'
alias eenv='$EDITOR ~/.zshenv'
alias efnv='$EDITOR ~/.config/zsh/zshenv-footer.zsh'

# Full shell reload — replaces zsh_reload() for .zshrc changes (exec is cleaner than sourcing)
alias reload='exec zsh'

# Clear history file
alias hc='[ -f "$HISTFILE" ] && : > "$HISTFILE" && fc -p'

alias yesCol='FORCE_COLOR=1 CLICOLOR_FORCE=1' # Force color in pipe

alias -g nPick="nnn -0p - | tr '\0' ' ' "
# Handy global aliases
alias -g ...='../..'
alias -g R=' | rg --smart-case'
alias -g G=' | grep -i'
alias -g J=' | jq'
alias -g L=' |& less'
alias -g B=' | bat'
alias -g C=' |& pbcopy'
# alias -g C=' |& tr "\n" " " | pbcopy'  # replace newlines with spaces
# alias -g C=' |& tr -d "\012" | pbcopy' # remove all newlines
alias -g P=' $(pbpaste)'
alias -g X=' |& xargs'
alias -g H=' --help L'
alias -g V=' X ${__MPV_CMD[@]}'
alias -g Z=' | xargs zed --existing'
alias zed='zed --existing'

alias -g DN=' > /dev/null'
alias -g NE=' 2> /dev/null'
alias -g NULL=' > /dev/null 2>&1'

# Suffix alias: open files directly by extension
alias -s json=jless
alias -s txt=less
alias -s md=bat
alias -s log=lnav
alias -s html=open   # macOS: open in default browser
alias -s yaml=bat
alias -s yml=bat
alias -s csv=bat

# ============================================================================================================
# Hotkey Insertions - Text Snippets
# ============================================================================================================
# Insert git commit template (Ctrl+X, G, C)
# \C-b moves cursor back one position
# bindkey -s '^Zgc' 'git commit -m ""'

# More examples:
# bindkey -s '^Zgp' 'git push origin '
# bindkey -s '^Zgs' 'git status\n'
# bindkey -s '^Zgl' 'git log --oneline -n 10\n'

# ============================================================================================================
# NOTES ON ZSH STARTUP ORDER (kept for reference)
# ============================================================================================================

# When a new interactive zsh starts on macOS, the order is:
# ~/.zshenv → ~/.zprofile → ~/.zshrc → ~/.zlogin

# /bin/zsh -i
# ├── ~/.zshenv
# │   └── ~/.config/zsh/zshenv-footer.zsh
# │       └── ~/.config/zsh/functions.zsh
# ├── ~/.zprofile
# ├── ~/.zshrc
# │   └── ~/.config/zsh/alias.zsh
# │   └── ~/.config/zsh/plugins.zsh
# ├── ~/.zlogin
# └── ~/.zlogout    (only when exiting)

# You mentioned a zsh() function that sources .zshenv/.zprofile again — that's redundant and potentially dangerous.
# It has been removed to keep things clean and avoid double-sourcing environment variables.
# If you need private env vars, put them in ~/.zshenv (sourced first and always).

function zsh_reload() {
	if [ -f "$HOME/.zshenv" ]; then
		# THIS FILE WILL CONTAIN ALL THE PRIVATE CONFIGURATION, WHICH I CAN'T PUBLISH ON git hub
		source "$HOME/.zshenv"

		#THIS FILE WILL CONTAIN ALL THE ENVIRONMENT VARIABLE AND THE CONFIGURATION WHICH I COMFORTABLE TO PUBLISH ON GITHUB
		# source "$HOME/.config/zsh/zshenv-footer.zsh"
	fi

	if [ -f "$HOME/.zprofile" ]; then
		source "$HOME/.zprofile"
	fi

	# Also reload this file itself so changes here take effect
	source "$HOME/.zshrc"
}
# ============================================================================================================
