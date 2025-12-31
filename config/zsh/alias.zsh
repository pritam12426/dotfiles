# printf "Importing \t %s \n" "$HOME/.config/zsh/alias.zsh"

[[ $- != *i* ]] && return

# --- Fix Apple verification issue for certain libraries ---
# Uncomment and use the following command to fix the "Apple could not verify" issue for specific libraries.
# sudo install_name_tool -change @rpath/libglfw.3.dylib \
# /usr/local/big_library/glfw-3.4/lib/libglfw.3.4.dylib

# --- General utility commands ---
# Use gpg for encryption
# gpg -c           # quick encryption with temp password
# gpg  --encrypt --recipient <email>   <file>
# gpg --decrypt  <file>

# gpg  -er                   <email>   <file>
# gpg -d  <file>


# Use sips for working with image metadata
# sips -g all

# --- Remove quarantine attribute from files ---
# Use this command to remove the quarantine attribute from a file.
# sudo xattr -rd com.apple.quarantine <file>


# --- HOMEBREW ---------------------
alias bup='brew update && brew upgrade && brew cleanup --prune=all -s'  # Update installed Homebrew formulae
alias blc='brew livecheck -q --newer-only --tap alhadis/troff'          # Run livecheck for `alhadis/troff` tap
# Display information about Homebrew formulae
alias bino='brew info'
alias bi='brew install'
alias bd='brew desc'

# --- Directory navigation aliases ---
alias lldir="cd \` sk < $CPP_LIB_DIR/index.txt \`"     # Navigate To Directory From Index File
alias cpdir="cd ~/Developer/cxx_lang"                  # Navigate To C++ Development Directory
alias cdir="cd ~/Developer/c_lang"                     # Navigate To C Development Directory
alias godir="cd ~/Developer/go_lang"                   # Navigate To C Development Directory
alias rdir="cd ~/Developer/rust_lang"                  # Navigate To C Development Directory
alias gdir="cd ~/Developer/git_repository"             # Navigate To Git Repository Directory
alias bdir="cd ~/.local/bin"                           # Navigate To Local Binaries Directory
alias bdir="cd ~/.local/bin"                           # Navigate To Local Binaries Directory
alias .dir="cd $DOT_FILE"                              # Navigate To your dotfiles Directory

# --- Firefox aliases ---
# alias firefox="open -a /Applications/Firefox.app"   # Launch Firefox
alias firefox="/Applications/Firefox.app/Contents/MacOS/firefox"
alias firefox-p="firefox --private-window"          # Launch Firefox in private mode

alias firefox-clean="rm -fv ~/Library/Application\ Support/Firefox/Profiles/*/formhistory.sqlite ; \
					 rm -fv ~/Library/Application\ Support/Firefox/Profiles/*/formhistory.dat"
# ----------------------------------------------------------


# ------------ LS and File Management Aliases ------------
# Enable colorized output for common commands
alias ls="ls --color=auto -GFh"
alias grep="grep -i --color=auto"
alias fgrep="fgrep -i --color=auto"
alias egrep="egrep -i --color=auto"
alias rsync="rsync -vrPlu"

# Common ls shortcuts
alias ll="ls -l"                       # List with human-readable sizes
alias la="ls -A"                       # List all files, excluding . and ..
alias l="ls -lA"                       # Detailed list including hidden files
alias lh="ls -ld --color=auto .[^.]*"  # List hidden directories

# File operation aliases with safety prompts
alias cp="cp -ip"        # Copy with interactive prompt
alias mv="mv -vi"        # Move with interactive prompt
alias du="du -hs"        # Display disk usage in human-readable format
alias bc="bc --quiet -l" # The command like cal Calculator
alias df='df -h'
alias scp='scp -pr'
alias nl='nl -ba'
# ---------------------------------------------------------


# ------------ NeoVim and System Aliases ------------
# Shortcuts for editing configuration files
alias enrc="$EDITOR ~/.config/nvim/init.lua"          # Edit NeoVim config
alias enhc="$EDITOR ~/.config/helix/config.toml"      # Edit helix config
alias eza="$EDITOR  ~/.config/zsh/alias.zsh"          # Edit alias file
alias efz="$EDITOR  ~/.config/zsh/functions.sh"       # Edit functon file
alias .e="edot"                                       # Edit functon file
# ---------------------------------------------------------

