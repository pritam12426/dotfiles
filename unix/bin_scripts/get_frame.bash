#!/usr/bin/env bash

set -euo pipefail

# ── Defaults ───────────────────────────────────────────────────────────────────

SOURCE_FILE=""
OUTPUT_PREFIX=""
OUTPUT_PREFIX_SET=false
OUTPUT_DIR="."
OUTPUT_EXT="jpg"

ALL=false
RANDOM_FRAME=false
TIMESTAMP=""
DRY_RUN=false
OVERWRITE=false
PREVIEW=false

COUNT=1
QUALITY=""        # empty = ffmpeg default
SCALE=""          # empty = no scaling
FPS=""            # empty = all frames (used with --all)
GRID=""           # empty = no grid, e.g. "3x2"
GIF_DURATION=""   # empty = not gif mode

FULL_OUTPUT_FILE=""
OUTPUT_FILES=()   # tracks all files written (for --count, --grid, --preview)

FFMPEG_CMD=(ffmpeg -hide_banner -loglevel warning -stats)

# ── Helpers ────────────────────────────────────────────────────────────────────

usage() {
	cat <<EOF
Usage:
  get-frame [options] <source_path>

Description:
  A small wrapper around ffmpeg for extracting frames from videos.

Modes (mutually exclusive):
  -a, --all                  Extract all frames (or N fps with --fps)
  -R, --random               Extract a random frame
  -t, --time <timestamp>     Extract frame at timestamp (HH:MM:SS or seconds)
  --gif <duration>           Extract a short GIF around a timestamp (requires -t)
  (default)                  Extract one random frame

Options:
  -o, --output <prefix>      Output file prefix (or full name with extension)
  -O, --output-dir <dir>     Output directory (default: current directory)
  -f, --format <ext>         Output format: jpg, png, webp, gif, auto (default: jpg)
                             'auto' detects from -o extension
  -c, --count <n>            Extract N random frames (random/default mode only)
  -q, --quality <1-100>      Output quality for jpg/webp (default: ffmpeg default)
  -s, --scale <WxH>          Scale output, e.g. 1280x720 or 640:-1
      --fps <n>              Frames per second to extract (--all mode only)
      --grid <NxM>           Tile extracted frames into a contact sheet (e.g. 3x2)
      --preview              Open the output file after extraction
  -y, --overwrite            Overwrite existing output files without prompting
  -n, --dry-run              Print ffmpeg command(s) without executing
  -h, --help                 Show this help message

Examples:
  get-frame movie.mp4
  get-frame -R movie.mp4
  get-frame -t 00:01:23 movie.mp4
  get-frame -a --fps 1 movie.mp4          # one frame per second
  get-frame -c 5 movie.mp4               # 5 random frames
  get-frame -c 9 --grid 3x3 movie.mp4   # 3x3 contact sheet
  get-frame -o shot.png movie.mp4        # auto-detect png from extension
  get-frame -q 90 -s 1280x720 movie.mp4
  get-frame -t 00:00:10 --gif 3 movie.mp4  # 3-second GIF from 10s
  get-frame --preview movie.mp4
EOF
}

die() {
	echo "get-frame: ❌ $*" >&2
	exit 1
}

# ── Timestamp validation ───────────────────────────────────────────────────────

