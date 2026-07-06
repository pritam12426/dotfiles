#!/usr/bin/env bash
set -euo pipefail
file_copied=()
privacy="--private"
description=""

# FORCE_MODE=false
# -----------------------------
# 🔍 Check Dependencies
# -----------------------------
if ! command -v gh > /dev/null 2>&1; then
	echo '❌ Error: "gh" CLI is not installed.'
	exit 1
fi

# -----------------------------
# 🚩 Flags
# -----------------------------
name_override=""
force_public=false
force_private=false
desc_flag=""
enable_issues=false
enable_wiki=false
open_browser=true     # default: open in browser after creation; --no-open disables
dry_run=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run | -N)
		dry_run=true; shift ;;
	--name | -n)
		[[ -z "${2:-}" ]] && { echo "Error: --name requires a value"; exit 1; }
		name_override="$2"; shift 2 ;;
	--public)
		force_public=true; shift ;;
	--private)
		force_private=true; shift ;;
	--description | --desc | -d)
		[[ -z "${2:-}" ]] && { echo "Error: --description requires a value"; exit 1; }
		desc_flag="$2"; shift 2 ;;
	--enable-issues)
		enable_issues=true; shift ;;
	--enable-wiki)
		enable_wiki=true; shift ;;
	--no-open)
		open_browser=false; shift ;;
	--help | -h)
		cat <<'EOF'
Usage: github-init [flags]

Flags:
  --name,        -n <name>   Override the repository name (default: directory name)
  --description, -d <text>   Set the repository description (skips prompt)
  --public                   Create as a public repository (skips prompt)
  --private                  Create as a private repository (skips prompt)
  --enable-issues            Enable GitHub Issues (disabled by default)
  --enable-wiki              Enable GitHub Wiki (disabled by default)
  --no-open                  Do not open the repository in the browser after creation
  --dry-run,     -N          Show every step and command without making any changes
  --help,        -h          Show this help message
EOF
		exit 0 ;;
	*)
		echo "Unknown option: $1"; exit 1 ;;
	esac
done

# --public and --private are mutually exclusive
if $force_public && $force_private; then
	echo "Error: --public and --private are mutually exclusive"; exit 1
fi

if $dry_run; then
	echo '⚡️ DRY-RUN MODE — no git commits, no GitHub repo will be created, no browser opened'
	echo ''
fi

# -----------------------------
# 📂 Detect or Initialize Repo
# -----------------------------

PROJ_ROOT=$(git rev-parse --show-toplevel 2> /dev/null || true)
if [[ -z $PROJ_ROOT ]]; then
	echo '📁 Not a git repository. Initializing...'
	if $dry_run; then
		echo '  [dry-run] git init'
		echo '  [dry-run] git config --local commit.gpgsign true'
		echo '  [dry-run] git config --local tag.gpgsign true'
		PROJ_ROOT="$PWD"
	else
		git init
		[[ -z "$(git config user.email || true)" ]] &&
			git config --local user.email '84720825+pritam12426@users.noreply.github.com'
		[[ -z "$(git config user.signingkey || true)" ]] &&
			git config --local user.signingkey '9D731EE58B357845'
		git config --local commit.gpgsign true
		git config --local tag.gpgsign true
		PROJ_ROOT=$(git rev-parse --show-toplevel)
	fi
fi

cd "$PROJ_ROOT" || exit 1

# -----------------------------
# 📦 Add Template Files (if missing)
# -----------------------------
# SCRIPT_DIR is the directory this script lives in, used to locate the template
# files relative to the script itself. Falls back to $DOT_FILE if set in the
# environment (legacy behaviour), so existing setups are not broken.

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TEMPLATE_DIR="${DOT_FILE:+$DOT_FILE/../global/c-cpp-template/common_template}"
TEMPLATE_DIR="${TEMPLATE_DIR:-$SCRIPT_DIR/../global/c-cpp-template/common_template}"
copy_if_missing() {
	if [[ ! -f "$1" && -f "$TEMPLATE_DIR/$1" ]]; then
		if $dry_run; then
			echo "  [dry-run] cp $TEMPLATE_DIR/$1 → ./$1"
		else
			cp -p "$TEMPLATE_DIR/$1" .
			echo "➡️  Copied $1"
		fi
		file_copied+=("$1")
	fi
}

copy_if_missing "README.md"
copy_if_missing "LICENSE"
copy_if_missing "REFERENCES.md"
copy_if_missing "TODO.txt"

if [ ! -f ".gitignore" ]; then
	if $dry_run; then
		echo "  [dry-run] create .gitignore"
	else
		echo "# /$(basename "$PROJ_ROOT")" > ".gitignore"
	fi
fi
if [ ! -f ".gitattributes" ]; then
	if $dry_run; then
		echo "  [dry-run] touch .gitattributes"
	else
		touch .gitattributes
	fi
fi

# -----------------------------
# 📝 Initial Commit (if needed)
# -----------------------------

if ! git rev-parse HEAD >/dev/null 2>&1; then
	echo '📌 No commits found. Creating initial commit...'
	if $dry_run; then
		echo '  [dry-run] git add --all'
		echo '  [dry-run] git commit -m "Initial commit"'
	else
		git add --all
		git commit -m 'Initial commit'
	fi
