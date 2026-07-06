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

function yt () {
	local URL="$1"
	local CC="yt-dlp"
	local command="yt-dlp "

	if ! [[ $URL =~ ^https?:// ]]; then
		message "Not a url" "Orion" "error"
		return 1
	fi

	if [[ $URL == https://www.youtube.com/watch* ]]; then
		command+=" \"$URL\""
	elif [[ $URL == https://www.youtube.com/playlist* ]]; then
		command+="--pList \"$URL\""
	elif [[ $URL == https://www.youtube.com/shorts* ]]; then
		command+=" --st \"$URL\""
	# elif [[ $URL == https://www.youtube.com/playlist* ]]; then #   ,,,,,,
	# 	command+="--pList \"$URL\""
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

yt  "$@"
echo "Done"
