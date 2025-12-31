#!/bin/zsh


# =========================================================================================================
# This script is designed to be used with launchctl and performs the following tasks:
# 1. Ensures the 'wireproxy' command is available in the system PATH, as it is critical for execution.
# 2. Confirms the presence of the Wireproxy configuration file in the user's .config directory.
# 3. Locates the most recent WireGuard configuration file in the Downloads folder.
# 4. Validates the WireGuard configuration file to ensure it is still valid and not expired.
# 5. Utilizes macOS's notification and alert systems to provide status updates and error reporting.
# 6. Delivers clear and user-friendly error messages for missing dependencies or files.
# =========================================================================================================


# Function to send a notification using macOS's notification system
notify() {
	local msg="$1"
	local title="${2:-Notification}" # Default title is 'Notification' if not provided
	local type="${3:-info}" # Default type is 'info' if not provided (info | error | log)

	# Check for --help option and display usage instructions
	if [[ $msg == "--help" ]]; then
		echo "Usage: notify <message> [title] [type]"
		echo "  <message>: The notification message to display."
		echo "  [title]:   Optional. The title of the notification. Default is 'Notification'."
		echo "  [type]:    Optional. The type of notification. Can be 'info', 'error', or 'log'. Default is 'info'."
		return 0
	fi

	# Choose the appropriate sound based on the notification type
	local sound="default"
	case "$type" in
	error)
		sound="Basso" # macOS built-in alert sound for errors
		;;
	log)
		sound="Pop" # Subtle sound for log messages
		;;
	info)
		sound="default" # Generic notification sound
		;;
	esac

	# Send the notification using AppleScript
	osascript -e "display notification \"$msg\" with title \"$title\" sound name \"$sound\"" 2 &>/dev/null
}

# Function to display a message using macOS's alert system
message() {
	local msg="$1"
	local title="${2:-Notification}" # Default title is 'Notification' if not provided
	local type="${3:-info}" # Default type is 'info' if not provided

	# Check for --help option and display usage instructions
	if [[ $msg == "--help" ]]; then
		echo "Usage: message <message> [title] [type]"
		echo "  <message>: The notification message to display."
		echo "  [title]:   Optional. The title of the notification. Default is 'Notification'."
		echo "  [type]:    Optional. The type of notification. Can be 'info', 'error', or 'log'. Default is 'info'."
		return 0
	fi

	# Display the appropriate alert based on the type
	case "$type" in
	error)
		osascript -e "display alert \"$title\" message \"$msg\" as critical" 2 &>/dev/null
		;;
	warning)
		osascript -e "display alert \"$title\" message \"$msg\" as warning" 2 &>/dev/null
		;;
	info | *)
		osascript -e "display alert \"$title\" message \"$msg\" as informational" 2 &>/dev/null
		;;
	esac
}

# Check if the 'wireproxy' command is available in the system PATH
if ! command -v wireproxy &>/dev/null; then
	message "wireproxy is not in path" "Launchctl" "error"
	# exit 1
else
	WIREPROXY_BIN=$(command -v wireproxy) # Store the path to the wireproxy binary
fi

# Define the path to the Wireproxy configuration file
WIREPROXY_CONF="$HOME/.config/wireproxy/wireproxy.conf"
if [[ ! -f $WIREPROXY_CONF ]]; then
	message "file not found: $WIREPROXY_CONF" "Launchctl: Wireproxy config" "error"
	return 1
	# exit 1
fi

# Find the latest WireGuard configuration file in the Downloads folder
WIREGUARD_CONFIG=$(find "$HOME/Downloads/" -type f -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-[A-Z][a-z][a-z]-[0-9][0-9].conf' | sort -t '-' -k1,1n -k2,2M -k3,3n | tail -n 1)

# Extract the filename from the full path
WIREGUARD_CONFIG_FILE=$(basename "$WIREGUARD_CONFIG")

# Extract the date from the filename (format: YYYY-MMM-DD)
WIREGUARD_DATE=$(echo "$WIREGUARD_CONFIG_FILE" | grep -oE '^[0-9]{4}-[A-Z][a-z]{2}-[0-9]{2}')

# Convert the extracted date to epoch format for comparison
WIREGUARD_DATE_EPOCH=$(date -j -f "%Y-%b-%d" "$WIREGUARD_DATE" "+%s" 2>/dev/null)

# Get the current date in epoch format
CURRENT_DATE_EPOCH=$(date "+%s")

# Compare the dates to check if the configuration file is expired
if [[ $WIREGUARD_DATE_EPOCH -lt $CURRENT_DATE_EPOCH ]]; then
	message "The WireGuard configuration file '$WIREGUARD_CONFIG_FILE' is expired." "Launchctl: Expired Config" "error"
	return 1
fi

# Check if the WireGuard configuration file exists
if [[ ! -f $WIREGUARD_CONFIG ]]; then
	message "2025-Nov-21.conf In this format in Downloads" "Launchctl: Wireguard config not found" "error"
	# exit 1
fi

# Notify the user that the process is complete
notify "Done"

# ! wireproxy -c "$WIREPROXY_CONF" <we can't pass the as en argument>
