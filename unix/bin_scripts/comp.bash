#!/usr/bin/env bash

set -euo pipefail

# run — Universal project-aware file runner
#
# A smart wrapper that detects file type and:
#   • Runs executables directly
#   • Compiles C/C++/Rust if needed
#   • Uses project tools (cmake, make, cargo, go, zig, etc.)
#   • Detects Git project root automatically
#   • Supports timing mode
#
# ------------------------------------------------------------
# USAGE:
#   run <file> [args...] [flags]
#
# FLAGS:
#   --time          Show execution time, CPU and memory usage
#   --pwd           In compile mode, place output binary in current directory ($PWD)
#   --compile-only  Compile but do not run the output binary
#   --dry-run       Print the command that would run, without executing it
#   --watch         Re-run automatically whenever the file changes
#   --release       Compile/run in release/optimised mode (C, C++, Rust, Zig)
#   --env FILE      Source FILE as a .env before running (e.g. --env .env.local)
#   --out NAME      Override the output binary name (compile mode only)
#   --stdin FILE    Feed FILE into the program's stdin on launch
#   --help          Show help message
#
# ------------------------------------------------------------
# EXAMPLES:
#
#   # Run a compiled binary
#   run ./a.out
#
#   # Compile and run C file
#   run main.c
#
#   # Compile C file and store output in current directory
#   run main.c --pwd
#
#   # Run Rust project (uses cargo automatically)
#   run src/main.rs
#
#   # Run with arguments
#   run main.c arg1 arg2
#
#   # Measure time and memory usage
#   run main.c --time
#
#   # Print command without running
#   run main.c --dry-run
#
#   # Re-run on every file save
#   run main.py --watch
#
#   # Compile in release mode
#   run main.c --release
#
#   # Load env vars from a file before running
#   run main.py --env .env.local
#
#   # Name the output binary explicitly
#   run src/main.c --out myapp
#
#   # Feed test input via stdin
#   run main.c --stdin tests/input.txt
#
# ------------------------------------------------------------
# Notes:
#   • If inside a Git repository, build commands run from project root
#   • Temporary build outputs go to $TMPDIR or /tmp
#   • --watch requires fswatch (macOS) or inotifywait (Linux)

# ---------- Input ----------
if [[ $# -lt 1 ]]; then
	echo 'Usage: run <file> [args...]'
	echo 'args:  [--pwd | --time]'
	exit 1
fi

# ---------- Flags ----------
TIME_MODE=0
COMPILE_ONLY=0
WORKING_DIR=0
DRY_RUN=0
WATCH_MODE=0
RELEASE_MODE=0
ENV_FILE=""
OUT_NAME=""
STDIN_FILE=""
NEW_ARGS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	--time)
		TIME_MODE=1
		;;
	--pwd)
		WORKING_DIR=1
		;;
	--compile-only)
		COMPILE_ONLY=1
		;;
	--dry-run)
		DRY_RUN=1
		;;
	--watch)
		WATCH_MODE=1
		;;
	--release)
		RELEASE_MODE=1
		;;
	--env)
		[[ -z "${2:-}" ]] && { echo "error: --env requires a FILE argument" >&2; exit 1; }
		ENV_FILE="$2"
		shift
		;;
	--out)
		[[ -z "${2:-}" ]] && { echo "error: --out requires a NAME argument" >&2; exit 1; }
		OUT_NAME="$2"
		shift
		;;
	--stdin)
		[[ -z "${2:-}" ]] && { echo "error: --stdin requires a FILE argument" >&2; exit 1; }
		STDIN_FILE="$2"
		shift
		;;
	--help)
		echo 'Usage: run <file> [arguments...] [flags]'
		echo
		echo 'Flags:'
		echo '  --time          Show execution time, CPU usage, and memory usage'
		echo '  --pwd           In compile mode, place the output binary in $PWD'
		echo '  --compile-only  Compile but do not run the output binary'
		echo '  --dry-run       Print the command that would run, without executing'
		echo '  --watch         Re-run automatically whenever the file changes'
		echo '  --release       Compile/run in release/optimised mode (C, C++, Rust, Zig)'
		echo '  --env FILE      Source FILE as a .env before running'
		echo '  --out NAME      Override the output binary name (compile mode only)'
		echo '  --stdin FILE    Feed FILE into the program'"'"'s stdin on launch'
		echo '  --help          Show this help message'
		exit 0
		;;
	*)
		NEW_ARGS+=("$1")
		;;
	esac
	shift
done

FULL_PATH=$(realpath -q "${NEW_ARGS[0]:-}" 2> /dev/null) || {
	echo "file: '${NEW_ARGS[0]:-}' not found" >&2
	echo 'Usage: run <file> [args...]' >&2
	exit 1
}
# Drop the filename from NEW_ARGS; remainder are program arguments.
NEW_ARGS=("${NEW_ARGS[@]:1}")

