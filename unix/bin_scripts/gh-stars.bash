#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghstar"
API_CACHE_FILE="$CACHE_DIR/stars.txt"
API_CACHE_WITH_LANGUAGE="$CACHE_DIR/stars_language.txt"

# mkdir -p "$CACHE_DIR"

# ---------- Flags ----------
FETCH_API=0
MODE_LANGUAGE=0
NEW_ARGS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	--fetch | update)
		FETCH_API=1
		;;
	--language | lang)
		MODE_LANGUAGE=1
		;;
	find)
		shift
		grep --color=auto -i < "$API_CACHE_FILE" "$@"
		exit $!
		;;
	*)
		NEW_ARGS+=("$1")
		;;
	esac
	shift
done

case "$OSTYPE" in
linux*)
	DEFAULT_OPENER=(xdg-open)
	;;
darwin*)
	DEFAULT_OPENER=(open)
	;;
*)
	echo "❯ Unknown operating system: $OSTYPE" >&2
	DEFAULT_OPENER=(echo)
	exit 1
	;;
esac

if [[ ! -f "$API_CACHE_FILE" ]]; then
	FETCH_API=1
fi

if [[ ! -f "$API_CACHE_WITH_LANGUAGE" ]]; then
	FETCH_API=1
fi

if [[ $FETCH_API -eq 1 ]]; then
	echo "❯ gh api user/starred" >&2

	gh api --paginate user/starred \
		--jq '.[] | "\(.full_name) | \(.description // "")"' > "$API_CACHE_FILE"
	bookmarkfmt "$API_CACHE_FILE"

	gh api --paginate user/starred \
		--jq '.[] | "\(.full_name) | \(.language) | \(.description // "")"' > "$API_CACHE_WITH_LANGUAGE"
	bookmarkfmt "$API_CACHE_WITH_LANGUAGE"
fi

if [[ $MODE_LANGUAGE -eq 1 ]]; then
	FULL_NAME=$(sk --case=smart --reverse < "$API_CACHE_WITH_LANGUAGE" | awk -F' | ' '{print $1}')
else
	FULL_NAME=$(sk --case=smart --reverse < "$API_CACHE_FILE" | awk -F' | ' '{print $1}')
fi

[[ -n "$FULL_NAME" ]] && "${DEFAULT_OPENER[@]}" "https://github.com/$FULL_NAME"
