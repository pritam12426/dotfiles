#!/bin/bash

notify() {
	local msg="$1"
	local title="${2:-Notification}"
	local type="${3:-info}" # info | error | log

	# Choose sound based on type
	local sound="default"
	case "$type" in
	error)
		sound="Basso"
		;; # macOS built-in alert
	log)
		sound="Pop"
		;; # subtle sound
	info)
		sound="default"
		;; # generic notification
	esac

	# Send notification
	osascript -e "display notification \"$msg\" with title \"$title\" sound name \"$sound\"" 2&>/dev/null
}

message() {
	local msg="$1"
	local title="${2:-Notification}"
	local type="${3:-info}"

	case "$type" in
	error)
		osascript -e "display alert \"$title\" message \"$msg\" as critical" 2&>/dev/null
		;;
	warning)
		osascript -e "display alert \"$title\" message \"$msg\" as warning" 2&>/dev/null
		;;
	info | *)
		osascript -e "display alert \"$title\" message \"$msg\" as informational" 2&>/dev/null
		;;
	esac
}

# Robust version with proper error handling
read -r -d '' AppleStripfileFolderSelect <<'EOF'
on run
    try
        tell application "Finder"
            -- Ensure there's an active Finder window or selection
            if (count of windows) = 0 then
                return "ERROR: No Finder window open"
            end if

            set selectedItems to selection
            if selectedItems is {} or (count of selectedItems) = 0 then
                return "ERROR: Nothing selected in Finder"
            end if
        end tell

        set thePaths to {}
        repeat with anItem in selectedItems
            try
                set thePath to POSIX path of (anItem as alias)
                set end of thePaths to thePath
            on error errMsg number errNum
                -- Skip problematic items but continue processing others
                -- Optionally log the error if needed
                log "Skipped item: " & (errMsg as text)
            end try
        end repeat

        if (count of thePaths) = 0 then
            return "ERROR: No valid files or folders selected"
        end if

        -- Join paths with newline for easy parsing in bash
        set {oldTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, linefeed}
        set output to thePaths as text
        set AppleScript's text item delimiters to oldTID
        return output

    on error errMsg number errNum
        -- Catch-all for any unexpected error
        return "ERROR: " & errMsg & " (error " & errNum & ")"
    end try
end run
EOF

read -r -d '' AppleStripSelectedFormat <<'EOF'
on run
    try
        set chosen to choose from list {"tar", "tar.gz", "tar.bz2", "tar.xz", "zip"} ¬
            with title "Archive Format" ¬
            with prompt "Please select the desired archive format:" ¬
            default items {"tar"} ¬
            OK button name "Continue" ¬
            cancel button name "Cancel" ¬
            multiple selections allowed false ¬
            empty selection allowed false

        -- User pressed Cancel or closed the dialog
        if chosen is false or chosen is {} then
            return "CANCELED"
        end if

        -- Successfully selected
        return item 1 of chosen as text

    on error errMsg number errNum
        -- -128 = User canceled (standard AppleScript cancel error)
        -- -1711 = Script execution error (very rare here)
        if errNum is -128 then
            return "CANCELED"
        else
            -- Any other unexpected error
            return "ERROR: " & errMsg & " (code " & errNum & ")"
        end if
    end try
end run
EOF

# === Get selected files/folders from Finder ===
result=$(osascript -e "$AppleStripfileFolderSelect" 2&>/dev/null)

# --- Error handling ---
if [[ $result == ERROR:* ]]; then
	notify "Selection failed" "${result#ERROR: }" "error"
	exit 1
elif [[ -z $result ]]; then
	message "No items selected" "Nothing was selected in Finder or all items failed." "error"
	exit 1
fi

# --- Convert newline-separated paths → bash array ---
IFS=$'\n' read -r -d '' -a files <<<"$result"

