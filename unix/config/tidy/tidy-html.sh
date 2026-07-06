#!/bin/sh

CONFIG="$HOME/.config/tidy/tidyrc-html"

exec "$HOME/.local/bin/tidy" \
	-config "$CONFIG" \
	-i \
	"$@" 2> /dev/null | sed 's/    /\t/g'; exit 0
