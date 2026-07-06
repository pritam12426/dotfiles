#!/usr/bin/env bash

findparms=(-maxdepth 1 -name '*.mp3' -or -name '*.mov' -or -name '*.wav' -or -name '*.m4a' -or -name '*.mp4' -or -name '*.mkv' -or -name '*.webm' -or -name '*.part')  # The filter to find the file using `find` command

# if [[ "$PWD" == "$HOME/Downloads/yt_dlp"* ]]; then
# 	findparms=(-type f -mtime -1 -maxdepth 1 -name '*.mp3' -or -name '*.mov' -or -name '*.wav' -or -name '*.m4a' -or -name '*.mp4' -or -name '*.mkv' -or -name '*.webm') # The filter to find the file using `find` command
# else
# 	findparms=(-type f -maxdepth 1 -name '*.mp3' -or -name '*.mov' -or -name '*.wav' -or -name '*.m4a' -or -name '*.mp4' -or -name '*.mkv' -or -name '*.webm') # The filter to find the file using `find` command
# fi

format_seconds() {
	local seconds=$1
	local hours=$((seconds / 3600))
	local minutes=$(( (seconds % 3600) / 60 ))
	local remaining_seconds=$((seconds % 60))

	printf "%02d:%02d:%02d\n" $hours $minutes $remaining_seconds
}

command=""
video_title=""
title_opction=""

(find "." "${findparms[@]}" | sed "s%./%%" | sort) | fzf | {
	read -r sk_passed_file

	if [ -z "$sk_passed_file" ]; then
		exit 1
	fi

	extension="${sk_passed_file##*.}"

	video_title=$(ffprobe -v error -select_streams v:0 -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$sk_passed_file")

	if [ -z "$video_title" ]; then
		video_title+=$(echo "$sk_passed_file" | tr '_' ' ')
	fi

	title_opction+=", "

	if [ "$extension" == "mp3" ] || [ "$extension" == "m4a" ] || [ "$extension" == "mav" ]; then
		title_opction+="'"
		bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$sk_passed_file")
		title_opction+=$(echo "scale=2; $bitrate / 1000" | bc | xargs printf "%.0f" )
		title_opction+="kbps'"

		command+="ffplay -loop -1 -nostats -seek_interval 5 -window_title"
	elif [ "$extension" == "mp4" ] || [ "$extension" == "mkv" ] || [ "$extension" == "mov" ] || [ "$extension" == "webm" ] || [ "$extension" == "part" ]; then

		title_opction+="'"
		title_opction+=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 "$sk_passed_file")
		title_opction+="x"
		title_opction+=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 "$sk_passed_file")
		title_opction+="p' • '"
		fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$sk_passed_file")
		title_opction+=$(echo "scale=4; $fps" | bc | xargs printf "%.0f" )
		title_opction+="fps'"

		command+="ffplay -nostats -loop -1 -sn -seek_interval 5 -window_title"
	fi

	title_opction+=" • '"
	time+=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$sk_passed_file")
	time=$(printf "%.0f" "$time")
	title_opction+=$(format_seconds "$time" )
	title_opction+="'"

	echo "Title: $video_title"
	echo -e "File:  $sk_passed_file\n"

	echo $command \"$video_title$title_opction\" \"$PWD/$sk_passed_file\"
	nohup $command "$video_title$title_opction" "$sk_passed_file" > /dev/null 2>&1 &
	# sleep 1
}
