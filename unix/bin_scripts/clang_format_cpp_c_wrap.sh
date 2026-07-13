#!/bin/sh

set -eu

: "${DOT_FILE:?DOT_FILE is not set}"

CLANG_FORMAT_FILE="$DOT_FILE/../global/c-cpp-template/common_template/clang-format.yml"

if [ -f ".clang-format" ]; then
	exec clang-format "$@"
else
	exec clang-format --style=file:"$CLANG_FORMAT_FILE" "$@"
fi
