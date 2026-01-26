# printf "Importing \t %s \n" "$HOME/.config/zsh/functions.sh"

# ===========================================================================
# This shell script contains a collection of utility functions
# and tools to enhance productivity and streamline workflows.
# It includes functions for notifications, managing proxy settings,
# wget and aria2c, taking screenshots, managing vcpkg libraries,
# and more. Each function is designed to handle specific tasks
# efficiently, with options for customization and flexibility.
# ===========================================================================

# Print bytes by decimal value
function bytes(){
	case $1 in -h|--help|-\?|'')
		printf >&2 'Usage: bytes [0..255]\n'; [ "$1" ]
		return ;;
	esac
	printf %b "`printf \\\\%03o "$@"`"
}

# ------------ Utility Functions ------------
function wireproxy-start() {
	# Start wireproxy in background if not already running
	if pgrep -x wireproxy >/dev/null; then
		echo "wireproxy is already running (PID: $(pgrep wireproxy))."

		printf 'Kill it and restart? (y/n): '
		read -k 1 -r choice
		echo

		case "$choice" in
		[nN])
			# Overring proxy environment variables in current shell
			echo "Proxy environment variables are now override for this session."
			eval "export http_proxy="http://127.0.0.1:8080""
			eval "export https_proxy="http://127.0.0.1:8080""
			eval "export all_proxy="socks5://127.0.0.1:1080""
			eval "export WIREPROXY_HTTP="http://127.0.0.1:8080""
			eval "export WIREPROXY_SOCKET="socks5://127.0.0.1:1080""
			return 0
			;;
		[yY])
			echo "Killing wireproxy (PID: $(pgrep wireproxy))."
			echo "Unseting variables"
			unset http_proxy https_proxy all_proxy WIREPROXY_HTTP WIREPROXY_SOCKET
			pkill wireproxy
			return $?
			;;
		esac
	fi

	wireproxy -d -c ~/.config/wireproxy/wireproxy.conf -i "127.0.0.1:9080"

	# Check if wireproxy actually started successfully
	if [[ $? -eq 0 ]]; then
		echo "wireproxy started successfully: $(pgrep wireproxy)"
		echo "Ports: HTTP → 8080    SOCKS5 → 1080"
		echo "To stop later: pkill wireproxy"

		# Set proxy environment variables in current shell
		eval "export http_proxy="http://127.0.0.1:8080""
		eval "export https_proxy="http://127.0.0.1:8080""
		eval "export all_proxy="socks5://127.0.0.1:1080""
		eval "export WIREPROXY_HTTP="http://127.0.0.1:8080""
		eval "export WIREPROXY_SOCKET="socks5://127.0.0.1:1080""

		echo "Proxy environment variables are now set for this session."
	fi
}

function findDuplicate() {
	find . -type f -size +1M -exec cksum {} \; |
		tee /tmp/filelist.tmp |
		cut -f 1,2 -d ' ' |
		sort |
		uniq -d |
		grep -hif - /tmp/filelist.tmp |
		sort -nrk2
}

function ww() {
	# --no-check-certificate \
	command wget \
		-c "$(pbpaste)"
}

# List all Makefile targets
function _make_() {
	command make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}' | command sort -u
}

function wi() {
	readlink -f "$(which "$1")"
}

