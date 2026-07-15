#!/bin/bash

set -euo pipefail

# ---------------------------------------------------------------------------
# clanginit — scaffold a new project from templates under $DOT_FILE/../global
# Portable: avoids bash 4+ associative arrays (macOS ships bash 3.2).
# ---------------------------------------------------------------------------

usage() {
	echo "Usage: clanginit [--dry-run] <c|c-min|cxx|c++|wx|ard|typ> <project-name>"
	exit 1
}

dry_run=false
args=()
for a in "$@"; do
	case "$a" in
		--dry-run|-n) dry_run=true ;;
		*)            args+=("$a") ;;
	esac
done
set -- "${args[@]}"

[ "$#" -lt 2 ] && usage

[ -z "${DOT_FILE:-}" ] && {
	echo "DOT_FILE not set"
	exit 1
}

TEMPLATE_DIR="$DOT_FILE/../global"
[ -d "$TEMPLATE_DIR" ] || {
	echo "TEMPLATE_DIR not found: $TEMPLATE_DIR"
	exit 1
}

TYPE_INPUT="$1"
# sanitize project name: strip any path components, keep just the leaf name
PROJECT="$(basename -- "$2")"

lower_input=$(echo "$TYPE_INPUT" | tr '[:upper:]' '[:lower:]')

# ---------------------------------------------------------------------------
# copy_if_missing SRC_REL DEST
#   SRC_REL is relative to $TEMPLATE_DIR
#   DEST is the destination path (file or directory)
#   Skips silently if DEST already exists. Respects $dry_run.
# ---------------------------------------------------------------------------
copy_if_missing() {
	local src="$TEMPLATE_DIR/$1"
	local dest="$2"

	if [ ! -e "$src" ]; then
		echo "⚠️  Missing template: $src"
		return 0
	fi
	if [ -e "$dest" ]; then
		echo "⏭️  Skipped (exists): $dest"
		return 0
	fi

	if $dry_run; then
		echo "  [dry-run] cp -rp $src → $dest"
	else
		mkdir -p "$(dirname -- "$dest")"
		cp -rp "$src" "$dest"
		echo "➡️  Copied $dest"
	fi
}

# ---------------------------------------------------------------------------
# 1. Base template for the chosen project type (case-based lookup —
#    portable replacement for an associative array)
# ---------------------------------------------------------------------------
base_template_for() {
	case "$1" in
		c)          echo "c-cpp-template/c" ;;
		c-min)      echo "c-cpp-template/c_min_with_make" ;;
		cxx | c++)  echo "c-cpp-template/c++" ;;
		wx)         echo "c-cpp-template/wx-form-template" ;;
		ard)        echo "embedded/arduino-cli-uno" ;;
		typ)        echo "typst" ;;
		*)          return 1 ;;
	esac
}

BASE_REL="$(base_template_for "$lower_input")" || {
	echo "Unsupported type '$TYPE_INPUT'. Supported: c c-min cxx c++ wx ard typ"
	exit 1
}

if [ -e "$PROJECT" ]; then
	echo "❌ '$PROJECT' already exists — refusing to overwrite the project root."
	exit 1
fi

copy_if_missing "$BASE_REL" "$PROJECT"

case "$lower_input" in
	ard)
		$dry_run || mv "$PROJECT/arduino-cli-uno.ino" "$PROJECT/$PROJECT.ino"
		;;
	typ)
		$dry_run || mkdir -pv "$PROJECT/assets"
		;;
esac

# ---------------------------------------------------------------------------
# 2. C/C++-family extras (build config, editor config, clangd, etc.)
#    Plain indexed array of "src|dest" pairs — portable across bash versions.
# ---------------------------------------------------------------------------
case "$lower_input" in
	c | cxx | c++ | wx)
		cpp_extras=(
			"c-cpp-template/common_template/src/CmakeConfig.h.in|$PROJECT/src/CmakeConfig.h.in"
			"c-cpp-template/common_template/zed|$PROJECT/.zed"
			"c-cpp-template/common_template/CMakePresets.json|$PROJECT/CMakePresets.json"
			"c-cpp-template/common_template/clangd.yml|$PROJECT/.clangd"
		)
		for pair in "${cpp_extras[@]}"; do
			copy_if_missing "${pair%%|*}" "${pair##*|}"
		done
		;;
esac

# ---------------------------------------------------------------------------
# 3. Common files, for every project type
# ---------------------------------------------------------------------------
printf "\nCommon project boiler code files:\n"
common_files=(
	"c-cpp-template/common_template/TODO.txt|$PROJECT/TODO.txt"
	"c-cpp-template/common_template/REFERENCES.md|$PROJECT/REFERENCES.md"
	"c-cpp-template/common_template/clang-tidy.yml|$PROJECT/.clang-tidy"
	"c-cpp-template/common_template/gitattributes|$PROJECT/.gitattributes"
	"c-cpp-template/common_template/editorconfig|$PROJECT/.editorconfig"
	"c-cpp-template/common_template/gitignore|$PROJECT/.gitignore"
	"c-cpp-template/common_template/README.md|$PROJECT/README.md"
)
for pair in "${common_files[@]}"; do
	copy_if_missing "${pair%%|*}" "${pair##*|}"
done

# ---------------------------------------------------------------------------
# 4. Optional doxygen setup
# ---------------------------------------------------------------------------
case "$lower_input" in
	c | cxx | c++ | wx)
		printf "Do you want to have doxygen in this project '%s' ?  (y/n): " "$PROJECT"
		read -r REPLY
		case "$REPLY" in
			[Yy]*)
				copy_if_missing "c-cpp-template/common_template/doc" "$PROJECT/doc"
				if ! $dry_run && [ -f "$PROJECT/CMakeLists.txt" ] && [ -f "$PROJECT/doc/patch.txt" ]; then
					cat "$PROJECT/doc/patch.txt" >> "$PROJECT/CMakeLists.txt"
					rm -f "$PROJECT/doc/patch.txt"
				fi
				;;
		esac
		;;
esac