# ---------- Watch Mode ----------
# Re-invoke this script (minus --watch) on every file change.
# Requires: fswatch (macOS/Linux) or inotifywait (Linux, inotify-tools).
if [[ $WATCH_MODE -eq 1 ]]; then
	# Rebuild argv without --watch so the child invocation is clean.
	WATCH_ARGS=("$FULL_PATH")
	if (( ${#NEW_ARGS[@]} )); then
		WATCH_ARGS+=("${NEW_ARGS[@]}")
	fi
	[[ $TIME_MODE     -eq 1 ]] && WATCH_ARGS+=(--time)
	[[ $COMPILE_ONLY  -eq 1 ]] && WATCH_ARGS+=(--compile-only)
	[[ $DRY_RUN       -eq 1 ]] && WATCH_ARGS+=(--dry-run)
	[[ $RELEASE_MODE  -eq 1 ]] && WATCH_ARGS+=(--release)
	[[ $WORKING_DIR   -eq 1 ]] && WATCH_ARGS+=(--pwd)
	[[ -n "$ENV_FILE"   ]]     && WATCH_ARGS+=(--env   "$ENV_FILE")
	[[ -n "$OUT_NAME"   ]]     && WATCH_ARGS+=(--out   "$OUT_NAME")
	[[ -n "$STDIN_FILE" ]]     && WATCH_ARGS+=(--stdin "$STDIN_FILE")

	SELF="$(realpath "$0")"

	if ! command -v watchexec &> /dev/null; then
		echo "error: --watch requires 'watchexec' (brew install watchexec / cargo install watchexec)" >&2
		exit 1
	fi

	echo "👁  Watching: $FULL_PATH" >&2
	echo "   Press Ctrl-C to stop." >&2
	watchexec --shell=none --watch "$FULL_PATH" "$SELF" "${WATCH_ARGS[@]}"
	exit 0
fi

# ---------- Helpers ----------

# /usr/bin/time flags differ between BSD (macOS) and GNU (Linux).
#   BSD:  -lhp  (-l = memory, -h = human-readable, -p = POSIX output)
#   GNU:  -v    (verbose; includes wall time, CPU, and max RSS)

case "$OSTYPE" in
	linux*)
		TIME_FLAGS=("-v")
		DEFALUT_OPNER=(xdg-open)
		;;
	darwin*)
		TIME_FLAGS=("-lhp")
		DEFALUT_OPNER=(open)
		;;
	*)
		echo "Unknown operating system: $OSTYPE"
		exit 1;
		;;
esac

# Source a .env file: export KEY=VALUE lines, skip comments and blanks.
load_env() {
	local env_file="$1"
	if [[ ! -f "$env_file" ]]; then
		echo "error: --env file not found: '$env_file'" >&2
		exit 1
	fi
	# shellcheck disable=SC2046
	export $(grep -Ev '^\s*(#|$)' "$env_file" | xargs)
}

# run_exec CMD [ARGS...]
#   • Respects DRY_RUN  — prints and returns without running
#   • Respects ENV_FILE — sources it before running
#   • Respects STDIN_FILE — redirects it into stdin
#   • Respects TIME_MODE — wraps with /usr/bin/time and captures its own
#     exit code so the program's exit code is always passed through
run_exec() {
	if [[ $DRY_RUN -eq 1 ]]; then
		echo "❯ (dry-run) $*" >&2
		return 0
	fi

	[[ -n "$ENV_FILE" ]] && load_env "$ENV_FILE"

	local exit_code

	if [[ $TIME_MODE -eq 1 ]]; then
		if [[ -n "$STDIN_FILE" ]]; then
			/usr/bin/time "${TIME_FLAGS[@]}" "$@" < "$STDIN_FILE"
		else
			/usr/bin/time "${TIME_FLAGS[@]}" "$@"
		fi
		# /usr/bin/time exits with the child's exit code on both BSD and GNU,
		# so $? here is already the program's exit code.
		exit_code=$?
		printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
	else
		if [[ -n "$STDIN_FILE" ]]; then
			"$@" < "$STDIN_FILE"
		else
			"$@"
		fi
		exit_code=$?
	fi

	return "$exit_code"
}

# If executable → run directly
if [[ -x $FULL_PATH ]]; then
	echo "▶ Executable file: '$FULL_PATH'" >&2
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
	run_exec "$FULL_PATH"
	exit $?
fi

