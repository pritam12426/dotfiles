#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------- CONFIG ----------------
: "${DOT_FILE:?DOT_FILE is not set}"

NNN_GIT_RIPO="$HOME/Developer/git_repository/online-repos/nnn"
LOCAL_PLUGIN_DIR="$HOME/.config/nnn/plugins"
PATCHS_DIR="$DOT_FILE/config/nnn/patchs"

UPDATE=false
# ---------------------------------------

# ---------------- LOGGING ----------------

log() {
	printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

die() {
	log "❌ $1"
	exit 1
}
# ----------------------------------------

# ---------------- ARGUMENTS ----------------
case "${1:-}" in
--update | -U)
	UPDATE=true
	;;
--help)
	echo "Usage: $0 [--update|-U]"
	exit 0
	;;
esac
# ------------------------------------------

log "🚀 Starting nnn build"

# ---------------- CLONE ----------------
if [[ ! -d $NNN_GIT_RIPO ]]; then
	log "📥 Cloning nnn repository"
	git clone https://github.com/jarun/nnn.git "$NNN_GIT_RIPO" || die "Clone failed"
	curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs -o /tmp/getplugs.sh
	sh /tmp/getplugs.sh
fi
# --------------------------------------

cd "$NNN_GIT_RIPO" || die "Cannot cd to repo"

log "🧹 Cleaning repo"
git clean -dfx
git reset --hard HEAD

if [[ $UPDATE == true ]]; then
	log "🔄 Updating repository"
	git pull --ff-only || die "Git pull failed"
fi

# ---------------- PATCH FUNCTION ----------------
git_apply_patch() {
	local patch="$1"

	if [[ ! -f $patch ]]; then
		log "⚠️ Patch not found: $patch"
		return 0
	fi

	log "🩹 Applying patch: $(basename "$patch")"

	if git apply --check "$patch"; then
		git apply "$patch"
		log "✅ Applied: $(basename "$patch")"
	else
		log "❌ Patch failed: $(basename "$patch")"
		return 1
	fi
}
# ------------------------------------------------

echo
git_apply_patch "$PATCHS_DIR/icons-v5.2.patch"
git_apply_patch "$PATCHS_DIR/nnn_keybinds-v5.patch"
git_apply_patch "$PATCHS_DIR/nnn-builtin-cd-lastdir-v5.patch"

# ---------------- BUILD ----------------
export PREFIX="$HOME/.local"

log "🏗 Building nnn"

make \
	O_PCRE2=1 \
	O_NOMOUSE=1 \
	O_EMOJI=1 \
	O_NOX11=1 \
	O_GITSTATUS=1 \
	clean strip install || die "Build failed"
# --------------------------------------

if [[ $UPDATE == true ]]; then
	log "🔌 Updating plugins"
	curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs -o /tmp/getplugs.sh
	sh /tmp/getplugs.sh
fi

# ---------------- BACKUP PLUGINS ----------------
mkdir -p "$LOCAL_PLUGIN_DIR"

if [[ -f "$LOCAL_PLUGIN_DIR/.cbcp" ]]; then
	log "📦 Backing up .cbcp"
	mv "$LOCAL_PLUGIN_DIR/.cbcp" "$LOCAL_PLUGIN_DIR/.cbcp-bk"
fi

if [[ -f "$LOCAL_PLUGIN_DIR/.ntfy" ]]; then
	log "📦 Backing up .ntfy"
	mv "$LOCAL_PLUGIN_DIR/.ntfy" "$LOCAL_PLUGIN_DIR/.ntfy-bk"
fi
# ----------------------------------------------

log "🎉 nnn build finished successfully"
