#!/bin/bash
# finder-locate (shim)
# Handles: glob expansion, stdin collection, exit code passthrough
# All Finder/flag logic lives in finder-locate.applescript

set -euo pipefail

APPLESCRIPT="$DOT_FILE/bin_scripts/finder_locate.applescript"


# ── Glob expansion ────────────────────────────────────────────────────────────
# Expand each argument as a glob. If a pattern matches nothing and is not a
# flag, bail with a clear error instead of passing the literal glob string.
expand_args() {
	local expanded=()
	for arg in "$@"; do
		# Pass flags through untouched
		if [[ $arg == -* ]]; then
			expanded+=("$arg")
			continue
		fi
		# Try glob expansion
		local matches=()
		while IFS= read -r -d '' match; do
			matches+=("$match")
		done < <(compgen -G "$arg" -P "" 2>/dev/null | tr '\n' '\0' || true)

		if [[ ${#matches[@]} -eq 0 ]]; then
			# No glob match — pass as-is and let AppleScript report the error
			expanded+=("$arg")
		else
			expanded+=("${matches[@]}")
		fi
	done
	printf '%s\0' "${expanded[@]}"
}

# ── Collect args ──────────────────────────────────────────────────────────────
ARGS=()

# Stdin pipe: read lines, treat each as a path
if [[ ! -t 0 && $# -eq 0 ]]; then
	while IFS= read -r line; do
		[[ -n $line ]] && ARGS+=("$line")
	done
elif [[ $# -gt 0 ]]; then
	# Glob-expand positional args
	while IFS= read -r -d '' arg; do
		ARGS+=("$arg")
	done < <(expand_args "$@")
fi

# ── Invoke AppleScript and relay exit code ────────────────────────────────────
osascript "$APPLESCRIPT" "${ARGS[@]}"
exit $?
