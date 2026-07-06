# printf "Importing \t %s \n" "$HOME/.config/zsh/functions.sh"

[[ $- != *i* ]] && return

function cdf() {
	local path dir

	if [[ $# -gt 0 ]]; then
		 path=$1
	else
		IFS= read -r path
	fi

	if [[ -f "$path" ]]; then
		dir=${path:h}  # zsh equivalent of dirname
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
		echo "Usage: headless <command> [args...]"
		return 1
	fi

	nohup "$@" > /dev/null 2>&1 &!
	local pid=$!
	echo "Started '$1' in background (PID: $pid)"
}
alias MPV='headless ${__MPV_CMD[@]}'

function awake4() {
	local pid
	pid=$(pgrep -n "$1") || {
		echo "Process '$1' not found"
		return 1
	}
	echo "[Caffeinate]: waiting for '$1' to (terminate / finish) :: pid=[$pid]"
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
function _make_() {
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
# function ari() {
# 	Display download information
#	print -P "aria2c %B%F{cyan}==> [ %F{yellow}URL: %F{magenta}$(pbpaste)%F{cyan} ] <==%f%b"

# 	--force-sequential=true \
# 	--remove-control-file \

# 	# Execute aria2c command
# 	command aria2c \
# 		--dir="$PWD" \
# 		"$@" "$(pbpaste)"
# }

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
			shift
			;;
		--xx)
			dest+="/../.dlpxx/post"
			shift
			;;
		*)
			break
			;;
		esac
	done

	mkdir -p "$dest" || return 1

	command+=(--destination "$dest")
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
