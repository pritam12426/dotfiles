#!/bin/bash

# Target output file
OUTPUT="$HOME/.cache/firefox_cookies.txt"

# macOS Firefox Profile Path (Escaped for the shell)
# We use a variable for the glob to find the profile directory
#SQLITE_PATH="~/Library/Application Support/Firefox/Profiles/*/cookies.sqlite" << not working ?

echo "[*] Searching for Firefox cookies..."

# Find the actual file (handles the * wildcard)
# We take the first one found if multiple profiles exist
DB_FILE=$(ls ~/Library/Application\ Support/Firefox/Profiles/*/cookies.sqlite 2>/dev/null | head -n 1)

if [ -z "$DB_FILE" ]; then
    echo "[-] Error: Could not find cookies.sqlite. Please check your Firefox installation."
    exit 1
fi

echo "[+] Found database: $DB_FILE"

# Firefox locks the DB while open. We copy it to /tmp to read it safely.
TEMP_DB="/tmp/firefox_cookies_bak.sqlite"
cp "$DB_FILE" "$TEMP_DB"

echo "[*] Extracting cookies to $OUTPUT with secure permissions..."

# The SQL Query to format as Netscape/curl compatible text

sqlite3 -separator $'\t' "$TEMP_DB" << EOF > "$OUTPUT"
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
    echo "[+] Success! Your cookies are saved in $OUTPUT"
    echo "[!] Reminder: Keep this file private. It contains your active login sessions."
    chmod 600 "$OUTPUT"
else
    echo "[-] An error occurred during extraction."
    exit 1
fi