validate_timestamp() {
	local ts="$1"
	# Accept: HH:MM:SS, HH:MM:SS.mmm, MM:SS, plain seconds (int or float)
	if [[ "$ts" =~ ^([0-9]{1,2}:)?[0-9]{1,2}:[0-9]{2}(\.[0-9]+)?$ ]] \
		|| [[ "$ts" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
		# Validate that MM and SS fields are < 60
		if [[ "$ts" =~ : ]]; then
			local ss="${ts##*:}"
			local mm="${ts%:*}"; mm="${mm##*:}"
			(( 10#${ss%%.*} < 60 )) || die "Seconds value out of range in timestamp: $ts"
			(( 10#${mm}     < 60 )) || die "Minutes value out of range in timestamp: $ts"
		fi
		return 0
	fi
	die "Invalid timestamp format: '$ts'  (use HH:MM:SS, MM:SS, or seconds)"
}

# ── Video duration via ffprobe ─────────────────────────────────────────────────

get_duration() {
	local duration
	duration=$(
		ffprobe \
			-v error \
			-show_entries format=duration \
			-of default=noprint_wrappers=1:nokey=1 \
			"$SOURCE_FILE"
	)
	duration=${duration%.*}
	[[ "$duration" =~ ^[0-9]+$ ]] || die "Failed to determine video duration"
	[[ "$duration" -gt 1 ]]       || die "Video duration must be greater than one second"
	echo "$duration"
}

random_seek_time() {
	local duration
	duration=$(get_duration)
	awk -v max="$duration" 'BEGIN { srand(); print int(rand() * (max - 1)) }'
}

# ── Quality / scale / overwrite filter args ────────────────────────────────────

quality_args() {
	[[ -z "$QUALITY" ]] && return
	case "$OUTPUT_EXT" in
		jpg|jpeg) echo "-q:v $(( 31 - (QUALITY * 31 / 100) ))" ;;  # ffmpeg jpg: 2(best)–31(worst)
		webp)     echo "-quality $QUALITY" ;;
		png)      : ;;   # PNG is lossless, quality flag ignored
	esac
}

scale_args() {
	[[ -z "$SCALE" ]] && return
	# Normalise: user may pass 1280x720 or 1280:720
	local s="${SCALE//x/:}"
	echo "-vf scale=$s"
}

overwrite_args() {
	$OVERWRITE && echo "-y" || echo "-n"
}

# Combine optional vf filters (scale + palette for gif, etc.)
vf_filter() {
	local filters=()
	[[ -n "$SCALE" ]] && filters+=("scale=${SCALE//x/:}")
	# Return comma-joined list, or empty
	local IFS=","
	echo "${filters[*]}"
}

# ── Run or print a command ─────────────────────────────────────────────────────

run_or_dry() {
	if [[ "$DRY_RUN" == true ]]; then
		printf 'Running: '
		printf '%q ' "$@"
		printf '\n'
	else
		"$@"
	fi
}

# ── Open file for preview ──────────────────────────────────────────────────────

open_preview() {
	local file="$1"
	[[ "$DRY_RUN" == true ]] && return
	# ffplay -loop -1 -sn -loglevel warning -stats -seek_interval 5
	case "$OSTYPE" in
		linux*)
			xdg-open "$file" &>/dev/null &
			;;
		darwin*)
			qlmanage -p >/dev/null 2>&1 -- "$file"
			;;
		*)
			echo "Unknown operating system: $OSTYPE"
			echo "get-frame: ⚠️  --preview: no 'open' or 'xdg-open' found" >&2
			exit 1;
		;;
	esac
}

# ── Build vf filter string ─────────────────────────────────────────────────────

build_vf() {
	local parts=()
	[[ -n "$SCALE" ]] && parts+=("scale=${SCALE//x/:}")
	local IFS=","
	echo "${parts[*]}"
}

# ── Modes ──────────────────────────────────────────────────────────────────────

#
# --all mode
#
run_all() {
	local out_dir
	out_dir="$(basename "$SOURCE_FILE" | sed 's/\.[^.]*$//')"
	[[ "$OUTPUT_DIR" != "." ]] && out_dir="$OUTPUT_DIR"

	local prefix="frame"
	[[ "$OUTPUT_PREFIX_SET" == true ]] && prefix="$OUTPUT_PREFIX"

	FULL_OUTPUT_FILE="${out_dir}/${prefix}_%06d.${OUTPUT_EXT}"
	mkdir -p -- "$out_dir"

	local cmd=("${FFMPEG_CMD[@]}" $(overwrite_args) -i "$SOURCE_FILE" -frame_pts 1)

	[[ -n "$FPS" ]] && cmd+=(-vf "fps=${FPS}$(
		local vf; vf=$(build_vf)
		[[ -n "$vf" ]] && echo ",$vf"
	)")
	[[ -z "$FPS" && -n "$SCALE" ]] && cmd+=(-vf "$(build_vf)")
	[[ -n "$(quality_args)" ]] && cmd+=($(quality_args))

	cmd+=("$FULL_OUTPUT_FILE")
	run_or_dry "${cmd[@]}"
	OUTPUT_FILES=("$FULL_OUTPUT_FILE")
}

