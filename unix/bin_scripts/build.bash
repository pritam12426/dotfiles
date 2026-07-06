#!/bin/bash
# file: ~/.local/bin/build

set -e

run_build() {
	if [[ -f build.ninja ]]; then
		command ninja "$@"
		exit $?
	fi

	if [[ -f Makefile ]]; then
		command make "$@"
		exit $?
	fi
}

# Try current directory first
run_build "$@"

# If in git repo use it
PROJ_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -z $PROJ_ROOT ]] && cd "$PROJ_ROOT"

# Try common build dirs
build_dirs=(
	"build-arm64"
	"build"
	"../build/"
)

for dir in "${build_dirs[@]}"; do
	if [[ -d $dir ]]; then
		cd "$dir" || exit 1
		echo "[Bulding dir 📁]: '$PWD/$dir'"
		run_build "$@"
	fi
done
