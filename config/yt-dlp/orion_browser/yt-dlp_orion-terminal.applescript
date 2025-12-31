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
	activate
	set theURL to URL of current tab of first window
end tell

tell application "Terminal"
	activate

	-- Open a new window if none exists
	if not (exists window 1) then
		do script "" -- creates a new window
		delay 0.3
		-- THIS IS THE LINE YOU WANT
		set bounds of front window to {0, 0, 850, 700} -- left, top, left+width, top+height
		--                                            ↑    ↑      ↑        ↑
		--                                        x=100 y=100 width=500 height=700
	end if


	-- Run the yt-dlp command in the frontmost window
	do script "/Users/pritam/.config/yt-dlp/orion_browser/yt-dlp_orion-terminal.sh " & quoted form of theURL in front window
end tell

return "Downloading → opened in Terminal (500×700)"
