#!/usr/bin/osascript

-- ================== about this script ==================
-- Date created: Sat Nov 29-2025 02:30:00 AM
-- User: Pritam <84720825+pritam12426@users.noreply.github.com>
-- Orion browser version: 1.0.0
-- yt-dlp: version 2025.11.12
-- aria2c: version 1.37.0

-- Purpose: Open Terminal and run yt-dlp command with the current tab URL from Orion browser.
-- This script is designed to be used as an Orion browser script.
-- It retrieves the URL of the current tab and opens Terminal to run a yt-dlp command.
-- Make sure to adjust the path to your yt-dlp script as needed.
-- ========================================================

tell application "Orion"
	set theURL to URL of current tab of front window
end tell

try
	log "yt-dlp started → " & theURL
	do shell script "/Users/pritam/.config/yt-dlp/orion_browser/yt-dlp_with_orion_browser.sh " & quoted form of theURL
	log "yt-dlp done → " & theURL
on error errMsg
	return "Failed: " & errMsg
end try
