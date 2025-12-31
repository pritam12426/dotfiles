#!/bin/bash

function install_github_scrpits() {
	local link="$1"
	local output_file="$2"
	local mess="$3"

	echo "📥 Downloading && installing $mess ..."
	curl -fsSL "$link" \
	-o "$output_file" \
	&& chmod +x "$output_file"
	echo -e "👍 Done installing \"$mess\" \n"
}

install_github_scrpits \
	"https://raw.githubusercontent.com/mac-cleanup/mac-cleanup-sh/refs/heads/main/mac-cleanup" \
	"$HOME/.local/bin/mac-cleanup" \
	"mac-cleanup"

install_github_scrpits \
	"https://raw.githubusercontent.com/peterkaminski/obsidian-settings-manager/main/osm.py" \
	"$HOME/.local/bin/osm" \
	"Obsidian Settings Manager (osm)"
