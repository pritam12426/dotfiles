#!/bin/bash

# ================== about this script ==================
# Date created: Wed Jan 07-2026 02:69:00 AM
# User: Pritam <84720825+pritam12426@users.noreply.github.com>
# Newsboat version: 2.42.0
# yt-dlp: version 2025.11.12
# aria2c: version 1.37.0
#
# Purpose: Open Terminal and run yt-dlp command with the current open RSS feed URL from Newsboat.
# This script is designed to be used as an Newsboat script.
# It retrieves the URL of the current tab and opens Terminal to run a yt-dlp command.
# Make sure to adjust the path to your yt-dlp script as needed.
# ========================================================


# export PATH="$HOME/.local/bin:$PATH"
LOG_FILE="$HOME/.local/share/yt-dlp/yt-dlp_newsboat.log"

function yt () {
	local URL="$1"
	local command="$HOME/.local/bin/yt-dlp"

	if ! [[ $URL =~ ^https?:// ]]; then
		message "Not a url" "Newsboat" "error"
		return 1
	fi

	if [[ $URL == https://www.youtube.com/watch* ]]; then
		command+=" \"$URL\""
	elif [[ $URL == https://www.youtube.com/playlist* ]]; then
		command+="--pList \"$URL\""
	elif [[ $URL == https://www.youtube.com/shorts* ]]; then
		command+=" --st \"$URL\""
	elif [[ $URL == https://www.instagram.com* ]]; then
		command+="--st \"$URL\""
	elif [[ $URL == https://www.jiosaavn.com* ]]; then
		command+=" --savan \"$URL\""
	elif [[ $URL == https://music.youtube.com* ]]; then
		command+=" --ysong \"$URL\""
	else
		command+=" \"$URL\""
	fi

	eval "$command"
}

mkdir -p "$(dirname "$LOG_FILE")"

(
	echo "=========== Starting yt-dlp with Newsboatr $(date +"%Y-%b-%d %Ih:%Mm:%Ss %p") ======================="
	yt  "$@"
) 2>&1 | tee "$LOG_FILE"

notify -q "Done" "Newsboat"

echo "Done"