# Open documentation file using fzf
function lldoc() {
	local doc

	doc=$(sk < "$CPP_LIB_DIR/doc.txt")

	if [[ $doc == /* ]] && [[ -f $doc ]]; then
		open "file://$doc"
	elif [[ $doc == http* ]]; then
		open "$doc"
	else
		printf '"%s" not exist' "$doc"
	fi
}

# Take a screenshot with shadow
function ss() {
	screencapture -w "./Screen–short–$(date +"%Y-%b-%d_at_%H.%M.%S").png"
}

# Take a screenshot without shadow
function sss() {
	screencapture -s "./Screen–short–$(date +"%Y-%b-%d_at_%H.%M.%S").png"
}
# --------------------------------------------------

# ------------ Aria2c Function ---------------
# Function to download content using aria2c
function ari() {
	# Display download information
	echo -e "aria2c \033[1;36m==> [ \033[1;33mURL: \033[1;35m$(pbpaste)\033[1;36m ] <==\033[0m"

	# --force-sequential=true \
	# --remove-control-file \

	# Execute aria2c command
	command aria2c \
		--dir="$PWD" \
		"$*" "$(pbpaste)"
}

function streem-aria2c() {
	# Display download information
	echo -e "\033[1;36m==> [ \033[1;33mStreem URL: \033[1;35m$(pbpaste)\033[1;36m ] <==\033[0m"

	# --on-download-complete
	# --select-file=1,5-7 <TORRENT>

	# Execute aria2c command
	command aria2c \
		-Z \
		"$@" "$(pbpaste)"
}
# ---------------------------------------------

# ------------ Vcpkg Function -----------------
# Function to manage vcpkg libraries with smart triplet handling
function vcpkg() {
	local VCPKG="/usr/local/bin/vcpkg" # Full path to the vcpkg executable

	if [[ $1 == "install" ]]; then
		shift # Remove 'install'
		for lib in "$@"; do
			# Install library for Debug (Dynamic)
			echo "===[ Installing $lib (Debug → Dynamic, debug-only)...    ]==="
			echo "===> vcpkg install $lib --triplet arm64-osx-dynamic <==="
			VCPKG_BUILD_TYPE=debug "$VCPKG" install "$lib" --triplet arm64-osx-dynamic

			# Install library for Release (Static)
			echo "===[ Installing $lib (Release → Static, Release-only)... ]==="
			echo "===> vcpkg install $lib --triplet arm64-osx <==="
			VCPKG_BUILD_TYPE=release "$VCPKG" install "$lib" --triplet arm64-osx
		done
	elif [[ $1 == "rem" ]]; then
		shift # Remove 'rem'
		for lib in "$@"; do
			# Remove library for Debug (Dynamic)
			echo "===[ Removing $lib (Debug → Dynamic, debug-only)...    ]==="
			echo "===> vcpkg remove $lib --triplet arm64-osx-dynamic <==="
			"$VCPKG" remove "$lib" --triplet arm64-osx-dynamic

			# Remove library for Release (Static)
			echo "===[ Removing $lib (Release → Static, Release-only)... ]==="
			echo "===> vcpkg remove $lib --triplet arm64-osx <==="
			"$VCPKG" remove "$lib" --triplet arm64-osx
		done
	else
		# Forward all other commands to vcpkg
		"$VCPKG" "$@"
	fi

	# add this at the top of the file     $CMAKE_TOOLCHAIN_FILE
	# if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	#   set(VCPKG_TARGET_TRIPLET "arm64-osx-dynamic")
	# else()
	#   set(VCPKG_TARGET_TRIPLET "arm64-osx")
	# endif()
}
# --------------------------------------------------

# ------------ Gallery-dl Function ------------
# Function to download content using gallery-dl
function gg() {
	# Default destination directory
	local dest="$HOME/Downloads/yt_dlp/posts"
	# local fileName="{category}-{username}-{date:%Y-%m-%d}-{num}.{extension}"

	# If first argument is '-', use the current directory as destination
	if [[ $1 == "-" ]]; then
		dest="$PWD"
		shift # Remove the '-' from $@
	fi

	# If first argument is 'xx', modify destination path
	if [[ $1 == "xx" ]]; then
		dest+="/../.dlpxx/post"
		shift # Remove 'xx' from $@
	fi

	# Display download information
	echo -e "\033[1;36m===[ gallery-dl \033[1;33mDownloading to: \033[1;35m$dest\033[1;36m ]===\033[0m"
	echo -e "\033[1;36m===[ \033[1;33mURL: \033[1;35m$(pbpaste)\033[1;36m ]===\033[0m"

	# Execute gallery-dl command
	gallery-dl --cookies-from-browser firefox --destination "$dest" "$@" "$(pbpaste)"
}
# ---------------------------------------------

# ------------ Link Executables Function -------
# Function to create symbolic links for executables in a target directory
function dot-deploy() {
	local mode="all"
	local target_dir
	local dry_run=false # Default to false

	# ---- option parsing ----
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--bin)
			mode="bin"
			shift
			;;
		-n | --dry-run)
			dry_run=true
			shift
			;;
		--help)
			echo "Usage: dot-link [--bin] [-d|--dry-run] [target_directory]"
			return 0
			;;
		*)
			target_dir="$1"
			shift
			;;
		esac
	done

	# ---- default target directory ----
	if [[ -z $target_dir && $mode == "bin" ]]; then
		target_dir="$HOME/.local/bin"
	fi

	if [[ -z $target_dir ]]; then
		echo "❌ Error: Target directory not specified."
		return 1
	fi

	# ---- dry run announcement ----
	if [[ $dry_run == true ]]; then
		echo -e "\033[1;35m🔍 DRY RUN MODE: No changes will be made.\033[0m"
	fi

	# ---- create directory ----
	if [[ $dry_run == true ]]; then
		echo "[Dry] Would create directory: $target_dir"
	else
		mkdir -p "$target_dir" || return 1
	fi

	# ---- find and link ----
	local find_args=("-maxdepth" "1" "-type" "f")
	[[ $mode == "bin" ]] && find_args+=("-perm" "-111")

	# Use find to get files, excluding hidden ones
	find . "${find_args[@]}" -not -name ".*" -print0 | while IFS= read -r -d '' file; do
		local filename=$(basename "$file")
		local src_path=$(realpath "$file")
		local link_path="$target_dir/$filename"

		if [[ $src_path == "$link_path" ]]; then continue; fi

		if [[ $dry_run == true ]]; then
			echo -e "\033[0;90m[Dry] Would link:\033[0m $filename \033[0;90m→\033[0m $link_path"
		else
			ln -sf "$src_path" "$link_path"
			echo -e "🔗 Linked: \033[0;32m$filename\033[0m -> \033[0;33m$link_path\033[0m"
		fi
	done
}
# ---------------------------------------------

# Initialize C/C++ project templates
function clanginit {
	if [[ $# -lt 2 ]]; then
		echo "Usage: clanginit <c|cxx|c++|ard> <project-name>"
		return 1
	fi

	[[ -z "$DOT_FILE" ]] && { echo "DOT_FILE not set"; return 1; }

	lower_input=$(echo "$1" | tr '[:upper:]' '[:lower:]')

	case "$lower_input" in
	c)
		cp -rvp "$DOT_FILE/../global/c-cpp-template/c/" "$2"
		;;
	c++|cxx)
		cp -rvp "$DOT_FILE/../global/c-cpp-template/c++/" "$2"
		;;
	ard)
		cp -rvp "$DOT_FILE/../global/embedded/arduino-cli-uno/" "$2"
		mv "$2/arduino-cli-uno.ino" "$2/$2.ino"
		;;
	*)
		echo "Unsupported: <c cxx c++ ard>: $1"
		return 1
		;;
	esac
}

# ------------ YT-DLP Functions ------------
function yt() {
	local URL="$(pbpaste)"
	local command=""

	# Check if URL is empty
	if [[ -z $URL ]]; then
		echo "Clipboard is empty or does not contain a URL."
		return 1
	fi

	# Regex to check if the string is a valid HTTP/HTTPS URL
	if ! [[ $URL =~ ^https?:// ]]; then
		echo -e "Clipboard does not contain a valid URL.: \a \033[31m$URL\033[0m"
		return 1
	fi

	if [[ $URL == https://www.youtube.com/watch* ]]; then
		command="yt-dlp $* \"$URL\""
	elif [[ $URL == https://www.youtube.com/playlist* ]]; then
		command="yt-dlp --pList $* \"$URL\""
	elif [[ $URL == https://www.youtube.com/shorts* ]]; then
		command="yt-dlp --st $* \"$URL\""
	elif [[ $URL == https://www.instagram.com* ]]; then
		command="yt-dlp --st $* \"$URL\""
	elif [[ $URL == https://www.jiosaavn.com* ]]; then
		command="yt-dlp --savan $* \"$URL\""
	elif [[ $URL == https://music.youtube.com* ]]; then
		command="yt-dlp --ysong $* \"$URL\""
	else
		command="yt-dlp $* \"$URL\""
	fi

	printf "\033[1;32m%s@%s\033[0m:\033[1;34m%s\033[0m\$ %s\n" "$USER" "$(hostname -s)" "${PWD/#$HOME/~}" "$command"

	eval "$command"

	# Check if yt-dlp command was successful
	if [[ $? -eq 0 ]]; then
		notify "Download completed successfully." "yt-dlp" "info"
	else
		notify "Download failed." "yt-dlp" "error"
		return $?
	fi
}
# -------------------------------------------------------


# ------------ Miscellaneous Functions ------------
# Generate a unified diff with highlighting
diff(){
	set -- diff -r -U4 "$@"
	if [ ! -t 1 ]; then command "$@"; return $?; fi
	command "$@" | format-diff
}

# Pretty-print media file metadata using ffprobe and jq
function hhhh() {
	command ffprobe -v quiet -print_format json -show_format -show_streams "$@" | jq
}

function todo() {
	local todo_file="$HOME/.todo.md"

	if [[ $1 == "add" || $1 == "a" ]]; then
		shift
		echo "$*" >>"$todo_file"
		echo "$*"
	elif [[ $1 == "edit" || $1 == "e" ]]; then
		"$EDITOR" "$todo_file"
	elif [[ $1 == "clean" || $1 == "c" ]]; then
		cat /dev/null > "$todo_file"
	elif [[ $1 == "find" || $1 == "f" ]]; then
		shift
		rg --no-heading --line-number -Li "(TODO:|FIX:|FIXME:|HACK:|NOTE:|XXX:|BUG:|OPTIMIZE:)" "$@"
	else
		bat --theme gruvbox-dark --style=plain --paging=always "$todo_file"
	fi
}

# -----------------------------------------------------
### Function extract for common file formats ###
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

### ARCHIVE EXTRACTION
# usage: ex <file>
function ex() {
	if [ -z "$1" ]; then
		# display usage if no parameters given
		echo "Usage: ex <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
		echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
	else
		for n in "$@"; do
			if [ -f "$n" ]; then
				case "${n%,}" in
				*.cbt | *.tar.bz2 | *.tar.gz | *.tar.xz | *.tbz2 | *.tgz | *.txz | *.tar)
					tar xvf "$n"
					;;
				*.lzma) unlzma ./"$n" ;;
				*.bz2) bunzip2 ./"$n" ;;
				*.cbr | *.rar) unrar x -ad ./"$n" ;;
				*.gz) gunzip ./"$n" ;;
				*.cbz | *.epub | *.zip) unzip ./"$n" ;;
				*.z) uncompress ./"$n" ;;
				*.7z | *.arj | *.cab | *.cb7 | *.chm | *.deb | *.dmg | *.iso | *.lzh | *.msi | *.pkg | *.rpm | *.udf | *.wim | *.xar)
					7z x ./"$n"
					;;
				*.xz) unxz ./"$n" ;;
				*.exe) cabextract ./"$n" ;;
				*.cpio) cpio -id < ./"$n" ;;
				*.cba | *.ace) unace x ./"$n" ;;
				*)
					echo "ex: '$n' - unknown archive method"
					return 1
					;;
				esac
			else
				echo "'$n' - file does not exist"
				return 1
			fi
		done
	fi
}
IFS=$SAVEIFS
# ---------------------------------------------------

function edot() {
	local file
	local base="$DOT_FILE/config"

	# --type l \
	# --follow \
	# --hidden \

	file=$(fd . "$base" \
		--type f \
		--exclude .gitignore |
	sed "s|^$base/||" |
	fzf --height=70% \
		--preview "bat -n --color=always --line-range=:500 '$base/{}' 2>/dev/null"
	)

	[[ -f $base/$file ]] && $EDITOR "$base/$file"
}

# Locate files by name
f(){
	find . -type f -name "*$1*";
}

# pathcp :: Copy absolute file path to clipboard
function pc() {
	if [[ $1 == "--help" ]]; then
		echo "Usage: pc <file|dir|glob>"
		echo "       pc        # copy PWD"
		return 0
	fi

	local out="" f match
	local args

	# If no arguments → use PWD
	if (( $# == 0 )); then
		args=("$PWD")
	else
		args=("$@")
	fi

	for f in "${args[@]}"; do
		for match in $f; do
			# Convert to absolute path (Zsh builtin)
			match="${match:A}"

			# If path contains escapable characters, quote it
			case "$match" in
				*[\ \(\)\[\]\{\}\&\;\!\']*)
					# Escape embedded double quotes
					match="${match//\"/\\\"}"
					match="\"$match\""
					;;
			esac

			if [ "${#args[@]}" -eq 1 ]; then
				out+="$match"
			else
				out+="$match "
			fi

		done
	done

	printf '%s' "$out" | pbcopy
}
# ---------------------------------------------
