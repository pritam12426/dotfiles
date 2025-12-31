#!/bin/bash

"$HOME/.local/bin/tidy" \
	-config "$HOME/.config/tidy/tidyrc-xml"
	"$@" 2>/dev/null

exit 0
