#!/usr/bin/env bash
# zed-root – Edit root files with live sync via entr
set -euo pipefail

# ---- 1. Check input ----------------------------------------------------
if [[ $# -eq 0 ]]; then
    echo "Usage: zed-root <file>"
    exit 1
fi


ORIG_FILE=$(realpath "$1")
ORIG_NAME=$(basename "$ORIG_FILE")
TMP_FILE="${TMPDIR:-/tmp}/zed-root--$ORIG_NAME"

# ---- 2. Copy to temp ----------------------------------------------------
cp -p "$ORIG_FILE" "$TMP_FILE"

# ---- 3. Start entr (NO PIPELINE IN BACKGROUND) -------------------------
echo "$TMP_FILE" | entr sudo cp -p "$TMP_FILE" "$ORIG_FILE" &
ENTR_PID=$!

# ---- 4. Start Zed in background ----------------------------------------
echo "entr started with PID $ENTR_PID"
echo "Opening: $ORIG_FILE"
echo " Temp: $TMP_FILE"
echo " → Ctrl+S: save to original (sudo)"
echo " → Close Zed to exit"
zed --wait "$TMP_FILE"

# ---- 5. Stop entr cleanly -----------------------------------------------
if kill "$ENTR_PID" 2>/dev/null; then
	echo "Stopping file watcher..."
	wait "$ENTR_PID" 2>/dev/null || true
fi

# ---- 6. Cleanup ---------------------------------------------------------
sudo cp -p "$TMP_FILE" "$ORIG_FILE"
rm -f "$TMP_FILE"
echo "Done."