# If shebang exists, run with it
first_line=$(head -n 1 "$FULL_PATH")
if [[ $first_line == \#!* ]]; then
	read -r -a shebang_parts <<< "${first_line:2}"
	echo "▶ Shebang: ${shebang_parts[*]} '$FULL_PATH'" >&2
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
	MAIN_COMMAND=("${shebang_parts[@]}" "$FULL_PATH")
	run_exec "${MAIN_COMMAND[@]}"
	exit $?
fi

FILE_DIR=$(dirname "$FULL_PATH")
FILE_NAME=$(basename "$FULL_PATH")
FILE_WITHOUT_EXTENSION="${FILE_NAME%.*}"

# ---------- Project Root ----------
GIT_ROOT=$(git -C "$FILE_DIR" rev-parse --show-toplevel 2> /dev/null || true)
PROJ_ROOT="${GIT_ROOT:-$FILE_DIR}"
cd "$PROJ_ROOT"

(( ${#NEW_ARGS[@]} )) && set -- "${NEW_ARGS[@]}"

# ---------- Compile Setup ----------
IS_COMPILE=0
IS_STRIP=0
OUTDIR="${TMPDIR:-/tmp}"
FINAL_OUTPUT_DIR="$OUTDIR"
# Derive a safe name from the filename (dots → dashes), then let --out override it.
FINAL_EXECUTIVE_FILE_NAME=${FILE_NAME//./-}
[[ -n "$OUT_NAME" ]] && FINAL_EXECUTIVE_FILE_NAME="$OUT_NAME"

if [[ $WORKING_DIR -eq 1 ]]; then
	FINAL_OUTPUT_DIR="$PWD"
fi

PRE_COMMAND=()
MAIN_COMMAND=()
POST_COMMAND=()

case "$FULL_PATH" in
*.c)
	if [[ -d 'build-arm64' ]]; then
		MAIN_COMMAND=(cmake --build build)
	elif [[ -d ../build-arm64 ]]; then
		MAIN_COMMAND=(cmake --build ../build)
	else
		IS_COMPILE=1
		MAIN_COMMAND=("${CC:-gcc}" -std=c17 -pedantic -Wall)
		MAIN_COMMAND+=("$CFLAGS" "$LDFLAGS")
		[[ $RELEASE_MODE -eq 1 ]] && MAIN_COMMAND+=(-O2) || MAIN_COMMAND+=(-g)
		MAIN_COMMAND+=("$FULL_PATH" -o "$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.out")
		POST_COMMAND=("$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.out")
	fi
	;;
*.cpp)
	if [[ -d 'build-arm64' ]]; then
		MAIN_COMMAND=(cmake --build build)
	elif [[ -d ../build-arm64 ]]; then
		MAIN_COMMAND=(cmake --build ../build)
	else
		IS_COMPILE=1
		MAIN_COMMAND=("${CXX:-g++}" -std=c++20 -pedantic -Wall)
		MAIN_COMMAND+=("$CPPFLAGS" "$LDFLAGS")
		[[ $RELEASE_MODE -eq 1 ]] && MAIN_COMMAND+=(-O2) || MAIN_COMMAND+=(-g)
		MAIN_COMMAND+=("$FULL_PATH" -o "$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.out")
		POST_COMMAND=("$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.out")
	fi
	;;
*/[Mm]akefile | *.mk)
	MAIN_COMMAND=(make -C "$FILE_DIR" -f "$FULL_PATH")
	;;
*/[Jj]ustfile)
	MAIN_COMMAND=(just -d "$FILE_DIR" -f "$FULL_PATH")
	;;
*/CMakeLists.txt)
	build_dir="$PROJ_ROOT/build/debug"
	MAIN_COMMAND=(cmake -S "$FILE_DIR" -B "$build_dir")
	project_name=$(basename "$FILE_DIR")

	if [[ ! -f "$build_dir/CMakeCache.txt" ]]; then
		MAIN_COMMAND+=(
			-DCMAKE_BUILD_TYPE=Debug
			-DCMAKE_OSX_ARCHITECTURES=arm64
			-DBUILD_SHARED_LIBS=ON
			-DCMAKE_INSTALL_PREFIX="$HOME/.local/dev-tools/$project_name"
		)
	fi
	;;
*.rs)
	if [[ -f Cargo.toml || -f ../Cargo.toml ]]; then
		MAIN_COMMAND=(cargo run)
		[[ $RELEASE_MODE -eq 1 ]] && MAIN_COMMAND+=(--release)
		MAIN_COMMAND+=(--)
	else
		IS_COMPILE=1
		MAIN_COMMAND=(rustc)
		[[ $RELEASE_MODE -eq 1 ]] && MAIN_COMMAND+=(-C opt-level=3)
		MAIN_COMMAND+=("$FULL_PATH" -o "$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.out")
		POST_COMMAND=("$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.out")
	fi
	;;
*.hurl)
	MAIN_COMMAND=(hurl "$FULL_PATH")
	;;
