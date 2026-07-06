#!/bin/sh

install_github_scrpits() {
	link="$1"
	output_file="$2"
	mess="$3"

	echo "📥 Downloading && installing $mess ..."
	curl -fsSL "$link" \
		-o "$output_file" \
			&& chmod +x "$output_file"

	printf "👍 Done installing \"%s\"\n\n" "$mess"
}

install_github_scrpits \
	"https://raw.githubusercontent.com/peterkaminski/obsidian-settings-manager/main/osm.py" \
	"$HOME/.local/bin/osm" \
	"Obsidian Settings Manager (osm)"


install_github_scrpits \
	"https://github.com/so-fancy/diff-so-fancy/releases/latest/download/diff-so-fancy" \
	"$HOME/.local/bin/diff-so-fancy" \
	"diff-so-fancy A good git diff"


install_github_scrpits \
	"https://raw.githubusercontent.com/paulirish/git-open/refs/heads/master/git-open" \
	"$HOME/.local/bin/git-open" \
	"Type 'git open' to open the GitHub"
