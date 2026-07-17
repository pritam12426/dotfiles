#!/bin/bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghstar"
API_CACHE_FILE="$CACHE_DIR/stars.txt"
mkdir -p "$CACHE_DIR"

# ---------- Flags ----------
FETCH_API=0
NEW_ARGS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	--fetch | update)
		FETCH_API=1
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
	echo "Unknown operating system: $OSTYPE"
	exit 1
	;;
esac

if [[ ! -f "$API_CACHE_FILE" ]]; then
	FETCH_API=1
fi

if [[ $FETCH_API -eq 1 ]]; then
	echo "❯ gh api user/starred" >&2
	gh api --paginate user/starred \
		--jq '.[] | "\(.name) | \(.description // "") | \(.full_name) | \(.html_url)"' > "$API_CACHE_FILE"
	echo "❯ bookmarkfmt \$API_CACHE_FILE" >&2
	# bookmarkfmt "$API_CACHE_FILE"
fi

url=$(sk --case=smart --reverse < "$API_CACHE_FILE" | awk -F' \\| ' '{print $4}')
[[ -n "$url" ]] && "${DEFAULT_OPENER[@]}" "$url"
