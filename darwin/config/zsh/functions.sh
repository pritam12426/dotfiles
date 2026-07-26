# printf "Importing \t %s \n" "$HOME/.config/zsh/functions.sh"

[[ $- != *i* ]] && return

function cdf() {
	local path dir git
	local book_mark_file="$HOME/.cache/_cdf.txt"

	case "$1" in
	-e | --edit)
		"${EDITOR:-vi}" "$book_mark_file"
		return
		;;
	-G | --git)
		shift
		git=true
		;;
	-a | --append)
		local target="${2:-$PWD}"
		if [[ ! -d $target ]]; then
			echo "cdf: --append: '$target' is not a directory" >&2
			return 1
		fi
		target="${target:A}"
		if [[ -f $book_mark_file ]] && /usr/bin/grep -qxF "$target" "$book_mark_file"; then
			echo "cdf: already bookmarked: $target" >&2
			return 0
		fi
		echo "$target" >> "$book_mark_file"
		echo "cdf: bookmarked $target"
		return 0
		;;
	-h | --help)
		echo "Usage: cdf [path] | -a|--append [dir] | -d|--delete [dir] | -e|--edit | -c|--clean"
		echo "  (no args)           Fuzzy-pick a bookmark and cd there"
		echo "  path                cd to path (or its parent folder, if path is a file)"
		echo "  -a, --append [dir]  Bookmark dir (default: current directory)"
		echo "  -d, --delete [dir]  Remove a bookmark (fuzzy-pick if dir is omitted)"
		return 0
		;;
	--*)
		echo "cdf: unknown option '$1'" >&2
		return 1
		;;
	esac

	if [[ $# -gt 0 ]]; then
		path=$1
		if [[ -d $path ]]; then
			cd -- "$path"
			return
		fi
	elif [[ $git == "true" ]]; then
		# path=$(/opt/homebrew/bin/sk --prompt="Chdir > " --case=smart --reverse --height=40% < "$XDG_DATA_HOME/gitm/registered_repos.txt")
		# path=${path%%:*}

		path=$(/usr/bin/cut -d':' -f1 "$XDG_DATA_HOME/gitm/registered_repos.txt" |
			/opt/homebrew/bin/sk --prompt="Chdir > " --case=smart --reverse --height=40%)  || return 0
	elif [[ -t 0 ]]; then
		[[ -s $book_mark_file ]] || {
			echo "cdf: no bookmarks yet, run 'cdf --append' first" >&2
			return 1
		}
		path=$(/usr/bin/grep -v '^[[:space:]]*$' "$book_mark_file" |
			/opt/homebrew/bin/sk --prompt="Chdir > " --case=smart --reverse --height=40%) || return 0
	else
		IFS= read -r path
	fi

	if [[ -z $path ]]; then
		echo "cdf: empty path" >&2
		return 1
	fi

	if [[ -f $path ]]; then
		dir=${path:h}
	else
		dir=$path
	fi

	cd -- "$dir"
}

function wanip_info() {
	local ip
	ip=$(curl -sL https://ifconfig.me/ip)
	curl -sL "http://ip-api.com/json/${ip}" | jq
}

# Print bytes by decimal value
function bytes() {
	case $1 in
	-h | --help | -\? | '')
		printf >&2 'Usage: bytes [0..255]\n'
		[ "$1" ]
		return
		;;
	esac
	printf "%b\n" "$(printf \\%03o "$@")"
}

function headless() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: headless <command> [args...]" >&2
		return 1
	fi

	nohup "$@" > /dev/null 2>&1 &
	local pid=$!
	disown 2> /dev/null
	echo "Started '$1' in background (PID: $pid)"
}
alias MPV='headless ${__MPV_CMD[@]}'

function awake4() {
	local pid
	local command_name

	# 1. Try to find the PID by name, or fall back to sk selection
	pid=$(pgrep -n "$1" 2> /dev/null) || {
		pid=$(ps -U "$USER" -o pid,comm | sk --case=smart --reverse | awk '{print $1}')
	}

	# 2. Exit early if user hits ESC or cancels sk
	if [ -z "$pid" ]; then
		echo "No process selected."
		return 1
	fi

	# 3. Fetch the command name cleanly using the lowercase variable
	command_name=$(ps -p "$pid" -o comm=)

	# 4. Run caffeinate and keep the Mac awake
	echo "[Caffeinate -i]: waiting for '$command_name' to (terminate / finish) :: pid=[$pid]"
	# caffeinate -s — keep it fully awake as long as it's plugged in (great for long downloads)
	# -u — "I'm actively using this right now!"
	# If the screen is off, this wakes it up and keeps it awake —
	# like nudging the kid and saying "stay up, I need you."
	# By itself it only lasts 5 seconds unless you also give it a -t timer.

	# $ pmset -g  <run this for more info>
	caffeinate -iw "$pid"
}