#
# Single frame at a specific seek time
#
run_single_frame() {
	local seek_time="$1"
	local suffix="$2"       # e.g. "random-42" or "00:01:23"
	local output_file="${OUTPUT_DIR}/${OUTPUT_PREFIX}${suffix:+_$suffix}.${OUTPUT_EXT}"

	mkdir -p -- "$OUTPUT_DIR"

	local cmd=("${FFMPEG_CMD[@]}" $(overwrite_args)
		-ss "$seek_time"
		-i "$SOURCE_FILE"
		-frames:v 1
	)
	[[ -n "$(quality_args)" ]] && cmd+=($(quality_args))
	[[ -n "$(build_vf)" ]]     && cmd+=(-vf "$(build_vf)")
	cmd+=("$output_file")

	run_or_dry "${cmd[@]}"
	FULL_OUTPUT_FILE="$output_file"
	OUTPUT_FILES+=("$output_file")
}

#
# Accurate timestamp mode (seek after -i for frame accuracy)
#
run_timestamp() {
	local output_file="${OUTPUT_DIR}/${OUTPUT_PREFIX}.${OUTPUT_EXT}"
	mkdir -p -- "$OUTPUT_DIR"

	local cmd=("${FFMPEG_CMD[@]}" $(overwrite_args)
		-i "$SOURCE_FILE"
		-ss "$TIMESTAMP"
		-frames:v 1
	)
	[[ -n "$(quality_args)" ]] && cmd+=($(quality_args))
	[[ -n "$(build_vf)" ]]     && cmd+=(-vf "$(build_vf)")
	cmd+=("$output_file")

	run_or_dry "${cmd[@]}"
	FULL_OUTPUT_FILE="$output_file"
	OUTPUT_FILES=("$output_file")
}

#
# GIF mode — palette-based for quality output
#
run_gif() {
	[[ -z "$TIMESTAMP" ]] && die "--gif requires -t <timestamp>"
	[[ -z "$GIF_DURATION" || "$GIF_DURATION" -le 0 ]] && die "--gif duration must be > 0"

	local palette_file
	palette_file="$(mktemp /tmp/get_frame_palette_XXXXXX.png)"
	trap 'rm -f "$palette_file"' EXIT

	local output_file="${OUTPUT_DIR}/${OUTPUT_PREFIX}.gif"
	mkdir -p -- "$OUTPUT_DIR"

	local scale_filter=""
	[[ -n "$SCALE" ]] && scale_filter="scale=${SCALE//x/:},"

	# Step 1 — generate palette
	local palette_cmd=("${FFMPEG_CMD[@]}" $(overwrite_args)
		-ss "$TIMESTAMP"
		-t "$GIF_DURATION"
		-i "$SOURCE_FILE"
		-vf "${scale_filter}palettegen"
		-y "$palette_file"
	)

	# Step 2 — render GIF using palette
	local gif_cmd=("${FFMPEG_CMD[@]}" $(overwrite_args)
		-ss "$TIMESTAMP"
		-t "$GIF_DURATION"
		-i "$SOURCE_FILE"
		-i "$palette_file"
		-lavfi "${scale_filter}paletteuse"
		"$output_file"
	)

	echo "get-frame: 🎨 Generating palette…"
	run_or_dry "${palette_cmd[@]}"
	echo "get-frame: 🎞️  Rendering GIF…"
	run_or_dry "${gif_cmd[@]}"

	FULL_OUTPUT_FILE="$output_file"
	OUTPUT_FILES=("$output_file")
}

