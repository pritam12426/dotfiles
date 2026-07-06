#!/usr/bin/env bash

set -euo pipefail

LIBROOT="/usr/local/big_library/libtorch-2.7.0/lib"
LIBOMP="$LIBROOT/libomp.dylib"

echo ">>> Using library directory: $LIBROOT"

# Ensure libomp exists
if [[ ! -f $LIBOMP ]]; then
	echo "Error: Expected libomp at $LIBOMP"
	exit 1
fi

# Loop through all .dylib files
for dylib in "$LIBROOT"/*.dylib; do
	echo "=============================="
	echo "Processing: $dylib"
	echo "=============================="

	# List dependencies
	otool -L "$dylib" | while read -r dep _; do

		# --- RULE 1: Replace external libomp ---
		if [[ $dep == "/opt/homebrew/opt/libomp/lib/libomp.dylib" ]]; then
			echo "  • Fixing libomp for $dylib"
			sudo install_name_tool \
				-change "/opt/homebrew/opt/libomp/lib/libomp.dylib" \
				"$LIBOMP" \
				"$dylib"
		fi

		# --- RULE 2: Replace @rpath/libXYZ.dylib with absolute path ---
		if [[ $dep == @rpath/*.dylib ]]; then
			base=$(basename "$dep")
			target="$LIBROOT/$base"

			if [[ -f $target ]]; then
				echo "  • Fixing @rpath: $dep → $target"
				sudo install_name_tool \
					-change "$dep" "$target" "$dylib"
			else
				echo "  • WARNING: No local file found for $dep"
			fi
		fi

	done
done

echo ">>> All libraries patched successfully!"