# --- Final output: each path wrapped in <path> and printed one per line ---
if ((${#files[@]} > 0)); then
	printf '"%s"\n' "${files[@]}"
else
	message "No valid paths" "Something went wrong during path extraction." "error"
	exit 1
fi

# Execute and capture result
selected_format=$(osascript -e "$AppleStripSelectedFormat")

case "$selected_format" in
"CANCELED")
	# notify "Canceled the format selection" "" "Error"
	message "Canceled the format selection" "" "Error"
	# echo "User canceled the format selection." >&2
	exit 1
	;;
"ERROR:"*)
	# message "AppleScript error" "${format#ERROR: }" "error"
	echo "AppleScript error: ${selected_format#ERROR: }" >&2
	exit 1
	;;
"tar" | "tar.gz" | "tar.bz2" | "tar.xz" | "zip")
	echo "Selected format: $selected_format"
	# Continue with your archiving logic
	;;
*)
	# Fallback (should never happen with proper script)
	echo "Invalid or empty response from dialog." >&2
	exit 1
	;;
esac

# Ask about password (only for ZIP)
want_password="no"
if [[ $selected_format == "zip" ]]; then
	if zenity --question --title="Password Protection" \
		--text="Do you want to password-protect the archive?\n(Only works with ZIP)"; then
		want_password="yes"
		echo $want_password
	fi

	if [[ $want_password == "yes" ]]; then
		password=$(zenity --password --title="Enter Password")
		[[ -z $password ]] && {
			message "Empty password" "" "error"
			exit 1
		}
		confirm=$(zenity --password --title="Confirm Password")
		[[ $password != "$confirm" ]] && {
			message "Passwords don't match" "" "error"
			exit 1
		}
	fi
fi

# Step 4: Save as
default_name="archive.$selected_format"
output_file=$(zenity --file-selection --save \
	--confirm-overwrite \
	--title="Save Archive As" \
	--filename="$default_name")

[[ -z $output_file ]] && {
	message "No output file chosen" "" "error"
	exit 1
}

# Step 5: Create archive with progress bar
(
	echo "10"
	echo "# Creating $selected_format archive..."

	# Build argument array instead of string → completely safe
	args=()

	case "$selected_format" in
		tar)
			args+=(-cf "$output_file") ;;
		tar.gz)
			args+=(-czf "$output_file") ;;
		tar.bz2)
			args+=(-cjf "$output_file") ;;
		tar.xz)
			args+=(-cJf "$output_file") ;;

		zip)
			if [[ -n $password ]]; then
				# macOS built-in zip with password
				echo "50"
				echo "# Adding password protection..."
				# We'll handle zip separately below
			else
				args+=(-j "$output_file")
			fi
			;;
	esac

	# Actually run the command safely
	if [[ $selected_format == "zip" && -n $password ]]; then
		# Special case: password-protected ZIP using built-in zip
		printf '%s\n%s\n' "$password" "$password" | zip -e -j "$output_file" "${files[@]}"
		# printf '%s\n%s\n' "$password" "$password" | zip -e -j "$output_file" "${files[@]}" 2&>/dev/null
	elif [[ $selected_format == "zip" ]]; then
		# zip -j "$output_file" "${files[@]}" 2&>/dev/null
		zip -j "$output_file" "${files[@]}"
	else
		# All tar formats — use built-in tar (always available)
		tar "${args[@]}" "${files[@]}"
	fi

	echo "100"
	echo "# Archive created successfully!"
) | zenity --progress --auto-close --title="Creating Archive..." --width=400 --text="Preparing..."

# Success message
[[ ${PIPESTATUS[1]} -eq 0 ]] &&
	notify "Archive created" "$output_file" "info" ||
	notify "Failed to create archive" "$output_file" "error"
exit $?


# Now you can safely use the ${files[@]} array
# Example:
# for file in "${files[@]}"; do
# 	echo "Processing: $file"
# done


# zip -r -P yourpassword archive_name.zip folder_name
