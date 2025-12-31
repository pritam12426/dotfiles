#!/bin/sh

[ "$#" -eq 0 ] && exit 1

url=$(curl -sIL -o /dev/null -w '%{url_effective}' "$1")

url=$(echo "${url}" | perl -p -e 's/(\?|\&)?utm_[a-z]+=[^\&]+//g;' -e 's/(#|\&)?utm_[a-z]+=[^\&]+//g;')

title="$2"
description="$3"

grep -q "${url}\t${title}\t${description}" ~/.config/newsboat/bookmarks_temp.txt || printf  "%s\t%s\t%s" "${url}" "${title}" "${description}" >> ~/.config/newsboat/bookmarks_temp.txt
