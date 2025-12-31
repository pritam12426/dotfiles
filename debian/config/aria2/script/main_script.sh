#!/bin/bash
# --on-download-complete "myhook.sh '$PWD' '/path/to/aria2.log'"
# https://aria2.github.io/manual/en/html/aria2c.html#event-hook

# echo "Called with [$1] [$2] [$3]"
# $1 ==> GID
# $2 ==> Number of file   (Bit torrent have multiple files in it)
# $3 ==> full file path

HISTORY_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/aria2/aria2_downloads.sqlite3"
SQL_HISTORY_STRUCTURE="$HOME/.config/aria2/script/sql_history_structure.sql"

# Log the download information to the database -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


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
