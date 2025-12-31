#!/bin/sh

printf "================ GET THUMBNAIL ================\n"
URL="$1"
file="/private/tmp/newsboat/thumbnail"
yt-dlp --write-thumbnail --skip-download --no-write-subs --no-write-auto-subs --no-write-description --no-write-info-json --convert-thumbnails jpg -o "$file" "$URL"
qlmanage -p -- "$file.jpg"
