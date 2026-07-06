#!/bin/bash
# file: ~/.local/bin/notify
# description: macOS notification banner via osascript

set -euo pipefail

# ── Shared escape helper ───────────────────────────────────────────────────────
# Escapes a string for safe embedding inside AppleScript double-quoted strings.
# Handles: backslashes, double-quotes, backticks, dollar signs.
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
Usage: notify [options] <message> [title] [type]

Options:
  -q, --quiet           Suppress sound
  -s, --subtitle <sub>  Add a subtitle line
  --help                Show this help

Arguments:
  <message>   The notification body (required)
  [title]     Notification title (default: Notification)
  [type]      info | error | log (default: info)

Sound mapping:
  info  → Glass
  error → Basso
  log   → Pop

Examples:
  notify "Build complete"
  notify -q "Deploying..." "CI" info
  notify --subtitle "3 failures" "Tests done" "Jest" error
HELP
}

# ── Defaults ───────────────────────────────────────────────────────────────────
quiet=false
subtitle=""

# ── Option parsing ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
	case "$1" in
	-q|--quiet)
		quiet=true
		shift
		;;
	-s|--subtitle)
		[[ -z "${2:-}" ]] && { echo "notify: --subtitle requires a value" >&2; exit 1; }
		subtitle="$2"
		shift 2
		;;
	--help)
		show_help
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		echo "notify: unknown option: $1" >&2
		echo "Try 'notify --help'" >&2
		exit 1
		;;
	*)
		break
		;;
	esac
done

# ── Positional args ────────────────────────────────────────────────────────────
msg="${1:-}"
if [[ -z "$msg" ]]; then
	echo "notify: message is required" >&2
	echo "Try 'notify --help'" >&2
	exit 1
fi
shift || true

title="${1:-Notification}"; shift || true
type="${1:-info}"

# ── Sound mapping ──────────────────────────────────────────────────────────────
# Uses real macOS sound names — "default" is not a valid sound name
case "$type" in
	error) sound="Basso"   ;;
	log)   sound="Pop"     ;;
	*)     sound="default" ;;
esac

# ── Escape all user strings ────────────────────────────────────────────────────
msg="$(as_escape "$msg")"
title="$(as_escape "$title")"
subtitle="$(as_escape "$subtitle")"

# ── Build AppleScript ──────────────────────────────────────────────────────────
# Subtitle is an optional clause — only added when non-empty
subtitle_clause=""
[[ -n "$subtitle" ]] && subtitle_clause=" subtitle \"$subtitle\""

sound_clause=""
$quiet || sound_clause=" sound name \"$sound\""

osascript -e "display notification \"$msg\" with title \"$title\"${subtitle_clause}${sound_clause}" \
	>/dev/null 2>&1
