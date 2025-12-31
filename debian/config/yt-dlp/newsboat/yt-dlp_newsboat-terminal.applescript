#!/usr/bin/osascript


-- ================== about this script ==================
-- Date created: Wed Jan 07-2026 02:69:00 AM
-- User: Pritam <84720825+pritam12426@users.noreply.github.com>
-- Newsboat version: 2.42.0
-- yt-dlp: version 2025.11.12
-- aria2c: version 1.37.0

-- Purpose: Open Terminal and run yt-dlp command with the current open RSS feed URL from Newsboat.
-- This script is designed to be used as an Newsboat script.
-- It retrieves the URL of the current tab and opens Terminal to run a yt-dlp command.
-- Make sure to adjust the path to your yt-dlp script as needed.
-- ========================================================


on run argv
	if (count of argv) < 1 then
		return "Error: No URL provided"
	end if

	-- Your code here, same as above
	set theURL to item 1 of argv

	tell application "Terminal"
		activate

		-- This forces a NEW window every time
		do script "" -- creates a new window
		delay 0.3
		-- THIS IS THE LINE YOU WANT
		set bounds of front window to {0, 0, 850, 700} -- left, top, left+width, top+height
		--                                                 ↑    ↑      ↑        ↑
		--                                              x=100 y=100 width=500 height=700


		-- Run the yt-dlp command in the frontmost window
		do script "/Users/pritam/.config/yt-dlp/newsboat/yt-dlp_newsboat-terminal.sh " & quoted form of theURL in front window
	end tell

	return "Downloading → opened in Terminal (500×700)"
end run