#
# Grid / contact-sheet mode
#
run_grid() {
	local cols rows
	IFS='x' read -r cols rows <<< "$GRID"
	[[ "$cols" =~ ^[0-9]+$ && "$rows" =~ ^[0-9]+$ ]] \
		|| die "--grid must be NxM (e.g. 3x2), got: $GRID"

	local total=$(( cols * rows ))
	[[ "$total" -lt 2 ]] && die "--grid product must be at least 2"

	# Collect N random frames into a temp dir
	local tmp_dir
	tmp_dir="$(mktemp -d /tmp/get_frame_grid_XXXXXX)"
	trap 'rm -rf "$tmp_dir"' EXIT

	echo "get-frame: 🎲 Extracting $total frames for ${cols}x${rows} grid…"
	local i
	for (( i=0; i<total; i++ )); do
		local seek_time
		seek_time=$(random_seek_time)
		local frame_file="${tmp_dir}/frame_$(printf '%03d' $i).${OUTPUT_EXT}"
		local cmd=("${FFMPEG_CMD[@]}" -y
			-ss "$seek_time"
			-i "$SOURCE_FILE"
			-frames:v 1
		)
		[[ -n "$(build_vf)" ]] && cmd+=(-vf "$(build_vf)")
		[[ -n "$(quality_args)" ]] && cmd+=($(quality_args))
		cmd+=("$frame_file")
		run_or_dry "${cmd[@]}"
	done

	# Tile with ffmpeg's tile filter
	local grid_file="${OUTPUT_DIR}/${OUTPUT_PREFIX}_grid-${cols}x${rows}.${OUTPUT_EXT}"
	mkdir -p -- "$OUTPUT_DIR"

	local tile_cmd=(ffmpeg -hide_banner -loglevel warning -y
		-pattern_type glob
		-i "${tmp_dir}/*.${OUTPUT_EXT}"
		-vf "tile=${cols}x${rows}"
		"$grid_file"
	)
	echo "get-frame: 🖼️  Composing contact sheet…"
	run_or_dry "${tile_cmd[@]}"

	FULL_OUTPUT_FILE="$grid_file"
	OUTPUT_FILES=("$grid_file")
}

