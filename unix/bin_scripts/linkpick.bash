#!/usr/bin/env bash
set -euo pipefail

OPEN=true
USE_PRIVATE=false
URL_FILES=()

# Default browser (Firefox)
BROWSER=(firefox)
PRIVATE_FLAG=(--private-window)

# ---- option parsing ----
while [[ $# -gt 0 ]]; do
	case "$1" in
	-o | --open)
		OPEN=true
		shift
		;;
	-NO | --no-open)
		OPEN=false
		shift
		;;
	-P | --private)
		USE_PRIVATE=true
		shift
		;;
	-S | --safari)
		BROWSER=(safari)
		PRIVATE_FLAG=(-private)  # Safari private mode is tricky via CLI
		# https://apple.stackexchange.com/questions/416297/open-an-url-in-safari-with-private-browsing
		OPEN=true
		shift
		;;
	-T | --tor)
		BROWSER=("/Applications/Tor Browser.app/Contents/MacOS/Tor/tor")
		PRIVATE_FLAG=(--private-window)
		OPEN=true
		shift
		;;
	-C | --chrome)
		BROWSER=(google-chrome)
		PRIVATE_FLAG=(--incognito)
		shift
		;;
	-F | --firefox)
		BROWSER=(firefox)
		PRIVATE_FLAG=(--private-window)
		shift
		;;
	-H | -h | --help)
		echo "Usage: linkpick [options] <file> [file...]"
		echo
		echo "Options:"
		echo "  -o, --open        Open selected URL"
		echo " -NO, --no-open     Not to open selected URL"
		echo "  -P, --private     Open in private/incognito mode"
		echo "  -C, --chrome      Use Google Chrome"
		echo "  -T, --tor         Use Tor browser"
		echo "  -S, --safari      Use Safari (macOS only)"
		echo "  -F, --firefox     Use Firefox"
		echo "  -h, --help        Show this help"
		exit 0
		;;
	-*)
		echo "Unknown option: $1"
		exit 1
		;;
	*)
		URL_FILES+=("$(realpath -- "$1")")
		shift
		;;
	esac
done

# ---- validate input ----
if [[ ${#URL_FILES[@]} -eq 0 ]]; then
	echo "Usage: linkpick [options] <file> [file...]"
	exit 1
fi

# ---- extract + select URL ----
URL="$(
	cat "${URL_FILES[@]}" |
	grep -E 'https?://' |
	fzf --prompt="Select link: " |
	grep -o 'https\?://\S\+'
)"

# ---- handle empty selection ----
if [[ -z "${URL:-}" ]]; then
	echo "No URL selected."
	exit 1
fi


# ---- open if requested ----
if [[ "$OPEN" == true ]]; then
	if [[ "$USE_PRIVATE" == true ]]; then
		echo "${BROWSER[@]}" "${PRIVATE_FLAG[@]}" "$URL"
		"${BROWSER[@]}" "${PRIVATE_FLAG[@]}" "$URL"
	else
		echo "${BROWSER[@]}" "$URL"
		"${BROWSER[@]}" "$URL"
	fi
else
	echo "$URL"
fi
