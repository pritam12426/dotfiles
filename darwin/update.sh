#!/bin/sh

line() {
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '='
}

cd "$DOT_FILE" || exit

printf "Static text file update .... \n"
python3 hooks/packageDataBackup.py
line

printf "Static text file update .... \n"
python3 hooks/binUrlBackup.py
line


printf "Static setting update .... \n"
python3 hooks/dotmason/dotmason.py
line

printf "🍺 brew bundleing .... \n"
brew bundle dump --force --formula --cask --tap --mas --file "${XDG_CONFIG_HOME}/homebrew/Brewfile"
sed -i '' 's/# /\n# /' "${XDG_CONFIG_HOME}/homebrew/Brewfile"
line

git --no-pager diff --stat
line
