#!/bin/bash
set -euo pipefail # Good practice: exit on error, unset vars, and pipe failures

# Colors for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== nnn plugins installer ===${NC}"

# Determine plugins directory (XDG compliant)
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins/personal"
SOURCE="$DOT_FILE/config/nnn/plugins"

echo -e "${YELLOW}→ Target plugins directory:${NC} $PLUGINS_DIR"

# Create directory if it doesn't exist
if mkdir -p "$PLUGINS_DIR" 2>/dev/null; then
	echo -e "${GREEN}✓ Created plugins directory${NC}"
else
	# mkdir -p rarely fails, but just in case
	if [[ -d $PLUGINS_DIR ]]; then
		echo -e "${GREEN}✓ Plugins directory already exists${NC}"
	else
		echo -e "${RED}✗ Failed to create plugins directory: $PLUGINS_DIR${NC}" >&2
		exit 1
	fi
fi

# Check if source plugins exist
if [[ ! -d "$SOURCE" ]]; then
	echo -e "${RED}✗ Error: $SOURCE directory not found in current path!${NC}" >&2
	echo "    Make sure you're running this script from the correct location." >&2
	exit 1
fi

cd "$SOURCE"

find . -maxdepth 1 -print | while IFS= read -r file; do
	filename="${file#./}" # Remove './' prefix

	# Skip "." and ""
	if [[ $filename == "." || -z $filename ]]; then
		continue
	fi

	src_path="$(pwd)/$filename"
	link_path="$PLUGINS_DIR/$filename"

	# Create symbolic link (force overwrite)
	ln -sf "$src_path" "$link_path"
	echo -e "ln -sf: ${RED} $filename ${NC} → ${YELLOW} $link_path ${NC}"
done

echo -e "${BLUE}=== Installation complete ===${NC}"
