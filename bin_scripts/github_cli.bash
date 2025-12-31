#!/bin/bash

# Check if GitHub CLI is installed
if ! type gh &> /dev/null; then
	echo "❌ Error: 'gh' CLI is not installed."
	exit 1
fi

case "$1" in
"init")
	# Get the root directory of the git project
	# This works even if you are in a subdirectory
	PROJ_ROOT=$(git rev-parse --show-toplevel 2> /dev/null)

	if [[ -z $PROJ_ROOT ]]; then
		echo "❌ fatal: not a git repository (or any of the parent directories): .git"
		exit 1
	fi

	# Get the name of the root directory for the repo name
	REPO_NAME=$(basename "$PROJ_ROOT")

	echo "📦 Public or Private? [ p/P=public 🔓 ] or [ Enter=private 🛜 ]"
	read -r choice
	privacy="--private"
	[[ $choice =~ ^[pP]$ ]] && privacy="--public"

	echo "📝 Enter repository description (or leave empty):"
	read -r description

	# Construct arguments array to avoid empty string issues
	GH_ARGS=("$REPO_NAME" "$privacy" "--source=$PROJ_ROOT" "--remote=origin" "--push" "--disable-wiki" "--disable-issues")

	# Only add description flag if it's not empty
	if [[ -n $description ]]; then
		GH_ARGS+=("--description" "$description")
	fi

	echo "🚀 Creating $privacy repository: $REPO_NAME ..."

	# Check for commits
	if [ -z "$(git log -1 2> /dev/null)" ]; then
		echo "⚠️  Note: No commits found. GitHub requires at least one commit to initialize with --push."
	fi

	gh repo create "${GH_ARGS[@]}"

	echo "✅ Done! Repository created and linked."
	exit 0
	;;

"info")
	target=$(pbpaste)
	# Check if clipboard looks like a 'user/repo' or a URL
	if [[ -z $target || ! $target =~ "/" ]]; then
		echo "ℹ️  Showing info for current directory repo:"
		gh repo view --json name,description,stargazerCount,url
	else
		echo "ℹ️  Showing info for: $target"
		gh repo view "$target" --json name,description,stargazerCount,url
	fi
	exit 0
	;;

"--help")
	echo "Custom GH Wrapper"
	echo "-------------------"
	echo "Usage: $(basename "$0") [command]"
	echo ""
	echo "Commands:"
	echo "  init    - Create a GitHub repo from current project root and push"
	echo "  info    - View info for repo in clipboard (or current folder)"
	echo "  * - All other commands pass through to 'gh' CLI"
	exit 0
	;;

*)
	# exec gh "$@"
	;;
esac
