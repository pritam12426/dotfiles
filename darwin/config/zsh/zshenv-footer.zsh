# printf "Importing \t %s \n" "$HOME.config/zsh/zshenv-footer.zsh"

# echo "[ -f "$HOME/.config/zsh/zshenv-footer.zsh" ] && source "$HOME/.config/zsh/zshenv-footer.zsh"" >> ~/.zshenv

# SUPPORTING SOME PRIVATE VARIABLES INSIDE .zshenv =============================
# export ARIA2C_SESSION_TOKEN="go to ~/.zshenv"
# export GITHUB_AUTH_TOKEN="go to    ~/.zshenv"     # this pritam_lpu_12416
# ==============================================================================

# -----------------------------------------------
# Helper to safely add to PATH without duplicates
# -----------------------------------------------
typeset -g PATH MANPATH

# Safely add a directory to PATH if it exists and is not already included
export PATH="$PATH"
__PATH_ADD() {
	local dir="$1"
	[[ -n $dir && -d $dir ]] || return
	case ":$PATH:" in
	*":$dir:"*) ;;                   # already present → do nothing
	*) PATH="${PATH:+$PATH:}$dir" ;; # append with colon only if PATH is non-empty
	esac
}

# Safely add a directory to MANPATH if it exists and is not already included
export MANPATH="$MANPATH"
# echo $MANPATH
__MANPATH_ADD() {
	local dir="$1"

	[[ -n $dir && -d $dir ]] || return # directory must exist

	# If MANPATH is empty -> add with trailing colon to keep system defaults
	if [[ -z $MANPATH ]]; then
		MANPATH="$dir:"
		return
	fi

	MANPATH="${MANPATH%%:}" # Remove trailing ':' to prevent "::"

	# Add only if not already present
	case ":$MANPATH:" in
		*":$dir:"*) ;; # already exists
		*) MANPATH="$MANPATH:$dir" ;;
	esac
}

autoload -Uz colors && colors

# sudo curl -L https://curl.se/ca/cacert.pem -o /usr/local/etc/ca-certificates/cert.pem
export SSL_CERT_FILE="/usr/local/etc/ca-certificates/cert.pem"
export BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox"

# FOR THE DEVELOPER===========================================================================================
export CXX="/usr/bin/clang++"
export CC="/usr/bin/clang"
export PREFIX="$HOME/.local"
export Boost_DIR="/usr/local/boost-1.87.0"
export PKGX_DIR="$HOME/.local/pkgx-env"

# FOR PYTHON ======
__PATH_ADD "/Library/Frameworks/Python.framework/Versions/3.14/bin"
__MANPATH_ADD "/Library/Frameworks/Python.framework/Versions/3.14/share/man"
__PATH_ADD "$HOME/Library/Python/3.14/bin"
__PATH_ADD "$HOME/Library/Python/3.14/share/man"
fpath=($fpath "$HOME/Library/Python/3.14/share/zsh/site-functions")

# __PATH_ADD "$HOME/Library/Python/3.9/bin"
# __PATH_ADD "$HOME/Library/Python/3.9/share/man"
# fpath=($fpath "$HOME/Library/Python/3.9/share/zsh/site-functions")

# FOR DEVELOPMENT LIBRARIES ==========
__PATH_ADD "/usr/local/big_library-bin"
export CMAKE_GENERATOR=Ninja
export DYLD_LIBRARY_PATH="/usr/local/lib:$DYLD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
export CMAKE_PREFIX_PATH="/usr/local/lib/cmake:$CMAKE_PREFIX_PATH"
export CMAKE_INSTALL_PATH="$PREFIX"
export CPP_LIB_DIR="/usr/local/big_library"

# FOR DEVELOPMENT LIBRARIES ==========
__PATH_ADD "$HOME/.local/bin"
__PATH_ADD "$HOME/.local/github-releases-binary"
__MANPATH_ADD "$HOME/.local/share/man"
fpath=($fpath "$HOME/.local/share/zsh/site-functions")

# https://www.reddit.com/r/zsh/comments/p8ir7r/how_to_disable_vi_style_keybinds_in_zsh/
#  ln -sf "$PREFIX/bin/nvim" "$PREFIX/bin/zsh-editor"

# export EDITOR="hx"
export EDITOR="$PREFIX/bin/zsh-editor"  # $EDITOR use nvim in terminal
# export VISUAL="zed --wait"      # $VISUAL use zed  in GUI mode
export DOT_FILE="$HOME/Developer/git_repository/dotfiles/darwin"
#export TERM="xterm-256color"                   # getting proper colors
# ============================================================================================================

# Linux LS color theme =======================================================================================
export ZED_ALLOW_ROOT=true               # Allow Zed editor to run as root
export CMAKE_COLOR_DIAGNOSTICS=true      # Enable colored diagnostics in CMake
export CLICOLOR=true                     # Enable colored output for ls
export PAGER="less"                      # Set default pager to less
export LESS="-Rir --tabs=2 -j5"          # Configure less for raw control characters, case-insensitive search
export LSCOLORS="ExFxBxDxCxegedabagacad" # Define ls color scheme
export LS_COLORS="$LSCOLORS"
export GREP_COLORS="sl=38;5;240:mt=1;38;5;10;48;5;22:fn=38;5;242:se=38;5;237:ln=38;5;10"
export JQ_COLORS='1;39:0;36:0;36:0;33:0;32:2;37:2;37'
export TROFFONTS="$HOME/Library/Fonts"
# ============================================================================================================