# ------------ Utility Functions ------------
function find-duplicate() {
	find . -type f -size +1M -exec cksum {} \; |
		tee /tmp/filelist.tmp |
		cut -f 1,2 -d ' ' |
		sort |
		uniq -d |
		grep -hif - /tmp/filelist.tmp |
		sort -nrk2

	# OR you can use < https://github.com/pkolaczk/fclones?tab=readme-ov-file#benchmarks >
	#     < fclone   | https://github.com/pkolaczk/fclones        | Rust >
	#     < dskDitto | https://github.com/jdefrancesco/dskDitto   | goLang >
	#     < fdupes   | https://github.com/adrianlopezroche/fdupes | C >
	#     < rdfind   | https://github.com/pauldreik/rdfind        | C++ >
}

function ww() {
	local URL=""
	URL="$(pbpaste)"

	local command=(/usr/local/bin/wget -c)

	command+=("$@")
	print -s -- "${command[*]} '$URL'"
	# echo "${command[*]} '$URL'" >> "$HISTFILE"

	command+=("$URL")
	(sleep 0.5; caffeinate -iw "$(pgrep wget)")&

	"${command[@]}"
	error_code="$?"

	# Check if yt-dlp command was successful
	if [[ $error_code -eq 0 ]]; then
		notify "Download completed successfully." "wget" "info"
	else
		notify "Download failed." "wget" "error"
		return $error_code
	fi

	return 0
}

# List all Makefile targets
function make_tree() {
	command make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}' | command sort -u
}

function wi() {
	readlink -f $(which -a "$1")
}

# Open documentation file using skim (fzf)
function lldoc() {
	local doc

	# Ensure doc list exists
	if [[ ! -f "$CPP_LIB_DIR/doc.txt" ]]; then
		echo "✘ doc list not found: $CPP_LIB_DIR/doc.txt"
		return 1
	fi

	doc=$(sk --prompt="Docs > " --height=40% < "$CPP_LIB_DIR/doc.txt") || return
	# doc=$(fzf --prompt="Docs > " < "$CPP_LIB_DIR/doc.txt") || return

	# Empty selection
	[[ -z $doc ]] && return 1

	# Expand ~ if present
	# doc="${doc/#\~/$HOME}"

	if [[ $doc =~ ^https?:// ]]; then
		open "$doc"
	elif [[ -f $doc ]]; then
		open "file://$doc"
	else
		echo "✘ Not found: $doc"
		return 1
	fi
}

# Take a screenshot with / without shadow
function screenshot() {
	local mode="window"

	case "$1" in
	--window | -w | "")
		mode="window"
		;;
	--select | -s)
		mode="select"
		;;
	--no-shadow | -o)
		mode="no-shadow"
		;;
	--help | -h)
		echo "Usage: screenshot [--window|-w] [--select|-s] [--no-shadow|-o]"
		echo "  --window,    -w   Capture a window, with shadow (default)"
		echo "  --select,    -s   Drag-select a region (no shadow — it's not a window)"
		echo "  --no-shadow, -o   Capture a window, shadow removed"
		return 0
		;;
	*)
		echo "screenshot: unknown option '$1'" >&2
		echo "Usage: screenshot [--window|-w] [--select|-s] [--no-shadow|-o]" >&2
		return 1
		;;
	esac

	local filename="Screenshot-$(date +"%Y-%b-%d_at_%H.%M.%S").png"

	case "$mode" in
	window) screencapture -w "$filename" ;;
	select) screencapture -s "$filename" ;;
	no-shadow) screencapture -w -o "$filename" ;;
	esac

	[[ -f $filename ]] && echo "Saved: $filename"
}
# --------------------------------------------------

function streem-aria2c() {
	# Display download information
	print -r -- "${fg_bold[cyan]}==> [ ${fg_bold[yellow]}Streem URL: ${fg_bold[magenta]}$(pbpaste)${fg_bold[cyan]} ] <==${reset_color}"

	# --on-download-complete
	# --select-file=1,5-7 <TORRENT>

	# Execute aria2c command
	command aria2c \
		-Z \
		"$@" "$(pbpaste)"
}
# ---------------------------------------------

# ------------ Gallery-dl Function ------------
# Function to download content using gallery-dl
function gly() {
	# Default destination directory
	local dest="$HOME/Downloads/yt_dlp/gallery-dl"
	local URL
	URL="$(pbpaste)"

	local command=(
		gallery-dl
	)

	# Regex to check if the string is a valid HTTP/HTTPS URL
	if [[ -z $URL || ! $URL =~ ^https?:// ]]; then
		print -r -- "Clipboard does not contain a valid URL.: \a ${fg[red]}'$URL'${reset_color}"
		return 1
	fi

	# Argument parsing
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--pwd)
			dest="$PWD"
			command+=(--destination "$dest")
			shift
			;;
		--xx)
			dest+="/../.dlpxx/post"
			command+=(--destination "$dest")
			shift
			;;
		*)
			break
			;;
		esac
	done

	mkdir -p "$dest" || return 1

	command+=("$@")

	# print -s -- "${command[*]} '$URL'"

	command+=("$URL")

	print -r -- "${fg_bold[green]}${USER}@$(hostname -s)${reset_color}:${fg_bold[blue]}${PWD/#$HOME/~}${reset_color}\$ ${command[*]}"

	# (sleep 0.5; caffeinate -iw "$(pgrep gallery-dl)")&

	"${command[@]}"
	error_code="$?"

	# Check if yt-dlp command was successful
	if [[ $error_code -eq 0 ]]; then
		notify "Download completed successfully." "gallery-dl" "info"
	else
		notify "Download failed." "gallery-dl" "error"
		return $error_code
	fi
}
# ---------------------------------------------

