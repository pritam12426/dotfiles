# `yt-dlp` Scripts for Orion Browser

This setup integrates `yt-dlp` with the Orion browser on macOS, allowing you to trigger video/audio downloads from the current browser tab using custom scripts.

There are two main ways to use this integration:
1.  **With a Terminal window**: A script that opens a new Terminal window to show the download progress.
2.  **In the background**: A script that runs the download in the background and uses system notifications to show progress.

## Prerequisites

Before you begin, ensure you have the following installed:

1.  **Orion Browser**: A WebKit-based browser for macOS.
2.  **Homebrew**: A package manager for macOS. If you don't have it, you can install it from [brew.sh](https://brew.sh/).
3.  **`yt-dlp`**: A command-line program to download videos from YouTube and other sites.
4.  **`aria2c`**: A command-line download utility used by `yt-dlp` for faster downloads.
5.  **A custom `yt-dlp` wrapper script**: The provided shell scripts use custom, non-standard flags (e.g., `--pList`, `--st`, `--savan`, `--ysong`). You must have a wrapper script for `yt-dlp` that can interpret these flags. This wrapper should be placed in a directory that is in your system's `PATH`, for example `~/.local/bin/yt-dlp`.

You can install `yt-dlp` and `aria2c` using Homebrew:
```sh
brew install yt-dlp aria2c
```

## Files

This configuration consists of four files:

*   `yt-dlp_orion-terminal.applescript`: An AppleScript that gets the current URL from Orion and executes the corresponding shell script in a new Terminal window.
*   `yt-dlp_orion-terminal.sh`: The shell script that constructs and runs the `yt-dlp` command for the "Terminal window" method.
*   `yt-dlp_with_orion_browser.applescript`: An AppleScript that gets the current URL from Orion and executes the corresponding shell script in the background.
*   `yt-dlp_with_orion_browser.sh`: The shell script that constructs and runs the `yt-dlp` command for the "background" method. It also sends notifications to the user.

## Setup Instructions

1.  **Place the script files**:
    *   Copy all four script files to a directory on your system. A good location is `~/.config/yt-dlp/orion_browser/`. If you choose a different location, you **must** update the hardcoded paths in the `.applescript` files.
    *   The current hardcoded path is `/Users/pritam/.config/yt-dlp/orion_browser/`. You will need to change `pritam` to your username.

2.  **Update AppleScript paths (if necessary)**:
    *   If you placed the scripts in a different directory, open both `yt-dlp_orion-terminal.applescript` and `yt-dlp_with_orion_browser.applescript` and update the path to the corresponding `.sh` file.

3.  **Make shell scripts executable**:
    *   Open your Terminal, navigate to the directory where you placed the scripts, and run:
        ```sh
        chmod +x yt-dlp_orion-terminal.sh yt-dlp_with_orion_browser.sh
        ```

4.  **Set up your custom `yt-dlp` wrapper script**:
    *   Make sure your custom `yt-dlp` wrapper script is located at `~/.local/bin/yt-dlp` and is executable. The scripts in this repository rely on this wrapper to handle custom flags.

5.  **Add scripts to Orion Browser**:
    *   Orion Browser allows you to run scripts from its menu.
    *   Open Orion, go to `Tools > Show User Scripts Folder`.
    *   Copy the two `.applescript` files into this folder.
    *   You should now see the scripts in the `Tools` menu in Orion.

## Usage

1.  Navigate to a webpage in Orion from which you want to download content.
2.  Go to the `Tools` menu in Orion.
3.  Choose one of the scripts:
    *   **`yt-dlp_orion-terminal`**: This will open a new Terminal window and you will see the `yt-dlp` output and progress there.
    *   **`yt-dlp_with_orion_browser`**: This will start the download in the background. You will receive a system notification when the download starts and when it completes. Check the log file at `~/.local/share/yt-dlp/orion_broser.log` for details and errors.

**Note**: The background script (`yt-dlp_with_orion_browser.sh`) intentionally disallows downloads of standard YouTube videos and playlists, as per its implementation. It is intended for specific content types like YouTube Shorts, Instagram posts, JioSaavn, and YouTube Music. The Terminal version is more general-purpose.
