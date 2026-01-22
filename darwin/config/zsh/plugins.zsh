# ============================================================================================================
# IMPORTING EXTERNAL FILES AND PLUGINS
# ============================================================================================================
__ZSH_PULGINS_DIR="$HOME/.local/share/zsh/plugins"

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
	# source "$__ZSH_PULGINS_DIR/__zoxide__"
else
	if hash zoxide 2>/dev/null; then
		printf "Warning: zoxide widget not installed (%s:%d)\n" "$HOME/.zshrc" $LINENO
		# To install: zoxide init --cmd cd zsh > "$__ZSH_PULGINS_DIR/__zoxide__"
	fi
fi

# zsh-you-should-use (actively used)
# https://github.com/MichaelAquilina/zsh-you-should-use/archive/refs/heads/master.zip
if [[ -f "$__ZSH_PULGINS_DIR/zsh-you-should-use/you-should-use.plugin.zsh" ]]; then
	source "$__ZSH_PULGINS_DIR/zsh-you-should-use/you-should-use.plugin.zsh"
fi

# fast-syntax-highlighting — currently disabled (uncomment if you want it later)
# https://github.com/zdharma-continuum/fast-syntax-highlighting
#if [[ -f "$__ZSH_PULGINS_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
#	source "$__ZSH_PULGINS_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
#fi

# zsh-autosuggestions — currently disabled (uncomment if you want it later)
# https://github.com/zsh-users/zsh-autosuggestions
#if [[ -f "$__ZSH_PULGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
#	source "$__ZSH_PULGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
#fi
