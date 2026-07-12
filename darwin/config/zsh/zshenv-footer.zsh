# printf "Importing \t %s \n" "$HOME.config/zsh/zshenv-footer.zsh"

# echo "[ -f "$HOME/.config/zsh/zshenv-footer.zsh" ] && source "$HOME/.config/zsh/zshenv-footer.zsh"" >> ~/.zshenv

# SUPPORTING SOME PRIVATE VARIABLES INSIDE .zshenv =============================
# export ARIA2C_SESSION_TOKEN="go to ~/.zshenv"
# export GITHUB_AUTH_TOKEN="go to    ~/.zshenv"     # this pritam_lpu_12416
# ==============================================================================

# -----------------------------------------------
# Helper to safely add to PATH without duplicates
# -----------------------------------------------
typeset -gTU PATH path
typeset -gTU MANPATH manpath

# Create tied scalar<->array pairs
typeset -gTU DYLD_LIBRARY_PATH dyld_library_path && export DYLD_LIBRARY_PATH
typeset -gTU PKG_CONFIG_PATH pkg_config_path     && export PKG_CONFIG_PATH
typeset -gTU CMAKE_PREFIX_PATH cmake_prefix_path && export CMAKE_PREFIX_PATH

typeset -gTU CPPFLAGS cppflags ' '               && export CPPFLAGS
typeset -gTU CFLAGS cflags ' '                   && export CFLAGS
typeset -gTU LDFLAGS ldflags ' '                 && export LDFLAGS


autoload -Uz colors && colors
# export FORCE_COLOR=1               # Force ANSI colors                  { Many modern programs }
# export CLICOLOR_FORCE=1            # Force colors (BSD/macOS ecosystem) { Many BSD/macOS tools }
# export NO_COLOR=1                  # Disable colors                     { Many modern programs }
export TERM="xterm-256color"         # getting proper colors

# This changes where ncurses looks for terminal definitions.
export TERMINFO=/usr/share/terminfo  # This changes where ncurses looks for terminal definitions.
# /usr/share/terminfo
# /etc/terminfo
# ~/.terminfo

[ -f "$HOME/.config/zsh/functions.sh" ] && source "$HOME/.config/zsh/functions.sh"

# mkdir -p  "$HOME/.local/share/ca-certificates" && wget "https://curl.se/ca/cacert.pem" -O "$HOME/.local/share/ca-certificates/cacert.pem" --no-check-certificate
export SSL_CERT_FILE="$HOME/.local/share/ca-certificates/cacert.pem"
export SSL_CERT_DIR="$HOME/.local/share/ca-certificates"

# export CURL_CA_BUNDLE="$HOME/.local/share/ca-certificates"
export MK_CERT_DIR="$HOME/.local/share/mkcert/ca-certificates"
export BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox"

export LOCAL_HOST_TLS_KEY="$MK_CERT_DIR/localhost+2-key.pem"
export LOCAL_HOST_TLS_CERT="$MK_CERT_DIR/localhost+2.pem"

export LIVE_SERVER_TLS_KEY="$LOCAL_HOST_TLS_KEY"
export LIVE_SERVER_TLS_CERT="$LOCAL_HOST_TLS_CERT"

# FOR THE DEVELOPER===========================================================================================
export CXX="/usr/bin/clang++"
export CC="/usr/bin/clang"
export PREFIX="$HOME/.local"
export CMAKE_INSTALL_PREFIX="$PREFIX/"

cppflags+=("-I$PREFIX/include")
cflags+=("-I$PREFIX/include")
ldflags+=("-L$PREFIX/lib")

# export CXXFLAGS="$CPPFLAGS $CXXFLAGS"
dyld_library_path+=("$PREFIX/lib")
pkg_config_path+=("$PREFIX/lib/pkgconfig")
cmake_prefix_path+=("$PREFIX/lib/cmake")

# export Protobuf_DIR="$HOME/.local/dev-tools/lib-protobuf-35.1-dev"
# pkg_config_path+=($HOME/.local/dev-tools/lib-protobuf-35.1-dev/lib/pkgconfig)


export Boost_DIR='/usr/local/boost-1.87.0'
export QT_DIR='/opt/homebrew/opt/qt@5/lib/cmake/Qt5'

export PKGX_DIR="$HOME/.local/pkgx-env"

# FOR PYTHON ======
path+=("/Library/Frameworks/Python.framework/Versions/3.14/bin")
# manpath+=('/Library/Frameworks/Python.framework/Versions/3.14/share/man')

# FOR PIP =========
path+=("$HOME/Library/Python/3.14/bin")
manpath+=("$HOME/Library/Python/3.14/share/man")
fpath+=("$HOME/Library/Python/3.14/share/zsh/site-functions")