else
	if [[ ${#file_copied[@]} -gt 0 ]]; then
		echo '📦 Template files added. Creating commit...'
		if $dry_run; then
			echo "  [dry-run] git add ${file_copied[*]}"
			echo "  [dry-run] git commit -m \"Add missing template files: ${file_copied[*]}\""
		else
			git add "${file_copied[@]}"
			git commit -m "Add missing template files: ${file_copied[*]}"
		fi
	fi
fi

# -----------------------------
# 🏷 Repo Name & GitHub Username
# -----------------------------

GH_USERNAME="$(gh api user --jq .login)"
REPO_NAME=$(basename "$PROJ_ROOT")
# TODO: ask the user for the repo name or
[[ -n "$name_override" ]] && REPO_NAME="$name_override"

# -----------------------------
# 🚀 Remote Check
# -----------------------------

if gh repo view "${GH_USERNAME}/${REPO_NAME}" >/dev/null 2>&1; then
	echo "⚠️  Repository 'https://github.com/${GH_USERNAME}/${REPO_NAME}' already exists."
	echo ''
	echo 'Options:'
	echo '  1) Add it as the "origin" remote and push (default)'
	echo '  2) Abort'
	echo '  3) Delete existing repository and create a new one'
	printf 'Choice [1/2/3]: '
	read -r repo_choice
	if [[ "${repo_choice}" == "2" ]]; then
		echo 'Aborted.'
		exit 0
	fi
	if [[ "${repo_choice}" == "3" ]]; then
		printf '📝 Use a different repository name? (y/N): '
		read -r rename_repo
		if [[ "${rename_repo}" =~ ^[yY]$ ]]; then
			printf 'New name > '
			read -r REPO_NAME
		fi
		if $dry_run; then
			echo "  [dry-run] gh repo delete '${GH_USERNAME}/${REPO_NAME}' --yes"
			echo "  [dry-run] Would update .gitignore header to '# /${REPO_NAME}'"
		else
			gh repo delete "${GH_USERNAME}/${REPO_NAME}" --yes
			echo "🗑️  Deleted existing repository '${GH_USERNAME}/${REPO_NAME}'"
			if [[ -f ".gitignore" ]] && [[ "${rename_repo}" =~ ^[yY]$ ]]; then
				sed -i '' "1s|^# /.*|# /${REPO_NAME}|" .gitignore
			fi
		fi
	else
		# Default (option 1): add remote and push
		if $dry_run; then
			echo "  [dry-run] git remote add origin https://github.com/${GH_USERNAME}/${REPO_NAME}.git"
			echo "  [dry-run] git push -u origin <current-branch>"
			echo "✅ [dry-run] Would push to existing repository: 'https://github.com/${GH_USERNAME}/${REPO_NAME}'"
		else
			if ! git remote get-url origin >/dev/null 2>&1; then
				git remote add origin "https://github.com/${GH_USERNAME}/${REPO_NAME}.git"
				echo "🔗 Remote 'origin' added."
			else
				echo "🔗 Remote 'origin' already set: $(git remote get-url origin)"
			fi
			git push -u origin "$(git symbolic-ref --short HEAD)"
			echo "✅ Pushed to existing repository: 'https://github.com/${GH_USERNAME}/${REPO_NAME}'"
		fi
		exit 0
	fi
fi

# -----------------------------
# 🔐 Privacy Selection
# -----------------------------

if $force_public; then
	privacy="--public"
elif $force_private; then
	privacy="--private"
else
	printf '⚠️  Make this repository PUBLIC? (y/N): '
	read -r confirm
	[[ "$confirm" =~ ^[yY]$ ]] && privacy="--public"
fi

# -----------------------------
# 📝 Description
# -----------------------------

if [[ -n "$desc_flag" ]]; then
	description="$desc_flag"
else
	echo "📝 Enter repository description (or leave empty):"
	printf 'Desc > '
	read -r description
fi

# -----------------------------
# 🚀 Create GitHub Repo
# -----------------------------

GH_ARGS=(
	"$REPO_NAME"
	"$privacy"
	"--source=$PROJ_ROOT"
	'--push'
)

# Issues and Wiki are disabled by default; flags opt in.
$enable_issues || GH_ARGS+=('--disable-issues')
$enable_wiki   || GH_ARGS+=('--disable-wiki')

if [[ -n $description ]]; then
	GH_ARGS+=('--description' "$description")
fi
echo "🚀 Creating $privacy repository: $REPO_NAME ..."
if $dry_run; then
	echo "  [dry-run] gh repo create ${GH_ARGS[*]}"
else
	gh repo create "${GH_ARGS[@]}"
fi

# -----------------------------
# ✅ Done
# -----------------------------

echo ''
echo "✅ Repository $($dry_run && echo '[dry-run] would be' || echo '') created: 'https://github.com/${GH_USERNAME}/${REPO_NAME}'"
echo "📦 Name:        $REPO_NAME"
echo "🔐 Privacy:     $privacy"
echo "📝 Description: ${description:-<none>}"
echo "✈️  Remote:      origin"
echo "🗒️  Wiki:        $($enable_wiki   && echo 'enabled' || echo 'disabled')"
echo "😌 Issues:      $($enable_issues && echo 'enabled' || echo 'disabled')"
echo
echo "To delete the repository: gh repo delete '${GH_USERNAME}/${REPO_NAME}'"

if $open_browser && ! $dry_run; then
	echo ''
	echo '🌐 Opening in browser...'
	gh repo view "${GH_USERNAME}/${REPO_NAME}" --web
elif $dry_run; then
	echo '  [dry-run] gh repo view --web'
fi
