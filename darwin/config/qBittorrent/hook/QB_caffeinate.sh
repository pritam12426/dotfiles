#!/bin/sh

# file: ~/.config/qBittorrent/hook/start_caffeinate.sh

DOT_FILE="$HOME/Developer/git_repository/dotfiles/darwin"

case "$1" in
--start)
	# Get qbittorrent PID
	QB_PID="$(pgrep -x qbittorrent)"

	if [ -z "$QB_PID" ]; then
		echo "qBittorrent is not running."
		exit 1
	fi

	# If previous caffeinate exists → kill it
	if pgrep -f /usr/bin/caffeinate >/dev/null 2>&1; then
		echo "Caffeinate is running ..."
		exit 0
	fi

	echo "Starting caffeinate for QB PID $QB_PID"

	# Start new caffeinate
	caffeinate -iw "$QB_PID" &
	;;
--kill)
	"$DOT_FILE/bin_scripts/notify.sh" "Done" "QBittorrent"
	exit 0;
	if pkill -f /usr/bin/caffeinate 2> /dev/null; then
		echo "Killed caffeinate (PID $CAFF_PID)"
		rm -f "$PID_FILE"
	else
		"$DOT_FILE/bin_scripts/message.sh" "Failed to kill caffeinate process or already dead." "QBittorrent" "error"
	fi
	;;
*)
	echo "Usage: $0 --start | --kill"
	exit 1
	;;
esac
