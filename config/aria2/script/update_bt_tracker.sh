#!/bin/bash

set -e

ORIGINAL_CONFIG_FILE="$HOME/.config/aria2/aria2-launchctl.conf"
ARIA2_CONF_LAUNCHCTL="$HOME/.config/aria2/__aria2-launchctl-with-BtTracker.conf"

# Copy original config
cp -p "$ORIGINAL_CONFIG_FILE" "$ARIA2_CONF_LAUNCHCTL"

# Fetch trackers
LIST1=$(curl -fsSL "https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/all_aria2.txt")
LIST2=$(curl -fsSL "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt")

# Merge + cleanup (remove newlines & duplicate commas)
TRACKERS="$LIST1,$(echo "$LIST2" | tr '\n' ',' | sed 's/,,*/,/g;s/,$//')"
# TRACKERS=$(echo "$TRACKERS" | sed 's/,,*/,/g;s/,$//')

# Update bt-tracker entry (working on macOS & Linux)
echo "🔧 Updating $ARIA2_CONF_LAUNCHCTL ..."

BT_CONFIG_HEAD=$(cat <<EOF



# Load additional BitTorrent trackers from external file =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
bt-tracker=$TRACKERS
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
EOF
)

# echo "$BT_CONFIG_HEAD" >> "$ARIA2_CONF_LAUNCHCTL"

echo "🎉 Trackers updated successfully!"
echo "📌 Saved to: $ARIA2_CONF_LAUNCHCTL"


# arai2c is running
if pgrep -x aria2c > /dev/null; then
	printf "aria2 is already running (PID: %d) Reload? (y/n): " "$(pgrep -x aria2c)"
	read -r choice
	echo
	case "$choice" in
			([yY])
				launchctl unload ~/Library/LaunchAgents/com.user.aria2.plist
				launchctl load ~/Library/LaunchAgents/com.user.aria2.plist
				echo "🔄 aria2 reloaded successfully."
				;;
			([nN])
				exit 0
				;;
	esac
else
	printf "Start aria2 server (y/n): "
	read -r choice
	echo
	case "$choice" in
			([yY])
				launchctl load ~/Library/LaunchAgents/com.user.aria2.plist
				echo "✅ aria2 started successfully."
				;;
	esac
fi