# FOR DEVELOPMENT LIBRARIES ==========
path+=('/usr/local/big_library-bin')
export CMAKE_GENERATOR='Ninja'
export CMAKE_EXPORT_COMPILE_COMMANDS=true
export CPP_LIB_DIR='/usr/local/big_library'

dyld_library_path+=(/usr/local/lib)
pkg_config_path+=(/usr/local/lib/pkgconfig)
cmake_prefix_path+=(/usr/local/lib/cmake)

# FOR DEVELOPMENT LIBRARIES ==========
path+=("$HOME/.local/github-releases-binary")
path+=("$HOME/.kelp/bin")

path+=("$HOME/.local/bin")
manpath+=("$HOME/.local/share/man")
fpath+=("$HOME/.local/share/zsh/site-functions")

# https://www.reddit.com/r/zsh/comments/p8ir7r/how_to_disable_vi_style_keybinds_in_zsh/
# export VISUAL='zed --wait'        # $VISUAL use zed  in GUI mode
# export EDITOR="$PREFIX/bin/nvim"  # $EDITOR use nvim in terminal

#  ln -sf "$PREFIX/bin/nvim" "$PREFIX/bin/zsh-editor"
# export EDITOR="$PREFIX/bin/zsh-editor"  # $EDITOR use nvim in terminal

#  ln -sf "$(which hx)" "$PREFIX/bin/vim-helix"
[ -z "$EDITOR" ] && export EDITOR="$PREFIX/bin/vim-helix"  # $EDITOR use helix in terminal

export DOT_FILE="$HOME/Developer/git_repository/dotfiles/darwin"
# ============================================================================================================

# Linux LS color theme =======================================================================================
export CMAKE_COLOR_DIAGNOSTICS='true'     # Enable colored diagnostics in CMake
export CLICOLOR=1                         # Enable colored output for ls
# export CLICOLOR_FORCE=true                # Enable colored output with '$ ls | less'
export PAGER='less'                       # Set default pager to less
export LESS='-Rir --tabs=2 -j5'           # Configure less for raw control characters, case-insensitive search
export LSCOLORS='ExFxBxDxCxegedabagacad'  # BSD colors (for macOS ls)
export LS_COLORS='di=34:ln=36:so=35:pi=33:ex=32:bd=34;46:cd=34;43' # GNU colors (for tree + zsh completion)
export TREE_COLORS="$LS_COLORS"
# export GREP_COLOR='1;92;48;5;22'          # Color with bold green and dimed green background
export GREP_COLOR="1;91;48;5;52"          # Color with bold red and dimed red background
export JQ_COLORS='1;39:0;36:0;36:0;33:0;32:2;37:2;37'
export TROFFONTS="$HOME/Library/Fonts"
# ============================================================================================================

# FZF & SK Configuration =====================================================================================
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/config"
# export SKIM_DEFAULT_COMMAND="fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."
# ============================================================================================================

# Red & Green Man Page Theme (2025 edition) ==================================================================
# Bold text & headings → Bright green (function names, section titles)
export LESS_TERMCAP_md=$'\e[01;38;5;82m' # vivid neon green
# Start blinking (rarely used) → Bright red (makes it actually noticeable)
export LESS_TERMCAP_mb=$'\e[05;38;5;196m' # blinking bright red
export LESS_TERMCAP_so=$'\e[01;97;41m' # bright white on red
# Search highlight bar / standout → White text on red background (super visible)
export LESS_TERMCAP_se=$'\e[0m' # End standout
# Underlined text (options, arguments, --flags) → Bright red underline
export LESS_TERMCAP_us=$'\e[04;38;5;196m' # bright red underline
export LESS_TERMCAP_ue=$'\e[0m' # End underline
export LESS_TERMCAP_me=$'\e[0m' # End all bold/attributes
# ============================================================================================================

# NNN File Manager Integration ===============================================================================
# NNN_GUI_PLUG="!&nohup ${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins/personal"
# Define NNN plugins for various tasks
typeset -gTU NNN_PLUG nnn_plug ';'   &&   export NNN_PLUG

# nnn_plug+=('a:personal/adb_push')
# nnn_plug+=('f:personal/ffplay_playlist')
# nnn_plug+=('r:personal/fix_ugly_name')
# nnn_plug+=('R:personal/mmv_batch_renamer')
nnn_plug+=('q:-personal/preview_with_quicklook')
nnn_plug+=('Q:-personal/preview_thumbnail')
nnn_plug+=('e:-personal/fetch_metadata')
nnn_plug+=('M:personal/mpv_playlist')
nnn_plug+=('C:-personal/copy_path')

# nnn_plug+=('B:personal/zoxide')

nnn_plug+=('i:cdpath')
# nnn_plug+=('I:cbcopy-mac')

