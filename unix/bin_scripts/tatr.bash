#!/usr/bin/env bash
set -euo pipefail

# https://www.youtube.com/watch?v=8NdRGmp70Go&t=1729s

# ---------- Input ----------
if [[ $# -lt 1 ]]; then
	echo 'Usage: run <file> [args...]'
	echo 'args:  [--pwd|--time]'
	exit 1
fi

# ---------- Flags ----------
TIME_MODE=0
COMPILE_ONLY=0
WORKING_DIR=0
NEW_ARGS=()

for arg in "$@"; do
	case "$arg" in
	--time)
		TIME_MODE=1
		;;
	--pwd)
		WORKING_DIR=1
		;;
	--help)
		echo 'Usage: run <file> [arguments...] [options]'
		echo
		echo 'Options:'
		echo '  --time    Show execution time, CPU usage, and memory usage'
		echo '  --pwd     In compile mode, place the output binary in the current directory ($PWD)'
		echo '  --help    Show this help message'
		exit 0
		;;
	*)
		NEW_ARGS+=("$arg")
		;;
	esac
done
