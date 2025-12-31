#!/bin/bash
# https://aria2.github.io/manual/en/html/aria2c.html#event-hook

# echo "Called with [$1] [$2] [$3]"
# $1 ==> GID
# $2 ==> Number of file   (Bit torrent have multiple files in it)
# $3 ==> full file path

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
mkdir -p "$HOME/.local/share/yt-dlp"
HISTORY_FILE="$HOME/.local/share/yt-dlp/yt-dlp_aira2_download-history.txt"
# HISTORY_FILE="$HOME/Library/Caches/yt-dlp/yt-dlp_aira2_download-history.txt"

# FIX 1: The condition to check if the file does NOT exist.
# -x checks if a file is EXECUTABLE.
# ! -e checks if a file does NOT EXIST, which is what you want.
if [[ ! -e "$HISTORY_FILE" ]]; then
	(
		# FIX 2: Corrected formatting for 5 distinct columns.
		# This ensures "File" and "Path" are separate, aligned columns.
		printf "%-18s | %-28s | %-5s | %-120s | %s\n" "GID" "Date" "Num" "File" "Path"

		# BEST PRACTICE: A separator line that exactly matches the header widths.
		# This is better than a hardcoded line of dashes.
		printf "%-18s | %-28s | %-5s | %-120s | %s\n" \
			"------------------" "----------------------------" "-----" "------------------------------------------------------------------------------------------------------------------------" "-----------"
	) > "$HISTORY_FILE"
fi


(
	printf "%-18s | %-28s | %-5lld | %-120s | %s\n" "$1" "$(date +"%Y-%b-%d %Ih:%Mm:%Ss %p")" "$2" "$(basename "$3")" "$(dirname "$3")"
) >> "$HISTORY_FILE"
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


# Log the download information to the database -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
HISTORY_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/aria2/aria2_downloads.sqlite3"
SQL_HISTORY_STRUCTURE="$HOME/.config/aria2/script/sql_history_structure.sql"

# Create DB directory
mkdir -p "$(dirname "$HISTORY_FILE")"

# Ensure schema exists
if [[ ! -f $HISTORY_FILE ]]; then
	if [[ ! -f $SQL_HISTORY_STRUCTURE ]]; then
		# echo "Schema file not found: $SQL_HISTORY_STRUCTURE"
		exit 1
	fi
	sqlite3 "$HISTORY_FILE" < "$SQL_HISTORY_STRUCTURE"
fi

sqlite3 "$HISTORY_FILE" <<EOF
INSERT INTO
	DOWNLOAD_HISTORY (gid, total_files, size_bytes, base_name, path)
VALUES (
    "$1",
    "$2",
    "$(du        "$3" | cut -f1)",
    "$(basename  "$3" | sed "s/'/''/g")",
    "$(dirname   "$3" | sed "s/'/''/g")"
);
EOF
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


# Remove the *.aria2 file -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Check if the file exists and is a regular file
if [[ -f "$3.aria2" ]]; then
	rm -f "$3.aria2"
fi
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