# nnn_plug+=("M:$NNN_GUI_PLUG/mpv_playlist >/dev/null 2>&1")

nnn_plug+=('Z:-!&zed -- "$nnn" ')
nnn_plug+=('r:-!tidy-mv -SHn -0 < "$NNN_SEL"  &&  printf '-' > "$NNN_SEL" *')
nnn_plug+=('d:-!git diff -- "$nnn" *')
nnn_plug+=('E:-!get-frame --random --preview --output-dir "$TMPDIR" "$nnn" *')
nnn_plug+=('l:-!&finder_locate "$nnn" ')
nnn_plug+=('c:-!&pathCopy "$nnn" | pbcopy')
nnn_plug+=('o:-!|otool -L -  "$nnn" ')
nnn_plug+=('R:-!mmv -0 < "$NNN_SEL"  &&  printf '-' > "$NNN_SEL" *')
nnn_plug+=('H:-!|hexdump -C --  "$nnn" ')
nnn_plug+=('O:-!openr -l --  "$nnn" *')
#nnn_plug+=('m:-!mpv --no-config --profile=fast --loop-file=inf --mute --geometry=1280+50%+50% -- "$nnn" *')
nnn_plug+=('m:-!mpv --no-config --profile=fast --force-window=immediate --loop-file=inf --mute --autofit=1280 -- "$nnn" * *')
nnn_plug+=('F:-!&ffplay -alwaysontop -loop -1 -sn -loglevel level+warning -seek_interval 5 -- "$nnn" ')
nnn_plug+=('f:-!ffplay  -alwaysontop -loop -1 -sn -loglevel warning -stats -seek_interval 5 -- "$nnn" *')


export NNN_COLORS='5236'                                # Set NNN color scheme
export NNN_OPTS='AUBREodefg'                            # Define NNN options
export NNN_SEL="$TMPDIR/nnn.sel"                        # Define NNN selection file
# export NNN_OPENER='/usr/bin/open'                       # Set default opener for files
# export NNN_OPENER='$HOME/.local/bin/opner'              # Set default opener for files
export NNN_TRASH='/usr/bin/trash'                       # Define NNN trash command
export NNN_FIFO="$TMPDIR/nnn.fifo"                      # Define NNN FIFO file
export NNN_TMPFILE="$TMPDIR/nnn.lastd"                  # Define NNN temporary file for last directory
# export NNN_FCOLORS="c1e2272e006033f7c6d6abc4"           # Define NNN file colors TOTO: make this var work with LS_COLORS
export NNN_HELP="cat $DOT_FILE/config/nnn/nnn_help.txt" # Define NNN help file
export NNN_ARCHIVE="\\.(7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|rar|rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)$" # Define regex for archive file extensions
export LC_ALL='en_US.UTF-8'

# cd ON QUIT WITH FILE MANGER(s)  ============================================================================
function n() {
	[ "${NNNLVL:-0}" -eq 0 ] || {
		echo 'nnn is already running \a'
		return
	}

	command nnn "$@"

	[ ! -f "$NNN_TMPFILE" ] || {
		. "$NNN_TMPFILE"
	}
}

function y() {
	tmp="$TMPDIR/yazi-cwd"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
}

function lf() {
	dir="$(command lf -print-last-dir "$@")"
	while ! cd -- "$dir" 2>/dev/null; do
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

typeset -gTU ENVPATH_VARS envpath_vars ';' && export ENVPATH_VARS;
envpath_vars+=('PATH')
envpath_vars+=('MANPATH')
envpath_vars+=('INFOPATH')
envpath_vars+=('CMAKE_PREFIX_PATH')
envpath_vars+=('PKG_CONFIG_PATH')
envpath_vars+=('DYLD_LIBRARY_PATH')

XXC_DIRS="/Users/pritam/Downloads;"
#XXC_DIRS+="/Users/pritam/Music;"
export XXC_DIRS; # this is for xxc command

# GPG CONFIGURATION ==========================================================================================
# Set GPG_TTY for signing commits with GPG
export GPG_TTY="$(tty)"

# ============================================================================================================

### SETTING XDG ENVIRONMENT VARIABLES ========================================================================
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/Library/Caches"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="$TMPDIR/$UID"
# export XDG_RUNTIME_DIR="/run/user/$UID"
export XDG_CONFIG_DIR="$HOME/.config"
export XDG_DATA_DIRS="/opt/homebrew/share:/usr/local/share:/usr/share"
# ============================================================================================================

# https://dprint.dev/setup/#limiting-parallelism
export DPRINT_MAX_THREADS=4

# https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_538.html
export ARGP_HELP_FMT="rmargin=120"

source ~/.config/broot/launcher/bash/br