*.md)
	IS_COMPILE=1
	MAIN_COMMAND=(pandoc
		-o "$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.html"
		--defaults=html-github-markdown
		--verbose
		"$FULL_PATH")
	POST_COMMAND=("${DEFALUT_OPNER[@]}" "$FINAL_OUTPUT_DIR/$FINAL_EXECUTIVE_FILE_NAME.html")
	;;
*.1 | *.2 | *.3 | *.4 | *.5 | *.6 | *.7 | *.8 | *.9)
	MAIN_COMMAND=(man "$FULL_PATH")
	;;
*.d2)
	MAIN_COMMAND=(d2
		--watch
		--force-appendix
		--font-mono ~/Library/Fonts/jetbrains_mono-v2.304/fonts/ttf/JetBrainsMono-Regular.ttf
		--check --center --sketch --layout elk --center "$FULL_PATH")
	;;
*.py)
	if [[ -f .python-version && -f pyproject.toml ]]; then
		MAIN_COMMAND=(uv run "$FULL_PATH")
	elif [[ -f ../.python-version && -f ../pyproject.toml ]]; then
		MAIN_COMMAND=(uv run "$FULL_PATH")
	else
		MAIN_COMMAND=(python "$FULL_PATH")
	fi
	;;
*.cal)
	MAIN_COMMAND=(bc -liqf "$FULL_PATH")
	;;
*.go)
	if [[ -f go.mod || -f ../go.mod ]]; then
		MAIN_COMMAND=(go run .)
	else
		MAIN_COMMAND=(go run "$FULL_PATH")
	fi
	;;
*.zig)
	if [[ -f build.zig || -f ../build.zig ]]; then
		MAIN_COMMAND=(zig build run)
		[[ $RELEASE_MODE -eq 1 ]] && MAIN_COMMAND+=(-Doptimize=ReleaseFast)
	else
		MAIN_COMMAND=(zig run)
		[[ $RELEASE_MODE -eq 1 ]] && MAIN_COMMAND+=(-O ReleaseFast)
		MAIN_COMMAND+=("$FULL_PATH")
	fi
	;;
*.lua)
	MAIN_COMMAND=(luajit --  "$FULL_PATH")
	;;
*.cs)
	MAIN_COMMAND=(dotnet run "$FULL_PATH")
	;;
*.java)
	MAIN_COMMAND=(java "$FULL_PATH")
	;;
*.html)
	MAIN_COMMAND=("${DEFALUT_OPNER[@]}" "$FULL_PATH")
	;;
*.js | *.ts)
	MAIN_COMMAND=(bun "$FULL_PATH")
	;;
*.typ)
	IS_COMPILE=1
	MAIN_COMMAND=(typst compile "$FULL_PATH")
	POST_COMMAND=(qlmanage -p -- "$FILE_DIR/$FILE_WITHOUT_EXTENSION.pdf")
	;;
*.rb)
	if [[ -f Gemfile ]]; then
		MAIN_COMMAND=(bundle exec ruby "$FULL_PATH")
	else
		MAIN_COMMAND=(ruby "$FULL_PATH")
	fi
	;;
*.sh | *.bash | *.zsh)
	MAIN_COMMAND=(bash "$FULL_PATH")
	;;
*.sql)
	db="$FILE_DIR/$FILE_WITHOUT_EXTENSION.sqlite3"
	MAIN_COMMAND=(sqlite3 -header -table -bail -nullvalue "-null-" "$db")
	;;
*)
	echo "Unsupported file type: .${FULL_PATH##*.}" >&2
	exit 1;
	;;
esac

# ---------- Non-Compile Execution ----------
if [[ $IS_COMPILE -eq 0 ]]; then
	echo "▶ ${MAIN_COMMAND[*]}" >&2
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
	run_exec "${MAIN_COMMAND[@]}"
	exit $?
fi

# Skip first argument AKA file name
MAIN_COMMAND+=("${@:2}")

# Append any extra user arguments passed after the filename
# cmd+=("$@")

# ---------- Compile Mode ----------
echo "▶ ${MAIN_COMMAND[*]}" >&2
printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
run_exec "${MAIN_COMMAND[@]}"
compile_status=$?

if [[ $COMPILE_ONLY -eq 1 ]]; then # if compile successful
	exit $compile_status
fi

if [[ $IS_STRIP -eq 1 ]]; then
	strip "${POST_COMMAND[0]}" || true
fi

# ---------- Post Compile Mode ----------
if [[ $compile_status -eq 0 && ${#POST_COMMAND[@]} -ne 0 ]]; then
	# printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
	echo "▶ Running: ${POST_COMMAND[*]}" >&2
	run_exec "${POST_COMMAND[@]}"
fi

exit $?
