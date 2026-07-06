#!/usr/bin/env bash

# gDrive - Two-way Google Drive transfer tool using rclone
#
# USAGE:
#   gDrive [push] [flags] <source_path> [<source_path>...]   # upload  (default)
#   gDrive  pull  [flags] <remote_path> [<local_dest>]       # download
#
# SUBCOMMANDS:
#   push   Upload local files/dirs to Google Drive (default when omitted)
#   pull   Download a remote path to a local destination
#
# SHARED FLAGS (both subcommands):
#   -n, --dry-run          Show what would transfer without making changes
#   -R, --remote <name>    rclone remote to use (default: Gdrive)
#
# PUSH FLAGS:
#   -d, --dest <path>      Override remote destination
#                          Accepts a bare path (/backups/foo) or remote:path
#                          Default: /rclone/<hostname>/
#
# PULL FLAGS:
#   -o, --output <dir>     Local directory to download into (default: $PWD)
#
# EXAMPLES:
#   gDrive ~/Documents                          # push (implicit)
#   gDrive push ~/Documents ~/Pictures          # push (explicit), multiple sources
#   gDrive pull /rclone/mymac/Documents         # pull into current directory
#   gDrive pull /rclone/mymac/file.txt -o ~/Downloads
#   gDrive pull /rclone/mymac/ -o ~/Restore --dry-run
#
# DEPENDENCIES:
#   rclone   — required  (https://rclone.org)
#   notify   — optional  (custom desktop-notification helper; skipped if absent)

set -euo pipefail

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---------- Helpers ----------

# notify is an optional external helper (e.g. a custom desktop-notification script).
# If it is not in $PATH the transfer still completes; the notification is just skipped.
safe_notify() {
	if command -v notify &> /dev/null; then
		notify "$@" || true
	fi
}

# Validate that a named rclone remote actually exists in the config.
validate_remote() {
	local r="$1"
	local remotes
	remotes="$(rclone listremotes)"
	if ! printf '%s\n' "$remotes" | grep -Fxq "${r}:"; then
		echo -e "${RED}Error:${NC} Remote '$r' does not exist in rclone config" >&2
		echo '' >&2
		echo 'Existing remotes:' >&2
		printf '%s\n' "$remotes" | tr ':' ' ' >&2
		exit 1
	fi
}

# Resolve a remote path into a fully-qualified rclone source/dest string.
# Accepts either a bare path (/rclone/foo) or a pre-qualified remote:path.
qualify_remote_path() {
	local remote="$1"
	local path="$2"
	local result
	if [[ "$path" == *:* ]]; then
		result="$path"
	else
		result="${remote}:${path}"
	fi
	# Ensure trailing slash so rclone treats it as a directory target
	[[ "$result" != */ ]] && result="${result}/"
	echo "$result"
}

show_usage() {
	echo 'Usage:'
	echo '  gDrive [push] [flags] <source_path> [<source_path>...]   # upload (default)'
	echo '  gDrive  pull  [flags] <remote_path> [<local_dest>]       # download'
	echo ''
	echo 'Shared flags:'
	echo '  -n, --dry-run          Show what would transfer without making changes'
	echo '  -R, --remote <name>    rclone remote to use (default: Gdrive)'
	echo ''
	echo 'Push flags:'
	echo '  -d, --dest <path>      Override remote destination path'
	echo ''
	echo 'Pull flags:'
	echo '  -o, --output <dir>     Local directory to download into (default: $PWD)'
}

# ---------- Globals ----------
host=$(hostname -s)
remote="Gdrive"
dry_run=false