# FZF & SK Configuration ==========================================================================================
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/config"
# export SKIM_DEFAULT_COMMAND="fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."
# ============================================================================================================

# Red & Green Man Page Theme (2025 edition) ==================================================================
# Bold text & headings → Bright green (function names, section titles)
export LESS_TERMCAP_md=$'\e[01;38;5;82m' # vivid neon green

# Start blinking (rarely used) → Bright red (makes it actually noticeable)
export LESS_TERMCAP_mb=$'\e[05;38;5;196m' # blinking bright red

# Search highlight bar / standout → White text on red background (super visible)
export LESS_TERMCAP_so=$'\e[01;97;41m' # bright white on red

# End standout
export LESS_TERMCAP_se=$'\e[0m'

# Underlined text (options, arguments, --flags) → Bright red underline
export LESS_TERMCAP_us=$'\e[04;38;5;196m' # bright red underline

# End underline
export LESS_TERMCAP_ue=$'\e[0m'

# End all bold/attributes
export LESS_TERMCAP_me=$'\e[0m'
# ============================================================================================================

# NNN File Manager Integration ===============================================================================
NNN_GUI_PLUG="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins/personal"
# Define NNN plugins for various tasks
NNN_PLUG="a:personal/adb_push;"
NNN_PLUG+="r:personal/fix_ugly_name;"
NNN_PLUG+="p:personal/ffplay_playlist;"
NNN_PLUG+="e:-personal/fetch_metadata;"
NNN_PLUG+="q:-personal/perview_with_quicklook;"
NNN_PLUG+="C:-personal/copy_path;"
NNN_PLUG+='i:personal/zoxide;'
NNN_PLUG+='m:personal/mpv_playlist;'
NNN_PLUG+='R:personal/mmv_batch_renamer;'

# NNN_PLUG+="Z:!&nohup '$NNN_GUI_PLUG/mpv_playlist' >/dev/null 2>&1;"
# NNN_PLUG+='I:cbcopy-mac;'

NNN_PLUG+='z:-!&zed "$nnn" ;'
NNN_PLUG+='o:-!|otool -L "$nnn" ;'
NNN_PLUG+='f:-!&ffplay -loop -1 -sn -loglevel level+warning -seek_interval 5 "$nnn" ;'

export NNN_PLUG
export NNN_COLORS="5236"                                # Set NNN color scheme
export NNN_OPTS="AUBRNEodefag"                          # Define NNN options
export NNN_SEL="$TMPDIR/nnn.sel"                        # Define NNN selection file
export NNN_OPENER="/usr/bin/open"                       # Set default opener for files
export NNN_TRASH="/usr/bin/trash"                       # Define NNN trash command
export NNN_FIFO="$TMPDIR/nnn.fifo"                      # Define NNN FIFO file
export NNN_TMPFILE="$TMPDIR/nnn.lastd"                  # Define NNN temporary file for last directory
export NNN_FCOLORS="c1e2272e006033f7c6d6abc4"           # Define NNN file colors
export NNN_HELP="cat $DOT_FILE/config/nnn/nnn_help.txt" # Define NNN help file
export NNN_ARCHIVE="\\.(7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|rar|rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)$" # Define regex for archive file extensions
export LC_ALL="en_US.UTF-8"

# cd ON QUIT WITH FILE MANGER(S)
function n() {
	[ "${NNNLVL:-0}" -eq 0 ] || {
		echo "nnn is already running"
		return
	}

	command nnn "$@"

	[ ! -f "$NNN_TMPFILE" ] || {
		. "$NNN_TMPFILE"
	}
}

function y() {
	tmp="$TMPDIR/yazi-cwd.XXXXXX"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
}

funcion lf() {
	dir="$(command lf -print-last-dir "$@")"
	while ! cd "$dir" 2>/dev/null; do
		dir="$(dirname -- "$dir")"
	done
}

function ranger() {
	ID="$$"
	OUTPUT_FILE="$TMPDIR/joshuto-cwd-$ID"
	command joshuto --output-file "$OUTPUT_FILE" "$@"
	exit_code="$?"

	case "$exit_code" in
	# regular exit
	0) ;;
	# output contains current directory
	101)
		JOSHUTO_CWD=$(<"$OUTPUT_FILE")
		builtin cd "$JOSHUTO_CWD" || return
		;;
	# output selected files
	102) ;;
	*)
		echo "Exit code: $exit_code"
		;;
	esac
}

# ============================================================================================================

# GPG CONFIGURATION ==========================================================================================
# Set GPG_TTY for signing commits with GPG
export GPG_TTY=$(tty)
# ============================================================================================================

### SETTING XDG ENVIRONMENT VARIABLES ========================================================================
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/Library/Caches"
export XDG_RUNTIME_DIR="$TMPDIR"
# ============================================================================================================

if [ -f "$HOME/.config/zsh/functions.sh" ]; then
	source "$HOME/.config/zsh/functions.sh"
fi

source ~/.config/broot/launcher/bash/br