# ── Argument parsing ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
	case "$1" in

	-h|--help)      usage; exit 0 ;;
	-a|--all)       ALL=true; shift ;;
	-R|--random)    RANDOM_FRAME=true; shift ;;
	-n|--dry-run)   DRY_RUN=true; shift ;;
	-y|--overwrite) OVERWRITE=true; shift ;;
	--preview)      PREVIEW=true; shift ;;

	-t|--time)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		TIMESTAMP="$2"; shift 2 ;;

	-o|--output)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		OUTPUT_PREFIX="$2"
		OUTPUT_PREFIX_SET=true
		shift 2 ;;

	-O|--output-dir)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		OUTPUT_DIR="$2"; shift 2 ;;

	-f|--format)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		OUTPUT_EXT="${2#*.}"; shift 2 ;;

	-c|--count)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		[[ "$2" =~ ^[1-9][0-9]*$ ]] || die "--count must be a positive integer"
		COUNT="$2"; shift 2 ;;

	-q|--quality)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		[[ "$2" =~ ^[1-9][0-9]?$|^100$ ]] || die "--quality must be 1-100"
		QUALITY="$2"; shift 2 ;;

	-s|--scale)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		[[ "$2" =~ ^[0-9-]+[x:][0-9-]+$ ]] || die "--scale must be WxH or W:H (e.g. 1280x720 or 640:-1)"
		SCALE="$2"; shift 2 ;;

	--fps)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		[[ "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "--fps must be a positive number"
		FPS="$2"; shift 2 ;;

	--grid)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		[[ "$2" =~ ^[0-9]+x[0-9]+$ ]] || die "--grid must be NxM (e.g. 3x2)"
		GRID="$2"; shift 2 ;;

	--gif)
		[[ $# -lt 2 ]] && die "Missing value for $1"
		[[ "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "--gif duration must be a positive number"
		GIF_DURATION="$2"
		OUTPUT_EXT="gif"
		shift 2 ;;

	-*)
		die "Unknown option: $1" ;;

	*)
		[[ -n "$SOURCE_FILE" ]] && die "Only one source file allowed"
		SOURCE_FILE="$1"; shift ;;
	esac
done

# ── Post-parse: auto-detect format from -o extension ──────────────────────────

if [[ "$OUTPUT_PREFIX_SET" == true && "$OUTPUT_EXT" == "jpg" ]]; then
	detected_ext="${OUTPUT_PREFIX##*.}"
	if [[ "$detected_ext" != "$OUTPUT_PREFIX" ]]; then   # dot was found
		case "$detected_ext" in
		jpg|jpeg|png|webp|gif)
			OUTPUT_EXT="$detected_ext"
			OUTPUT_PREFIX="${OUTPUT_PREFIX%.*}"
			;;
		esac
	fi
fi

# ── Default output prefix from source filename ─────────────────────────────────

if [[ "$OUTPUT_PREFIX_SET" == false ]]; then
	OUTPUT_PREFIX="$(basename "$SOURCE_FILE" | sed 's/\.[^.]*$//')"
fi

# ── Validate ───────────────────────────────────────────────────────────────────

validate_args() {
	[[ -z "$SOURCE_FILE" ]] && { usage; exit 1; }

	# Mutex checks — run before file check so errors are clear even with fake paths
	[[ "$ALL" == true && "$RANDOM_FRAME" == true ]]     && die "--all cannot be used with --random"
	[[ "$ALL" == true && -n "$TIMESTAMP" ]]             && die "--all cannot be used with --time"
	[[ "$RANDOM_FRAME" == true && -n "$TIMESTAMP" ]]    && die "--random cannot be used with --time"
	[[ -n "$GIF_DURATION" && -z "$TIMESTAMP" ]]         && die "--gif requires -t <timestamp>"
	[[ -n "$GIF_DURATION" && "$ALL" == true ]]          && die "--gif cannot be used with --all"
	[[ -n "$GIF_DURATION" && "$RANDOM_FRAME" == true ]] && die "--gif cannot be used with --random"
	[[ -n "$GRID" && "$ALL" == true ]]                  && die "--grid cannot be used with --all"
	[[ -n "$GRID" && -n "$TIMESTAMP" ]]                 && die "--grid cannot be used with --time (it picks random frames)"
	[[ -n "$FPS" && "$ALL" == false ]]                  && die "--fps is only valid with --all"
	[[ "$COUNT" -gt 1 && -n "$TIMESTAMP" ]]             && die "--count cannot be used with --time"
	[[ "$COUNT" -gt 1 && "$ALL" == true ]]              && die "--count cannot be used with --all"

	[[ ! -f "$SOURCE_FILE" ]] && die "File not found: $SOURCE_FILE"

	# Format validation
	case "$OUTPUT_EXT" in
	jpg|jpeg|png|webp|gif) ;;
	*) die "Unsupported output format: $OUTPUT_EXT" ;;
	esac

	# Timestamp validation (when provided)
	[[ -n "$TIMESTAMP" ]] && validate_timestamp "$TIMESTAMP"

	# Quality only applies to jpg/webp
	if [[ -n "$QUALITY" ]]; then
		case "$OUTPUT_EXT" in
		jpg|jpeg|webp) ;;
		*) echo "get-frame: ⚠️  --quality ignored for $OUTPUT_EXT (only applies to jpg/webp)" >&2 ;;
		esac
	fi
}

validate_args

# ── Dispatch ───────────────────────────────────────────────────────────────────

if [[ -n "$GIF_DURATION" ]]; then
	run_gif

elif [[ -n "$GRID" ]]; then
	run_grid

elif [[ "$ALL" == true ]]; then
	run_all

elif [[ -n "$TIMESTAMP" ]]; then
	run_timestamp

elif [[ "$COUNT" -gt 1 || "$RANDOM_FRAME" == true ]]; then
	#
	# Random / count mode
	#
	for (( i=0; i<COUNT; i++ )); do
		seek_time=$(random_seek_time)
		if [[ "$COUNT" -gt 1 ]]; then
			run_single_frame "$seek_time" "random-$(printf '%03d' $((i+1)))-${seek_time}s"
		else
			run_single_frame "$seek_time" "random-${seek_time}"
		fi
	done

else
	#
	# Default: one random frame
	#
	seek_time=$(random_seek_time)
	run_single_frame "$seek_time" "random-${seek_time}"
fi

# ── Output / preview ───────────────────────────────────────────────────────────

for f in "${OUTPUT_FILES[@]}"; do
	echo "$f"
done

if $PREVIEW && [[ ${#OUTPUT_FILES[@]} -gt 0 ]]; then
	open_preview "${OUTPUT_FILES[0]}"
fi