# ---------- Subcommand detection ----------
# First non-flag argument is treated as the subcommand if it is "push" or "pull".
# Everything else falls through to push (backwards compatible).
subcommand="push"
if [[ $# -gt 0 && "$1" == "push" ]]; then
	subcommand="push"
	shift
elif [[ $# -gt 0 && "$1" == "pull" ]]; then
	subcommand="pull"
	shift
fi

# ---------- rclone base flags (shared by both modes) ----------
rclone_flags=(
	-vP
	--transfers 4
	--checkers 8
	--metadata
	--update    # skip files that are newer on the destination
	# --tpslimit 10   # uncomment to avoid API rate limits
	# --stats 30s
)

# ============================================================
# PUSH mode
# ============================================================
if [[ "$subcommand" == "push" ]]; then

	dest_override=""
	sources=()

	while [[ $# -gt 0 ]]; do
		case $1 in
		-n | --dry-run)
			dry_run=true
			shift
			;;
		-R | --remote)
			[[ -z "${2:-}" || "$2" == -* ]] && { echo "Error: --remote requires a NAME"; exit 1; }
			remote="$2"
			validate_remote "$remote"
			shift 2
			;;
		-d | --dest)
			[[ -z "${2:-}" || "$2" == -* ]] && { echo "Error: --dest requires a PATH"; exit 1; }
			dest_override="$2"
			shift 2
			;;
		--help | -h)
			show_usage; exit 0
			;;
		-*)
			echo "Unknown push option: $1"; show_usage; exit 1
			;;
		*)
			# realpath locks in absolute paths at parse time; non-existent paths are
			# caught later by the [[ ! -e $source ]] guard inside the upload loop.
			sources+=("$(realpath -- "$1")")
			shift
			;;
		esac
	done

	if [[ ${#sources[@]} -eq 0 ]]; then
		echo "Error: no source paths given" >&2; show_usage; exit 1
	fi

	# Build destination
	if [[ -n "$dest_override" ]]; then
		dest="$(qualify_remote_path "$remote" "$dest_override")"
	else
		dest="${remote}:/rclone/${host}/"
	fi

	# Push-specific rclone flags
	rclone_flags+=(--checksum)

	# Directory-only exclude flags — defined once, never mutated inside the loop.
	dir_flags=(
		--exclude ".DS_Store"
		--exclude ".git"
		--exclude ".gitignore"
		--exclude "*.tmp"
		--exclude "*._*"      # macOS resource-fork thumbnails
		--exclude ".*{/**,}"  # hidden files and folders
	)

	if $dry_run; then
		rclone_flags+=(--dry-run)
		echo -e "⚡️ ${YELLOW}DRY-RUN MODE ENABLED (no changes will be made)${NC}"
	fi

	echo -e "${CYAN}▶ push${NC}  remote: ${remote}  →  dest: ${dest}"
	printf '%0.s─' $(seq 1 "$(tput cols)") >&2; echo >&2

	success_count=0
	fail_count=0
	failed_items=()

	for source in "${sources[@]}"; do
		if [[ ! -e $source ]]; then
			echo -e "🚫 ${RED}Error: source does not exist:${NC} \"$source\""
			fail_count=$((fail_count + 1))
			failed_items+=("$source")
			continue
		fi

		base=$(basename "$source")
		exit_code=0

		if [[ -d $source ]]; then
			final_dest="${dest}${base}/"
			echo -e "${GREEN}☁️  Uploading directory:${NC} \"$source\" → \"$final_dest\""
			rclone copy "$source" "$final_dest" "${rclone_flags[@]}" "${dir_flags[@]}" || exit_code=$?
		else
			final_dest="${dest}"
			echo -e "${GREEN}☁️  Uploading file:${NC} \"$source\" → \"${final_dest}${base}\""
			rclone copyto "$source" "${final_dest}${base}" "${rclone_flags[@]}" || exit_code=$?
		fi

		if [[ $exit_code -eq 0 ]]; then
			success_count=$((success_count + 1))
			echo -e "✅ ${GREEN}Success:${NC} \"$source\"\n"
		else
			echo -e "🚫 ${RED}Failed${NC} (exit $exit_code): \"$source\"\n"
			fail_count=$((fail_count + 1))
			failed_items+=("$source")
		fi
	done

	total=$((success_count + fail_count))

	if [[ $fail_count -eq 0 ]]; then
		message="Successfully uploaded $success_count item(s) to ${remote}"
		safe_notify "Upload Complete ${remote}" "$message" "info"
		echo -e "${GREEN}🎉 $message${NC}"
	else
		message="Uploaded $success_count/$total item(s) to ${remote}. Failed: $fail_count"
		safe_notify "Upload Partial Failure ${remote}" "$message" "error"
		echo -e "${YELLOW}⚠️  $message${NC}"
		if [[ ${#failed_items[@]} -gt 0 ]]; then
			echo -e "${RED}Failed items:${NC}"
			printf '   • %s\n' "${failed_items[@]}"
		fi
	fi

	exit $fail_count
fi

# ============================================================
# PULL mode
# ============================================================
if [[ "$subcommand" == "pull" ]]; then

	remote_path=""
	local_dest=""
	output_override=""

	while [[ $# -gt 0 ]]; do
		case $1 in
		-n | --dry-run)
			dry_run=true
			shift
			;;
		-R | --remote)
			[[ -z "${2:-}" || "$2" == -* ]] && { echo "Error: --remote requires a NAME"; exit 1; }
			remote="$2"
			validate_remote "$remote"
			shift 2
			;;
		-o | --output)
			[[ -z "${2:-}" || "$2" == -* ]] && { echo "Error: --output requires a DIR"; exit 1; }
			output_override="$2"
			shift 2
			;;
		--help | -h)
			show_usage; exit 0
			;;
		-*)
			echo "Unknown pull option: $1"; show_usage; exit 1
			;;
		*)
			if [[ -z "$remote_path" ]]; then
				remote_path="$1"
			elif [[ -z "$local_dest" ]]; then
				local_dest="$1"
			else
				echo "Error: unexpected argument '$1'" >&2; show_usage; exit 1
			fi
			shift
			;;
		esac
	done

	# --output takes priority; positional local_dest is a convenience shorthand
	if [[ -n "$output_override" ]]; then
		local_dest="$output_override"
	fi
	# Default to current directory
	local_dest="${local_dest:-$PWD}"

	if [[ -z "$remote_path" ]]; then
		echo "Error: no remote path given" >&2; show_usage; exit 1
	fi

	# Build fully-qualified rclone source
	source_rclone="$(qualify_remote_path "$remote" "$remote_path")"

	# Resolve local destination to an absolute path
	local_dest="$(realpath -m -- "$local_dest")"

	if $dry_run; then
		rclone_flags+=(--dry-run)
		echo -e "⚡️ ${YELLOW}DRY-RUN MODE ENABLED (no changes will be made)${NC}"
	fi

	echo -e "${CYAN}▶ pull${NC}  remote: ${source_rclone}  →  local: ${local_dest}"
	printf '%0.s─' $(seq 1 "$(tput cols)") >&2; echo >&2

	# Create local destination if it does not exist yet (unless dry-run)
	if ! $dry_run && [[ ! -d "$local_dest" ]]; then
		echo -e "${YELLOW}  Creating local directory:${NC} $local_dest"
		mkdir -p "$local_dest"
	fi

	exit_code=0
	rclone copy "$source_rclone" "$local_dest" "${rclone_flags[@]}" || exit_code=$?

	if [[ $exit_code -eq 0 ]]; then
		message="Successfully downloaded '${remote_path}' → '${local_dest}'"
		safe_notify "Download Complete ${remote}" "$message" "info"
		echo -e "\n✅ ${GREEN}${message}${NC}"
	else
		message="Download failed (exit ${exit_code}): '${remote_path}'"
		safe_notify "Download Failed ${remote}" "$message" "error"
		echo -e "\n🚫 ${RED}${message}${NC}"
	fi

	exit $exit_code
fi
