#!/bin/sh

PARENT_PID="$PPID"
PARENT_NAME="$(ps -p "$PARENT_PID" -o comm=)"

echo "Editing file: '$1' ..." >&2
echo "Parent ('$PARENT_NAME') pid=($PARENT_PID)" >&2
echo "Waiting for Zed to close the file..." >&2

zed --wait "$@"
