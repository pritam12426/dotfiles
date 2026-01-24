#!/bin/sh

[ "$#" -eq 0 ] && exit 1

url=$(curl -sIL -o /dev/null -w '%{url_effective}' "$1")

url=$(echo "${url}" | perl -p -e 's/(\?|\&)?utm_[a-z]+=[^\&]+//g;' -e 's/(#|\&)?utm_[a-z]+=[^\&]+//g;')
title="$2"
description="$3"

LINE=$(printf "%s\t%s\t%s" "${url}" "${title}" "${description}")
bookMark_file="$HOME/.local/share/newsboat/bookmarks.txt"

grep -q "$LINE" "$bookMark_file" || echo "$LINE" >> "$bookMark_file"
