#!/bin/bash

# file: ~/.local/bin/notify.sh
# description: a simple prescription for getting notifications on macOS

quiet=false

# ---- option parsing ----
while [[ $# -gt 0 ]]; do
	case "$1" in
	-q | --quiet)
		quiet=true
		shift
		;;
	--help)
		echo "Usage: notify [-q|--quiet] <message> [title] [type]"
		echo "  <message>: The notification message to display."
		echo "  [title]:   Optional. Default: Notification"
		echo "  [type]:    info | error | log"
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		echo "Unknown option: $1"
		exit 1
		;;
	*)
		break
		;;
	esac
done

# ---- positional args ----
msg="$1"; shift || true
title="${1:-Notification}";  shift || true
type="${1:-info}"

# ---- sound mapping ----
case "$type" in
	error) sound="Basso" ;;
	log)   sound="Pop" ;;
	*)     sound="default" ;;
esac

# ---- escape for AppleScript ----
msg=${msg//\\/\\\\};     msg=${msg//\"/\\\"}
title=${title//\\/\\\\}; title=${title//\"/\\\"}

# ---- notify ----
if ! $quiet; then
	# escape quotes to avoid AppleScript breakage
	osascript -e "display notification \"$msg\" with title \"$title\" sound name \"$sound\"" > /dev/null 2>&1
else
	osascript -e "display notification \"$msg\" with title \"$title\""
fi
