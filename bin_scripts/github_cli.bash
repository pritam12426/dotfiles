#!/bin/bash

case "$@" in
"init")
	GIT_DIR="$(git rev-parse --git-dir)"

	if [[ ! -d $GIT_DIR ]]; then
		echo "❌ Not a git repository. Run: git init"
		exit 1
	fi

	GIT_DIR

	echo "📦 Public or Private? [ p/P=public 🔒 ] or [ any key=private 🛜 ]"
	read -r choice
	privacy="--private"
	if [[ $choice =~ ^[pP]$ ]]; then
		privacy="--public"
	fi

	echo "📝 Enter repository description (or leave empty):"
	read -r description
	desc_flag=""
	if [[ -n $description ]]; then
		desc_flag="--description=$description "
	fi

	echo "Making a new repo to github "
	repo_name=$(basename "$")
	command gh repo create "$repo_name" "$desc_flag" "$privacy" --source . --remote=origin --push --disable-wiki --disable-issues
	echo "🚀 Done! Linked and pushed to GitHub."

	;;
"info")
	command gh repo view "$(pbpaste)" --json name,description,stargazerCount
	exit $?
	;;
"--help")
	command gh --help
	echo "User define options"
	echo "  --export-cookies or -E  export the saved cookies of firefox to ~/.cache/firefox_cookies.txt"
	echo "  --clean or -C           Open the Browser Console."

	exit 0
	;;
esac

command gh "$@"
