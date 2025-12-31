#!/bin/bash

set -euo pipefail

REPO="aristocratos/btop"
PATH="themes"
OUTPUT_DIR="$HOME/.config/btop/themes"
mkdir -p "$OUTPUT_DIR/themes"
local contents=$(curl -s "https://api.github.com/repos/$REPO/contents/$dir_path")

# Function to download a directory recursively
download_dir() {
	local dir_path="${1:-$PATH}"
	local local_dir="${2:-$OUTPUT_DIR}"

	# Create local dir if needed

	# Fetch contents via API

	# Loop through items
	echo "$contents" | jq -r '.[] | @base64' | while read item; do
		local info=$(echo "$item" | base64 --decode)
		local name=$(echo "$info" | jq -r '.name')
		local type=$(echo "$info" | jq -r '.type')
		local subpath="$dir_path/$name"
		local sublocal="$local_dir/$name"

		if [ "$type" = "file" ]; then
			echo "Downloading file: $subpath"
			curl -s -L -o "$sublocal" "$(echo "$info" | jq -r '.download_url')"
		elif [ "$type" = "dir" ]; then
			echo "Entering subdir: $subpath"
			download_dir "$subpath" "$sublocal"
		fi
	done
}

# Start download
# download_dir
# echo "Download complete! Check the '$OUTPUT_DIR' folder."
# exit 0

download_and_log() {
	echo -e "\033[1;36m==> \033[1;33m $command\033[1;36m <==\033[0m"
	# Download
	if ! eval "$command"; then
		echo -e "\033[1;31mFailed $command\033[0m"
		continue
	fi
	printf '%*s\n' $(tput cols) '' | tr ' ' '-' >&2
}

downloadAndCommand=(
	"wget -q --show-progress '' "
);

for command in "${downloadAndCommand[@]}"; do
	download_and_log "$command"
done
