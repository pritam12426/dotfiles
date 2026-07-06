#!/usr/bin/env bash

set -euo pipefail

# ── Help ──────────────────────────────────────────────────────────────────────
show_help() {
	cat <<HELP
extractor — extract compressed archives

Usage:
  extractor [options] <file1> [file2 ...]

Options:
  -o, --output <dir>   Extract into <dir> instead of current directory
  --dry-run            List archive contents without extracting
  -h, --help           Show this help

Supported formats:
  .tar.gz / .tgz  .tar.bz2  .tar.xz  .tar
  .gz  .bz2  .xz  .zip  .7z

Examples:
  extractor archive.tar.gz
  extractor -o ~/extracted archive.zip
  extractor --dry-run archive.tar.gz
HELP
}

# ── Argument parsing ──────────────────────────────────────────────────────────
OUTPUT_DIR=""
DRY_RUN=false
FILES=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		show_help
		exit 0
		;;
	-o | --output)
		[[ -z "${2:-}" ]] && { echo "Error: --output requires a directory argument" >&2; exit 1; }
		OUTPUT_DIR="$2"
		shift 2
		;;
	--dry-run | -n)
		DRY_RUN=true
		shift
		;;
	--)
		shift
		FILES+=("$@")
		break
		;;
	-*)
		echo "Unknown option: $1" >&2
		echo "Try 'extractor --help'" >&2
		exit 1
		;;
	*)
		FILES+=("$1")
		shift
		;;
	esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
	show_help
	exit 1
fi

# ── Resolve & create output directory ────────────────────────────────────────
if [[ -n "$OUTPUT_DIR" ]]; then
	if $DRY_RUN; then
		echo "  (dry-run: would extract to '$OUTPUT_DIR')"
	else
		mkdir -p "$OUTPUT_DIR"
		OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"   # absolute path
	fi
fi

# ── Per-file helpers ──────────────────────────────────────────────────────────

# Build the tar -C / unzip -d / 7z -o flag when an output dir is set
tar_outflag()   { [[ -n "$OUTPUT_DIR" ]] && echo "-C $OUTPUT_DIR" || echo ""; }
unzip_outflag() { [[ -n "$OUTPUT_DIR" ]] && echo "-d $OUTPUT_DIR" || echo ""; }
p7z_outflag()   { [[ -n "$OUTPUT_DIR" ]] && echo "-o $OUTPUT_DIR" || echo ""; }

# For single-stream formats (gz/bz2/xz) that decompress in-place,
# we copy to OUTPUT_DIR first so we don't modify the source location.
copy_to_outdir() {
	local file="$1"
	if [[ -n "$OUTPUT_DIR" ]]; then
		cp -- "$file" "$OUTPUT_DIR/"
		echo "$OUTPUT_DIR/$(basename -- "$file")"
	else
		echo "$file"
	fi
}

# ── Main loop ─────────────────────────────────────────────────────────────────
for file in "${FILES[@]}"; do
	echo "Processing: $file"

	# Existence check — use original path, not basename
	if [[ ! -f "$file" ]]; then
		echo "  Error: File does not exist: '$file'" >&2
		continue
	fi

	# Absolute path so extraction commands work regardless of -C target
	abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename -- "$file")"
	filename="$(basename -- "$file")"

	if $DRY_RUN; then
		echo "  [dry-run] contents of $filename:"
		case "$filename" in
		*.tar.gz|*.tgz)   tar -tzf "$abs_file" ;;
		*.tar.bz2)        tar -tjf "$abs_file" ;;
		*.tar.xz)         tar -tJf "$abs_file" ;;
		*.tar)            tar -tf  "$abs_file" ;;
		*.gz)             echo "  (single gzip stream — decompresses to ${filename%.gz})" ;;
		*.bz2)            echo "  (single bzip2 stream — decompresses to ${filename%.bz2})" ;;
		*.xz)             echo "  (single xz stream — decompresses to ${filename%.xz})" ;;
		*.zip)            unzip -l "$abs_file" ;;
		*.7z)             7z l   "$abs_file" ;;
		*)                echo "  Unsupported format: $filename" ;;
		esac
	else
		case "$filename" in
		*.tar.gz|*.tgz)
			# shellcheck disable=SC2046
			tar -xzf "$abs_file" $(tar_outflag)
			;;
		*.tar.bz2)
			tar -xjf "$abs_file" $(tar_outflag)
			;;
		*.tar.xz)
			tar -xJf "$abs_file" $(tar_outflag)
			;;
		*.tar)
			tar -xf  "$abs_file" $(tar_outflag)
			;;
		*.gz)
			target="$(copy_to_outdir "$abs_file")"
			gzip -d "$target"
			;;
		*.bz2)
			target="$(copy_to_outdir "$abs_file")"
			bzip2 -d "$target"
			;;
		*.xz)
			target="$(copy_to_outdir "$abs_file")"
			xz -d "$target"
			;;
		*.zip)
			# shellcheck disable=SC2046
			unzip "$abs_file" $(unzip_outflag)
			;;
		*.7z)
			# shellcheck disable=SC2046
			7z x "$abs_file" $(p7z_outflag)
			;;
		*)
			echo "  Unsupported format: $filename" >&2
			continue
			;;
		esac
		echo "  ✔ Done: $filename"
	fi
	echo
done

echo "All files processed."
