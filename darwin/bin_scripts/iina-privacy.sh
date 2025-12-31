#!/bin/bash -x

set -euo pipefail
IINA="/Applications/IINA.app/Contents/MacOS/iina-cli"

message() {
	local msg="$1"
	local title="${2:-Notification}"
	local type="${3:-info}"

	case "$type" in
	error)
		osascript -e "display alert \"$title\" message \"$msg\" as critical" 2&>/dev/null
		;;
	warning)
		osascript -e "display alert \"$title\" message \"$msg\" as warning" 2&>/dev/null
		;;
	info | *)
		osascript -e "display alert \"$title\" message \"$msg\" as informational" 2&>/dev/null
		;;
	esac
}

if [ ! -x "$IINA" ]; then
	message "iina-cli is not installed" "IINA-privacy" "error"
	exit 1
fi

IINA_HISTORY_FILE="$HOME/Library/Application Support/com.colliderli.iina/history.plist"
IINA_HISTORY_DIR="$HOME/Library/Application Support/com.colliderli.iina/watch_later"

TEMP_HISTORY_FILE="$TMPDIR/history.plist"
TEMP_HISTORY_DIR="$TMPDIR/watch_later"

cp -p   "$IINA_HISTORY_FILE" "$TEMP_HISTORY_FILE"
cp -rp  "$IINA_HISTORY_DIR"  "$TEMP_HISTORY_DIR"

"$IINA" --keep-running "$@"

sleep 2;

rm    "$IINA_HISTORY_FILE"
rm -r "$IINA_HISTORY_DIR"

cp -p   "$TEMP_HISTORY_FILE" "$IINA_HISTORY_FILE"
cp -rp  "$TEMP_HISTORY_DIR"  "$IINA_HISTORY_DIR"
