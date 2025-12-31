#!/bin/bash

"$HOME/.local/bin/tidy" \
	-config "$HOME/.config/tidy/tidyrc-html"
	"$@" 2>/dev/null

exit 0
