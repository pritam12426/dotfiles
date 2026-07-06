# btop Themes Installer

This folder contains a script to download themes for the `btop` application from the official GitHub repository.

## Script: `installTheme.zsh`

### Overview
The `installTheme.zsh` script automates the process of downloading themes for `btop`. It fetches the themes from the `aristocratos/btop` GitHub repository and saves them locally in the `themes` directory.

### Features
- **Recursive Download**: Downloads all files and subdirectories from the `themes` directory in the repository.
- **Automatic Directory Creation**: Ensures the local directory structure matches the repository's structure.
- **Simple Execution**: Requires minimal user input; just run the script.

### Prerequisites
Ensure the following tools are installed on your system:
- `zsh`: The script is written in Zsh.
- `curl`: Used for making HTTP requests.
- `jq`: Used for parsing JSON responses.

### Usage
1. Open a terminal and navigate to this folder.
2. Run the script:
   ```zsh
   ./installTheme.zsh
