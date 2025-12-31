#!/bin/bash

# Check if at least one file is passed
if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <compressed_file1> [compressed_file2 ...]"
	exit 1
fi


for file in "$@"; do
	echo "Processing: $file"

	if [[ ! -f $file ]]; then
		echo "  Error: File does not exist."
		continue
	fi

	filename=$(basename -- "$file")

	echo "Try to use  bsdtar -t -f $filename"
	case "$filename" in
	*.tar.gz | *.tgz)
		tar -xzf "$filename"
		;;
	*.tar.bz2)
		tar -xjf "$filename"
		;;
	*.tar.xz)
		tar -xJf "$filename"
		;;
	*.tar)
		tar -xf "$filename"
		;;
	*.gz)
		gzip -d "$filename"
		;;
	*.bz2)
		bzip2 -d "$filename"
		;;
	*.xz)
		/usr/local/big_library/xz-5.8.0/bin/xz -d "$filename"
		;;
	*.zip)
		unzip "$filename"
		;;
	*.7z)
		7z x "$filename"
		;;
	*)
		echo "  Unsupported file format: $filename"
		;;
	esac

	echo "Done: $file"
	echo
done

echo "All files processed."