# ------------ YT-DLP Functions ------------
function yt() {
	local URL=""
	local fallback=0
	local run_caff=false
	URL="$(pbpaste)"
	# URL="$(pbpaste | tr -d '\n' | xargs)"

	local tmp_file="${TMPDIR:-/tmp}/per-url-Yt-dlp.tmp"
	local command=(yt-dlp)
	local notificationDomain="Generic Download"

	# If clipboard empty → fallback
	if [[ -z $URL ]]; then
		if [[ -s $tmp_file ]]; then
			fallback=1
			URL="$(< "$tmp_file")"
		else
			echo "Clipboard is empty or does not contain a URL."
			return 1
		fi
	fi

	# Validate format
	if ! [[ $URL =~ ^https?://[^[:space:]]+ ]]; then
		if [[ -s $tmp_file ]]; then
			fallback=true
			URL="$(< "$tmp_file")"
		else
			print -r -- "%F{red}Invalid URL: '$URL'%f"
			return 1
		fi
	fi

	case "$URL" in
		*youtube.com/watch* )
			notificationDomain="YouTube Video"
			command+=(--cookies-from-browser firefox)
			run_caff=true
			;;
		*youtube.com/playlist* )
			notificationDomain="YouTube Playlist"
			command+=(
				--pList
				--cookies-from-browser firefox
			)
			run_caff=true
			;;
		*youtube.com/shorts* )
			notificationDomain="YouTube Short"
			command+=(--st)
			;;
		*music.youtube.com* )
			notificationDomain="YouTube Music"
			command+=(--ysong)
			;;
		*instagram.com* )
			notificationDomain="Instagram Reel"
			command+=(--st)
			;;
		*jiosaavn.com* )
			notificationDomain="Jio Savan Song"
			command+=(--savan)
			;;
	esac

	command+=("$@")
	print -s -- "${command[*]} '$URL'"
	# echo "${command[*]} '$URL'" >> "$HISTFILE"

	command+=("$URL")
	print -r -- "${fg_bold[green]}${USER}@$(hostname -s)${reset_color}:${fg_bold[blue]}${PWD/#$HOME/~}${reset_color}\$ ${command[*]}"

	if [[ $fallback == "true" ]]; then
		print -P "[ zsh – yt ] Invalid URL ( %B%U%F{yellow}'$(pbpaste)'%f%u%b ). Falling back to last saved URL..."
		print -P "[ zsh - yt ] URL: => ( %F{red}'$URL'%f )"
	fi

	if [[ $run_caff == "true" ]]; then
		(sleep 0.5; caffeinate -iw "$(pgrep yt-dlp)")&
	fi

	"${command[@]}"
	error_code="$?"

	# Check if yt-dlp command was successful
	if [[ $error_code -eq 0 ]]; then
		echo "$URL" > "$tmp_file"
		notify "Download completed successfully." "$notificationDomain" "info"
	else
		notify "Download failed." "yt-dlp" "error"
		return $error_code
	fi

	return 0
}
# -------------------------------------------------------

# ------------ Miscellaneous Functions ------------
# Generate a unified diff with highlighting
function diff() {
	set -- diff -r -u "$@"
	if [ ! -t 1 ]; then
		command "$@"
		return $?
	fi
	command "$@" | diff-so-fancy
}

# Locate files by name
function ffind() {
	find . -type f -name "*$1*"
}

# pathcp :: Copy absolute file path to clipboard
function pc() {
	# if len of args is 0, use PWD
	if [ $# -eq 0 ]; then
		printf "$PWD" | pbcopy
	else
		"$DOT_FILE/binary_exe/pathCopy" "$@" | pbcopy
	fi
}
# ---------------------------------------------

# Stream everything live
logf() {
	log stream --style compact "$@"
}

# Stream logs from a process
logp() {
	log stream --style compact \
		--predicate "process == \"$1\""
}

# Stream logs from a process with a minimum level
logpl() {
	log stream --style compact \
		--level "${2:-debug}" \
		--predicate "process == \"$1\""
}

# Show previous logs from a process
logshow() {
	log show --style compact \
		--last "${2:-10m}" \
		--predicate "process == \"$1\""
}


logkernel() {
	log stream --style compact \
		--predicate 'subsystem == "com.apple.kernel"' "$@"
}

# Search messages
loggrep() {
	log show --style compact \
		--last "${2:-1h}" \
		--predicate "eventMessage CONTAINS[c] \"$1\"" logkernel
}
alias logerr='log stream --style compact --predicate "messageType == error"'                 # Follow only errors
alias logfault='log stream --style compact --predicate "messageType == fault"'               # Follow only faults
