#!/bin/sh

# ================== about this script ==================
# Date created: Sat Nov 29-2025 02:30:00 AM
# User: Pritam <84720825+pritam12426@users.noreply.github.com>
# Orion browser version: 1.0.0
# yt-dlp: version 2025.11.12
# aria2c: version 1.37.0

# Purpose: Open Terminal and run yt-dlp command with the current tab URL from Orion browser.
# This script is designed to be used as an Orion browser script.
# It retrieves the URL of the current tab and opens Terminal to run a yt-dlp command.
# Make sure to adjust the path to your yt-dlp script as needed.
# ========================================================

export PATH="$HOME/.local/bin:$PATH"
LOG_FILE="$HOME/.local/share/yt-dlp/orion_broser.log"

function notify() {
	local msg="$1"
	local title="${2:-Notification}"
	local type="${3:-info}" # info | error | log

	# Check for --help option
	if [[ $msg == "--help" ]]; then
		echo "Usage: notify <message> [title] [type]"
		echo "  <message>: The notification message to display."
		echo "  [title]:   Optional. The title of the notification. Default is 'Notification'."
		echo "  [type]:    Optional. The type of notification. Can be 'info', 'error', or 'log'. Default is 'info'."
		return 0
	fi

	# Choose sound based on type
	local sound="default"
	case "$type" in
	error)
		sound="Basso"
		;; # macOS built-in alert
	log)
		sound="Pop"
		;; # subtle sound
	info)
		sound="default"
		;; # generic notification
	esac

	# Send notification
	osascript -e "display notification \"$msg\" with title \"$title\" sound name \"$sound\"" 2 &>/dev/null
}

function message() {
	local msg="$1"
	local title="${2:-Notification}"
	local type="${3:-info}"

	# Check for --help option
	if [[ $msg == "--help" ]]; then
		echo "Usage: message <message> [title] [type]"
		echo "  <message>: The notification message to display."
		echo "  [title]:   Optional. The title of the notification. Default is 'Notification'."
		echo "  [type]:    Optional. The type of notification. Can be 'info', 'error', or 'log'. Default is 'info'."
		return 0
	fi

	case "$type" in
	error)
		osascript -e "display alert \"$title\" message \"$msg\" as critical" 2 &>/dev/null
		;;
	warning)
		osascript -e "display alert \"$title\" message \"$msg\" as warning" 2 &>/dev/null
		;;
	info | *)
		osascript -e "display alert \"$title\" message \"$msg\" as informational" 2 &>/dev/null
		;;
	esac
}

function yt () {
	local URL="$1"
	local CC="yt-dlp"
	local command="yt-dlp  --newline "

	if ! [[ $URL =~ ^https?:// ]]; then
		message "Not a url" "Orion" "error"
		return 1
	fi

	if [[ $URL == https://www.youtube.com/watch* ]]; then
		message "Standard YouTube video downloads are not supported in Orion Browser script." "Orion" "error"
		exit 1
	elif [[ $URL == https://www.youtube.com/playlist* ]]; then
		message "Playlist downloads are not supported in Orion Browser script." "Orion" "error"
		exit 1
	elif [[ $URL == https://www.youtube.com/shorts* ]]; then
		command+=" --st $* \"$URL\""
	elif [[ $URL == https://www.instagram.com* ]]; then
		command+="--st $* \"$URL\""
	elif [[ $URL == https://www.jiosaavn.com* ]]; then
		command+=" --savan $* \"$URL\""
	elif [[ $URL == https://music.youtube.com* ]]; then
		command+=" --ysong $* \"$URL\""
	fi

	notify "Starting download with $CC..." "Orion" "info"

	echo "=== Executing command: $command ===" >> "$LOG_FILE"
	eval "$command"

	if [[ $? -eq 0 ]]
	then
		notify "Download completed successfully." "yt-dlp" "info"
	else
		message "$URL" "Orion Error" "error"
		return $?
	fi
}

mkdir -p "$(dirname "$LOG_FILE")"

echo "=========== Starting yt-dlp with Orion Browser $(date +"%Y-%b-%d %Ih:%Mm:%Ss %p") =======================" > "$LOG_FILE"
yt  "$@" >> "$LOG_FILE" 2>&1
