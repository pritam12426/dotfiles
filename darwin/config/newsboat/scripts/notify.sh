#!/usr/bin/env bash

# file: ~/.config/newsboat/notify.sh

msg="$*"

[[ -z $msg ]] && exit 0

# Escape for AppleScript
msg=${msg//\\/\\\\}
msg=${msg//\"/\\\"}

# macOS only
osascript -e "display notification \"$msg\" with title \"Newsboat\" sound name \"default\""
