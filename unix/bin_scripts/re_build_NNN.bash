#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------- CONFIG ----------------
: "${DOT_FILE:?DOT_FILE is not set}"

UPDATE=false
NNN_GIT_RIPO="$HOME/Developer/git_repository/online-repos/nnn"
LOCAL_PLUGIN_DIR="$HOME/.config/nnn/plugins"
PATCHS_DIR="$DOT_FILE/config/nnn/patchs"
CHECKOUT_VERISON_HASH="5b0919af16d2abe00c15cbf20a8f2057eb9c485f"
# ---------------------------------------

# ---------------- LOGGING ----------------
log() {
	printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

line() {
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '='
}

die() {
	log "❌ $1"
	exit 1
}
# ----------------------------------------

# ---------------- ARGUMENTS ----------------
case "${1:-}" in
--update | -U | -u)
	UPDATE=true
	;;
--help)
	echo "Usage: $0 [--update | -U | -u]"
	exit 0
	;;
esac
# ------------------------------------------

log "🚀 Starting nnn build"

# ---------------- CLONE ----------------
if [[ ! -d $NNN_GIT_RIPO ]]; then
	log "📥 Cloning nnn repository"
	git clone https://github.com/jarun/nnn.git "$NNN_GIT_RIPO" || die "Clone failed"
	curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs -o \
		/tmp/getplugs.sh && chmod +x /tmp/getplugs.sh && \
			/tmp/getplugs.sh
fi
# --------------------------------------
line

cd "$NNN_GIT_RIPO" || die "Cannot cd to repo '$NNN_GIT_RIPO'"

log "🧹 Resetting repo"
git fetch --all --tags || die "Fetch failed"
git reset --hard origin/master || true
git clean -dfx
line

if [[ $UPDATE == true ]]; then
	log "🔄 Updating repository"
	git fetch origin || die "Git fetch failed"
	# git pull --ff-only origin || die "Git pull failed"
else
	log "📌 Checking out commit: $CHECKOUT_VERISON_HASH"
	git fetch --all --tags || die "Git fetch failed"

	# Ensure commit exists
	if ! git cat-file -e "$CHECKOUT_VERISON_HASH^{commit}" 2>/dev/null; then
		die "Commit $CHECKOUT_VERISON_HASH not found"
	fi

	git checkout --detach "$CHECKOUT_VERISON_HASH" || die "Checkout failed"
fi

# ---------------- PATCH FUNCTION ----------------
line
git_apply_patch() {
	local patch="$PATCHS_DIR/$1"

	if [[ ! -f $patch ]]; then
		log "⚠️ Patch not found: $patch"
		return 0
	fi

	# log "🩹 Applying patch: $(basename "$patch")"

	if git apply --check "$patch"; then
		git apply "$patch"
		log "✅ Applied: $(basename "$patch")"
	else
		log "❌ Patch failed: $(basename "$patch")"
		return 1
	fi
}
# ------------------------------------------------

git_apply_patch "icons.patch"
git_apply_patch "nnn_keybinds.patch"
# git_apply_patch "nnn-builtin-cd-lastdir.patch"
line

# ---------------- BUILD ----------------
export PREFIX="$HOME/.local"

log "🏗  Building nnn"
# O_NOLC=1 \
make \
	O_NORL=0 \
	O_PCRE2=1 \
	O_NOSSN=1 \
	O_NOBATCH=1 \
	O_NOMOUSE=1 \
	O_NOFIFO=1 \
	O_EMOJI=1 \
	O_GITSTATUS=1 \
	O_NOX11=1 \
	clean strip install || die "Build failed"
line
# --------------------------------------

if [[ $UPDATE == true ]]; then
	read -rp "Do you want to update plugins? [y/N]: " reply

	if [[ $reply =~ ^[Yy]$ ]]; then
		log "🔌 Updating plugins"
		curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs -o \
			/tmp/getplugs.sh && chmod +x /tmp/getplugs.sh && \
				/tmp/getplugs.sh
	else
		log "❌ Plugin update skipped"
		exit 1
	fi
fi

# ---------------- BACKUP PLUGINS ----------------
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
