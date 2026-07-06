#!/bin/bash
# file: ~/.local/bin/message
# description: macOS alert / dialog engine using pure AppleScript

set -euo pipefail

# ── Shared escape helper ───────────────────────────────────────────────────────
# Same helper as notify — if both scripts live alongside a shared lib, source it.
# Escapes for safe embedding inside AppleScript double-quoted strings.
as_escape() {
	local s="$1"
	s="${s//\\/\\\\}"   # backslash → \\
	s="${s//\"/\\\"}"   # " → \"
	s="${s//\`/\\\`}"   # ` → \`
	s="${s//$/\\$}"     # $ → \$ (prevent shell expansion inside osascript -e)
	printf '%s' "$s"
}

# ── Help ───────────────────────────────────────────────────────────────────────
show_help() {
	cat <<HELP
Usage: message [options] <message> [title] [type]

Options:
  -c, --confirm          Show OK / Cancel dialog (exits 1 on Cancel)
  -p, --prompt           Ask for text input; prints result to stdout
  --password, --pass     Ask for hidden input; prints result to stdout
  --timeout <n>          Auto-dismiss after N seconds (info/warning only)
  --icon <path>          Custom icon file (.icns or .png) for the dialog
  --help                 Show this help

Arguments:
  <message>   The dialog body (required)
  [title]     Dialog title (default: Notification)
  [type]      info | warning | error (default: info)

Exit codes:
  0   OK / accepted
  1   Cancel pressed
  2   Error type alert shown

Examples:
  message "Deployment complete"
  message --confirm "Delete all files?" "Warning" warning
  message --prompt "Enter your name:"
  message --password "Enter API key:"
  message --timeout 5 "Done!" "Build" info
HELP
}

# ── Defaults ───────────────────────────────────────────────────────────────────
confirm=false
prompt=false
password=false
timeout=0        # 0 = no timeout
icon=""

# ── Option parsing ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
	case "$1" in
	-c|--confirm)
		confirm=true; shift ;;
	-p|--prompt)
		prompt=true; shift ;;
	--password|--pass)
		password=true; shift ;;
	--timeout)
		[[ -z "${2:-}" ]] && { echo "message: --timeout requires a number" >&2; exit 1; }
		timeout="$2"; shift 2 ;;
	--icon)
		[[ -z "${2:-}" ]] && { echo "message: --icon requires a path" >&2; exit 1; }
		icon="$2"; shift 2 ;;
	--help)
		show_help; exit 0 ;;
	--)
		shift; break ;;
	-*)
		echo "message: unknown option: $1" >&2
		echo "Try 'message --help'" >&2
		exit 1 ;;
	*)
		break ;;
	esac
done

# ── Positional args ────────────────────────────────────────────────────────────
msg="${1:-}"
if [[ -z "$msg" ]]; then
	echo "message: message is required" >&2
	echo "Try 'message --help'" >&2
	exit 1
fi
shift || true

title="${1:-Notification}"; shift || true
type="${1:-info}"

# ── Alert level mapping ────────────────────────────────────────────────────────
case "$type" in
	error)   level="critical";      beep=1; exitcode=2 ;;
	warning) level="warning";       beep=1; exitcode=1 ;;
	*)       level="informational"; beep=0; exitcode=0 ;;
esac

# ── Escape all user strings ────────────────────────────────────────────────────
msg="$(as_escape "$msg")"
title="$(as_escape "$title")"

# ── Optional clauses ───────────────────────────────────────────────────────────
timeout_clause=""
(( timeout > 0 )) && timeout_clause=" giving up after $timeout"

icon_clause=""
if [[ -n "$icon" && -f "$icon" ]]; then
	icon_escaped="$(as_escape "$icon")"
	icon_clause=" with icon POSIX file \"$icon_escaped\""
fi

# ── Beep ───────────────────────────────────────────────────────────────────────
(( beep > 0 )) && osascript -e "beep $beep" >/dev/null 2>&1

# ── Prompt modes ──────────────────────────────────────────────────────────────
if $password; then
	# Run dialog; osascript exits non-zero on Cancel
	raw=$(osascript -e "display dialog \"$msg\" default answer \"\" with hidden answer${timeout_clause}" 2>&1) || {
		exit 1   # user hit Cancel
	}
	# Extract just the text — strip "button returned:OK, text returned:"
	printf '%s\n' "${raw##*text returned:}"
	exit 0

elif $prompt; then
	raw=$(osascript -e "display dialog \"$msg\" default answer \"\"${timeout_clause}" 2>&1) || {
		exit 1   # user hit Cancel
	}
	printf '%s\n' "${raw##*text returned:}"
	exit 0

elif $confirm; then
	# osascript throws error 1 on Cancel when cancel button is set
	out=$(osascript -e \
		"display alert \"$title\" message \"$msg\" buttons {\"Cancel\",\"OK\"} \
		default button \"OK\" cancel button \"Cancel\" as $level${timeout_clause}${icon_clause}" \
		2>&1) || exit 1
	[[ "$out" == *"OK"* ]] || exit 1

else
	# Plain alert — no user input needed
	osascript -e \
		"display alert \"$title\" message \"$msg\" as $level${timeout_clause}${icon_clause}" \
		>/dev/null 2>&1
fi

exit $exitcode
