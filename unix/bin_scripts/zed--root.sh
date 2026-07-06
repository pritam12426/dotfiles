#!/usr/bin/env bash
# zed-root – Edit root-owned files safely with Zed + live sync via entr
set -euo pipefail

# ---- 1. Check input ----------------------------------------------------
if [[ $# -eq 0 ]]; then
	echo "Usage: zed-root <file>"
	exit 1
fi

ORIG_FILE=$(realpath "$1")
ORIG_NAME=$(basename "$ORIG_FILE")
TMP_FILE="${TMPDIR:-/tmp}/zed-root--$$-$ORIG_NAME"

if [[ ! -f $ORIG_FILE ]]; then
	echo "Error: File does not exist: $ORIG_FILE"
	exit 1
fi

# ---- 2. Capture original permissions + ownership -----------------------
ORIG_PERMS=$(stat -c "%a" "$ORIG_FILE" 2> /dev/null || stat -f "%Lp" "$ORIG_FILE")
ORIG_OWNER=$(stat -c "%U:%G" "$ORIG_FILE" 2> /dev/null || stat -f "%Su:%Sg" "$ORIG_FILE")

# ---- 3. Copy to temp (drop ownership so Zed can write without sudo) ----
cp "$ORIG_FILE" "$TMP_FILE"
chmod u+rw "$TMP_FILE"

# ---- 4. Authenticate once up-front -------------------------------------
# sudo -v refreshes the cached credential in THIS session.
# The entr subshell below is a child of this process, so it shares
# the same sudo credential cache — no new session, no cache miss.
echo "Authenticating for live sync (Ctrl+S → original file)..."
sudo -v

# ---- 5. Start entr in a background subshell ----------------------------
# Running as ( ... ) & keeps entr inside a child of THIS process,
# so sudo -n can reuse the credential cache primed above.
# -p: don't run the command on startup, only on file changes.
# -z: exit if the command exits with a non-zero status (e.g. file deleted).
(echo "$TMP_FILE" | entr -pz sh -c "
    sudo -n cp '$TMP_FILE' '$ORIG_FILE' \
        && echo '  [synced $(date +%H:%M:%S)]' \
        || echo '  [sync failed – sudo cache may have expired]'
") &
WATCHER_PID=$!

# ---- 6. Open Zed (blocks until editor window is closed) ----------------
echo "Watcher started (PID=$WATCHER_PID)"
echo "  Original : $ORIG_FILE"
echo "  Temp     : $TMP_FILE"
echo "  Perms    : $ORIG_PERMS  Owner: $ORIG_OWNER"
echo "  → Ctrl+S saves live to original; close Zed to finish."
echo ""

zed --wait "$TMP_FILE"

# ---- 7. Stop entr cleanly ----------------------------------------------
if kill "$WATCHER_PID" 2> /dev/null; then
	echo "Stopping file watcher..."
	wait "$WATCHER_PID" 2> /dev/null || true
fi

# ---- 8. Final authoritative copy with original perms + owner -----------
# This is the only step that may prompt for your password (if cache expired).
echo "Writing final changes to $ORIG_FILE ..."
sudo cp "$TMP_FILE" "$ORIG_FILE"
sudo chmod "$ORIG_PERMS" "$ORIG_FILE"
sudo chown "$ORIG_OWNER" "$ORIG_FILE"

# ---- 9. Cleanup ---------------------------------------------------------
rm -f "$TMP_FILE"
echo "Done. $ORIG_FILE  perms=$ORIG_PERMS  owner=$ORIG_OWNER"
