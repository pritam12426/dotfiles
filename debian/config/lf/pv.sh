#!/bin/sh

file_type=$(file --mime-type -b "$1")

case "$1" in
	*.tar*)
		tar tf "$1"
	;;
	*.zip)
		unzip -l "$1"
	;;
	image/*)
		chafa -f sixel -s "$2x$3" --animate off --polite on "$1"
		;;
	*.rar)
		unrar l "$1"
	;;
	*.7z)
		7z l "$1"
	;;
	*.json)
		bat \
		--paging=never \
		--style=numbers \
		--wrap=never \
		-f "$1" || true
	;;
	*)
		if [ "${file_type%%/*}" = "text" ]; then
			# bat --paging=never --style=numbers --wrap=never -f "$1" || true
			bat \
			--paging=never \
			--wrap=never \
			-f "$1" || true
	else
			exiftool \
			-FileSize \
			-Comment \
			-FileType \
			-CreateDate \
			-ModifyDate \
			-TimeScale \
			-Duration \
			-TrackCreateDate \
			-TrackModifyDate \
			-MediaLanguageCode \
			-HandlerType \
			-ImageSize \
			-FilePermissions \
			"$1"
		fi
		;;
esac
