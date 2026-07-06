#!/usr/bin/osascript

-- finder-locate.applescript
-- Usage (via shim):  finder-locate [flags] <file1> [file2 ...]
--                    command | finder-locate [flags]
--
-- Flags:
--   -h, --help        Show this help
--   --new-window      Open a new Finder window instead of reusing the front one
--   -q, --quiet       Reveal without bringing Finder to the front
--   --dry-run         Print resolved paths to stdout, do not open Finder

on run argv
	-- ── Defaults ──────────────────────────────────────────────────────────────
	set newWindow to false
	set quietMode to false
	set dryRun to false
	set filePaths to {}

	-- ── Parse argv ────────────────────────────────────────────────────────────
	set i to 1
	repeat while i ≤ (count of argv)
		set arg to item i of argv as text

		if arg is "-h" or arg is "--help" then
			showHelp()
			return
		else if arg is "--new-window" then
			set newWindow to true
		else if arg is "-q" or arg is "--quiet" then
			set quietMode to true
		else if arg is "--dry-run" then
			set dryRun to true
		else if arg starts with "-" then
			printErr("Unknown flag: '" & arg & "'")
			error "" number 1
		else
			set end of filePaths to arg
		end if

		set i to i + 1
	end repeat

	-- ── Validate we have at least one path ────────────────────────────────────
	if (count of filePaths) is 0 then
		showHelp()
		error "" number -128
	end if

	-- ── Resolve & validate each path ─────────────────────────────────────────
	set fileRefs to {}
	set dryRunLines to ""

	repeat with rawPath in filePaths
		set rawPath to rawPath as text

		-- Resolve symlinks / relative paths / ~
		set resolvedPath to do shell script "realpath -- " & quoted form of rawPath

		-- Existence check
		set doesExist to do shell script "test -e " & quoted form of resolvedPath & " && echo 1 || echo 0"
		if doesExist is "0" then
			printErr("File does not exist: '" & resolvedPath & "'")
			error "" number 1
		end if

		if dryRun then
			-- Accumulate for dry-run output
			if dryRunLines is "" then
				set dryRunLines to resolvedPath
			else
				set dryRunLines to dryRunLines & linefeed & resolvedPath
			end if
		else
			set end of fileRefs to (resolvedPath as POSIX file)
		end if
	end repeat

	-- ── Dry-run: print and exit ───────────────────────────────────────────────
	if dryRun then
		do shell script "echo " & quoted form of dryRunLines
		return
	end if

	-- ── Open Finder window / reveal ───────────────────────────────────────────
	tell application "Finder"
		if newWindow then
			make new Finder window
		end if
		if not quietMode then
			activate
		end if
		reveal fileRefs
	end tell
end run


-- ── Helpers ───────────────────────────────────────────────────────────────────

on showHelp()
	do shell script "echo 'Usage:
  finder-locate [flags] <file1> [file2 ...]
  command | finder-locate [flags]

Flags:
  -h, --help       Show this help
  --new-window     Open a new Finder window instead of reusing the front one
  -q, --quiet      Reveal without bringing Finder to the front
  --dry-run        Print resolved paths, do not open Finder' >&2"
end showHelp

on printErr(msg)
	do shell script "echo " & quoted form of ("finder-locate: " & msg) & " >&2"
end printErr
