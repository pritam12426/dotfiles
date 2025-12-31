#!/usr/bin/env bash

OUTPUT_FILE="$HOME/.cache/firefox_cookies.txt"

case "$1" in
--file)
	# Use the second argument as filename, or fallback to default
	if [ -n "$2" ]; then
		OUTPUT_FILE="$2"
	else
		# or just make it empty / disable file output
		OUTPUT_FILE=""
	fi
	;;
--help | -h)
	echo "Usage: $0 [--file [filename]]"
	echo "  --file FILE    : save cookies to FILE instead of default"
	echo "  --file         : don't save to any file"
	exit 0
	;;
esac

# Rest of your script here...
echo "Will save cookies to: ${OUTPUT_FILE:-<no file>}"

# Target output file

# macOS Firefox Profile Path (Escaped for the shell)
# We use a variable for the glob to find the profile directory
#SQLITE_PATH="~/Library/Application Support/Firefox/Profiles/*/cookies.sqlite" << not working ?

echo "[*] Searching for Firefox cookies..."

# Find the actual file (handles the * wildcard)
# We take the first one found if multiple profiles exist
DB_FILE=$(ls ~/Library/Application\ Support/Firefox/Profiles/*/cookies.sqlite 2> /dev/null | head -n 1)

if [ -z "$DB_FILE" ]; then
	echo "[-] Error: Could not find cookies.sqlite. Please check your Firefox installation."
	exit 1
fi

echo "[+] Found database: $DB_FILE"

# Firefox locks the DB while open. We copy it to /tmp to read it safely.
TEMP_DB="/tmp/firefox_cookies_bak.sqlite"
cp "$DB_FILE" "$TEMP_DB"

echo "[*] Extracting cookies to $OUTPUT_FILE with secure permissions..."

# The SQL Query to format as Netscape/curl compatible text

sqlite3 -separator $'\t' "$TEMP_DB" << EOF > "$OUTPUT_FILE"
.mode tabs
SELECT
    host,
    CASE WHEN host LIKE '.%' THEN 'TRUE' ELSE 'FALSE' END,
    path,
    CASE WHEN isSecure THEN 'TRUE' ELSE 'FALSE' END,
    expiry,
    name,
    value
FROM moz_cookies;
EOF

# Cleanup
rm -f "$TEMP_DB" "$TEMP_DB-shm" "$TEMP_DB-wal"

if [ $? -eq 0 ]; then
	echo "[+] Success! Your cookies are saved in $OUTPUT_FILE"
	echo "[!] Reminder: Keep this file private. It contains your active login sessions."
	chmod 600 "$OUTPUT_FILE"
else
	echo "[-] An error occurred during extraction."
	exit 1
fi