# Generate nicer-looking hexadecimal dumps
alias hexdump='hexdump -v \
	-e \""[2m│[22m0x%08.8_ax[2m│[22m "\" \
	-e '\''16/1 "%02X "'\'' \
	-e \"" [2m│[22m"\" \
	-e '\''16/1 "%_p" "'\''"[2m│[22m"'\''\n"'\'


alias umount="diskutil unmount"                     # Apple recommend diskutil(1) be used instead of umount(1)
alias unquarantine="xattr -rd com.apple.quarantine" # Remove annoying extended attributes added to downloads

alias typecode='GetFileInfo -t'    # Print 4-character creator/type codes
alias creatorcode='GetFileInfo -c' # Print 4-character creator/type codes

# Resize Terminal.app to fill the screen
alias fit='printf '\''\e[3;0;0t\e[4;0;9999t'\'
alias FIT='for i in /dev/ttys???; do fit > "$i"; done'

# System utility aliases ------------------------------
alias o="open ."                                                                           # Open current directory in Finder
alias c.="code ."                                                                          # Open current directory in VS Code
alias z.="zed ."                                                                           # Open current directory in Zed editor
alias sqldump='sqlite3 /dev/stdin .dump <'                                                 # Dump an SQLite database in human-readable form
alias prune='find -L . -name . -o -type d -prune -o -type l -exec rm -v {} +'              # Delete broken symlinks in the current directory
alias hardlinks='find . \! -type d \! -links 1'                                            # List files with at least one hard-link
alias xxd='NO_COLOR=1 xxd -u -g1'                                                          # Generate nicer-looking hexadecimal dumps
alias peek="qlmanage -p >/dev/null 2>&1  -- "                                              # Preview a file using Quick Look
alias pow="pmset -g batt" 	                                                               # Print power diagnostics (battery-level and charge status)
alias tree="tree -a --noreport"                                                            # Hide summary lines in tree(1) output
alias bush='tree -spugDF --metafirst --timefmt="%Y-%m-%d %T"'
# alias live-server="open 'http://localhost:8085/' && python3 -m http.server 8085"           # Start live server with python
alias live-server="live-server -H localhost -p 8085 -o"                                    # Start live server with rust binary
# alias tre="tre -a -E '.git'"                                                               # Display directory tree
# alias python="python3 -u"                                                                  # Use Python 3 as default
alias envpath="envpath | less"                                                             # Print the environment variable in prettiest form
alias nq="networkquality -s"                                                               # Check network quality
alias search="command ls -AF | grep -i"                                                    # Search files in current directory
alias sayy="pbpaste | command say -i"                                                      # Convert clipboard text to speech
alias per="find . -type f -exec chmod 644 {} \; ; find . -type d -exec chmod 755 {} \;"    # Fix permissions
alias seelog="tail -n 1 -f --"                                                             # Tail logs
alias exportlib="source $LIBS_DIR/env"                                                     # Load library environment
alias bsdtar="bsdtar --acls --fflags --xattrs --mac-metadata"                              # Archive macOS-specific filesystem attributes
alias zzz="bsdtar -vxf"                                                                    # Extract archives
alias exportembdlib="source $DOT_FILE/../global/embedded/embedded-ENV.sh"                  # Load embedded environment
alias ninja-tree="ninja -t targets"                                                        # Display Ninja build targets
alias chownroot="sudo chown -R root:wheel"                                                 # Change ownership to root
alias chownself="sudo chown -R pritam:staff"                                               # Change ownership to user
alias bk="open 'http://localhost:8080/' && shiori server"                                  # Open bookmarks server
alias wget="wget --xattr -c"                                                               # Download with wget
alias off="pmset displaysleepnow"                                                          # Turn off display
alias soff="pmset sleepnow"                                                                # Put system to sleep
alias zed-editor="eval \"export EDITOR='zed --wait'\""                                     # setting EDITOR = zed
alias gui-rclone="rclone rcd --rc-web-gui --rc-no-auth"                                    # configure our rclone with webui
#alias gui-docker=""                                                                        # configure our docker with webui
alias eget="eget --download-only "                                                         # Tell eget to only download the System wise release zip file
alias find-zombies="ps -axo pid,ppid,stat,command | grep -w Z+"                            # Find zombies + parent PID
alias aria2="aria2c --dir . --summary-interval=10"                                         # aria2c download file in $PWD
alias agg="agg -v --idle-time-limit 0.7 --fps-cap 30 --font-size 20 --font-family 'JetBrains Mono'"

alias reload-aria2c="launchctl unload ~/Library/LaunchAgents/com.user.aria2.plist &&
				    launchctl load ~/Library/LaunchAgents/com.user.aria2.plist"
# --------------------------------------------------

# ------------ EXIFTool Aliases ------------
alias exf="exiftool -sort -P -overwrite_original_in_place" # Modify metadata
alias exfcpy="exf -TagsFromFile"                           # Copy metadata from another file
alias stripmeta='exiftool -All= -overwrite_original'
# alias x='exiftool -a -U'
# alias X='x -b -X'
# ============================================================================================================

# IP and MAC Address Aliases =================================================================================
# Fetch public IP information
alias ipinfo="curl https://raw.githubusercontent.com/jarun/nnn/master/plugins/ipinfo 2> /dev/null | sh | less"

# Fetch WAN (public) IP address
alias myip="curl -s http://checkip.dyndns.org/ | sed 's/[a-zA-Z<>/ :]//g'"

# Fetch LAN (local) IP address
alias lanip="ipconfig getifaddr en0"
# ============================================================================================================
