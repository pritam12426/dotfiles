#!/usr/bin/env bash

set -euo pipefail

MODE="all"
TARGET_DIR=""
DRY_RUN=false

usage() {
	cat <<EOF
dot-deploy - create symbolic links for files

Usage:
  dot-deploy [options] <target-directory>

Options:
  --bin            Link executable files only
  -n, --dry-run    Show what would happen
  -h, --help       Show this help

Examples:
  dot-deploy ~/.config
  dot-deploy --bin
  dot-deploy --bin ~/.local/bin
  dot-deploy --bin --dry-run
EOF
}

# ---- option parsing ----
while [[ $# -gt 0 ]]; do
	case "$1" in
	--bin)
		MODE="bin"
		shift
		;;
	-n|--dry-run)
		DRY_RUN=true
		shift
		;;
	-h|--help)
		usage
		exit 0
		;;
	*)
		TARGET_DIR="$1"
		shift
		;;
	esac
done

# ---- default target directory ----
if [[ -z "$TARGET_DIR" && "$MODE" == "bin" ]]; then
	TARGET_DIR="$HOME/.local/bin"
fi

if [[ -z "$TARGET_DIR" ]]; then
	echo "❌ Error: target directory not specified."
	exit 1
fi

# ---- dry run banner ----
if [[ "$DRY_RUN" == true ]]; then
	echo "🔍 DRY RUN MODE: no changes will be made."
fi

# ---- create target directory ----
if [[ "$DRY_RUN" == true ]]; then
	echo "[Dry] mkdir -p $TARGET_DIR"
else
	mkdir -p "$TARGET_DIR"
fi

# ---- find files ----
FIND_ARGS=(-maxdepth 1 -type f)

if [[ "$MODE" == "bin" ]]; then
	FIND_ARGS+=(-perm -111)
fi

find . "${FIND_ARGS[@]}" -not -name ".*" -print0 |
while IFS= read -r -d '' file; do
	filename=$(basename "$file")
	src_path=$(realpath "$file")
	link_path="$TARGET_DIR/$filename"

	[[ "$src_path" == "$link_path" ]] && continue

	if [[ "$DRY_RUN" == true ]]; then
		echo "[Dry] ln -sf \"$src_path\" \"$link_path\""
	else
		ln -sf "$src_path" "$link_path"
		echo "🔗 Linked: $filename -> $link_path"
	fi
done
