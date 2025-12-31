#!/bin/bash

# Function to display port information
display_port_info() {
	local port=$1
	local description=$2
	echo -e "\033[1;36m==> [ \033[1;33mWireproxy $description: \033[1;35m :$port \033[1;36m ] <==\033[0m"
	lsof -i :$port
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
}

# Display information for each port
display_port_info 9080 "HEALTH_ENDPOINT"
display_port_info 1080 "socket"
display_port_info 8080 "HTTP"

# Define the health status endpoint
HEALTH_ENDPOINT="127.0.0.1:9080"

# Check if the server is running
if curl --silent --fail "$HEALTH_ENDPOINT" >/dev/null; then
	echo "Wireproxy server is running successfully."
elif lsof -i :9080 | grep -q "LISTEN"; then
	echo "Wireproxy server is running (based on lsof)."
else
	echo "Wireproxy server is NOT running."
	exit 1
fi
