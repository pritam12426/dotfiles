#!/bin/bash
# description: macOS alert / dialog engine using pure AppleScript

confirm=false
prompt=false
password=false

# ---- option parsing ----
while [[ $# -gt 0 ]]; do
	case "$1" in
		-c|--confirm)   confirm=true; shift ;;
		-p|--prompt)    prompt=true; shift ;;
		--password)     password=true; shift ;;
		--help)
			echo "Usage: message [options] <message> [title] [type]"
			echo
			echo "Options:"
			echo "  -c, --confirm      Show OK / Cancel dialog (exit 1 on Cancel)"
			echo "  -p, --prompt       Ask for input"
			echo "  --password         Ask for hidden input"
			echo
			echo "Types:"
			echo "  info (default), warning, error"
			exit 0 ;;
		--) shift; break ;;
		-*) echo "Unknown option: $1"; exit 1 ;;
		*) break ;;
	esac
done

msg="$1"; shift
title="${1:-Notification}"; shift || true
type="${1:-info}"

# ---- escape ----
msg=${msg//\\/\\\\}; msg=${msg//\"/\\\"}
title=${title//\\/\\\\}; title=${title//\"/\\\"}

# ---- alert level ----
case "$type" in
	error)   level="critical";  beep=2; exitcode=2 ;;
	warning) level="warning";   beep=1; exitcode=1 ;;
	*)       level="informational"; beep=0; exitcode=0 ;;
esac

# ---- clipboard ----
osascript -e "set the clipboard to \"$msg\"" >/dev/null 2>&1

# ---- beep ----
((beep>0)) && osascript -e "beep $beep" >/dev/null 2>&1

# ---- prompt modes ----
if $password; then
	res=$(osascript -e "display dialog \"$msg\" default answer \"\" with hidden answer")
	echo "$res"
	exit 0
elif $prompt; then
	res=$(osascript -e "display dialog \"$msg\" default answer \"\"")
	echo "$res"
	exit 0
elif $confirm; then
	out=$(osascript -e "display alert \"$title\" message \"$msg\" buttons {\"Cancel\",\"OK\"} default button \"OK\" cancel button \"Cancel\" as $level")
	[[ "$out" == *OK* ]] || exit 1
else
	osascript -e "display alert \"$title\" message \"$msg\" as $level" >/dev/null 2>&1
fi

exit $exitcode
