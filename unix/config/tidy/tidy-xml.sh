#!/bin/sh

CONFIG="$HOME/.config/tidy/tidyrc-xml"

"$HOME/.local/bin/tidy" \
	-config "$CONFIG" \
	-xml \
	-i \
	"$@" 2>/dev/null | sed 's/    /\t/g'

exit 0
