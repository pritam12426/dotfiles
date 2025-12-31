#!/usr/bin/env bash

# gDrive - Upload files/directories to Google Drive using rclone
# Usage: gDrive [-n|--dry-run] <source_path> [<source_path>...]

set -euo pipefail # Better error handling: exit on error, unset vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

dry_run=false
sources=()

# Parse options
while [[ $# -gt 0 ]]; do
	case $1 in
	-n | --dry-run)
		dry_run=true
		shift
		;;
	-*)
		echo "Unknown option: $1"
		echo "Usage: gDrive [-n|--dry-run] <source_path> [<source_path>...]"
		exit 1
		;;
	*)
		sources+=("$1")
		shift
		;;
	esac
done

if [[ ${#sources[@]} -eq 0 ]]; then
	echo "Usage: gDrive [-n|--dry-run] <source_path> [<source_path>...]"
	exit 1
fi

# Destination base (hostname-based folder)
host=$(hostname -s)
dest="Gdrive:/rclone/${host}/"

# rclone common flags
rclone_flags=(
	-vP
	--checksum
	--transfers 4
	--checkers 8
	--metadata
	--update      # Skip files that are newer on destination
	# --tpslimit 10 # Avoid API rate limits
	--stats 30s
)

if $dry_run; then
	rclone_flags+=(--dry-run)
	echo -e "⚡️ ${YELLOW}DRY-RUN MODE ENABLED (no changes will be made)${NC}"
fi

success_count=0
fail_count=0
failed_items=()

for source in "${sources[@]}"; do
	if [[ ! -e $source ]]; then
		echo -e "🚫 ${RED} Error: Source does not exist: \"$source\"${NC}"
		((fail_count++))
		failed_items+=("$source")
		continue
	fi

	base=$(basename "$source")
	if [[ -d $source ]]; then
		final_dest="${dest}${base}/"
		echo -e "${GREEN}☁️  Uploading directory:${NC} \"$source\" → \"$final_dest\""
		rclone copy "$source" "$final_dest" "${rclone_flags[@]}"
	else
		final_dest="${dest}"
		echo -e "${GREEN}☁️  Uploading file:${NC} \"$source\" → \"$final_dest$base\""
		rclone copyto "$source" "${final_dest}$base" "${rclone_flags[@]}"
	fi

	exit_code=$?
	if [[ $exit_code -eq 0 ]]; then
		((success_count++))
		echo -e "✅ ${GREEN} Success:${NC} \"$source\"\n"
	else
		echo -e "🚫 ${RED} Failed:${NC} \"$source\" (exit code: $exit_code)\n"
		((fail_count++))
		failed_items+=("$source")
	fi
done

# Final summary and notification
total=$((success_count + fail_count))

if [[ $fail_count -eq 0 ]]; then
	message="Successfully uploaded $success_count item(s) to Google Drive"
	notify "Upload Complete" "gDrive" "$message" || true
	echo -e "${GREEN}🎉 $message${NC}"
else
	message="Uploaded $success_count/$total item(s). Failed: $fail_count"
	notify "Upload Partial Failure" "gDrive" "$message" || true
	echo -e "${YELLOW}⚠️  $message${NC}"
	if [[ ${#failed_items[@]} -gt 0 ]]; then
		echo -e "${RED}Failed items:${NC}"
		printf '   • %s\n' "${failed_items[@]}"
	fi
fi

exit $fail_count
