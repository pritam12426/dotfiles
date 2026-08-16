# printf "Importing \t %s \n" "$HOME/.config/zsh/alias.zsh"

[[ $- != *i* ]]  &&  return


# ============================================================================
# HOMEBREW
# ============================================================================
alias b='brew'
alias bup='b update  &&  b upgrade  &&  b cleanup --prune=all -s'  # Update installed Homebrew formulae
alias bclean='b cleanup --prune=all -s'                        # clean the catch data of brew
alias blc='b livecheck -q --newer-only --tap alhadis/troff'    # Run livecheck for `alhadis/troff` tap
alias bi='b install  --verbose'
alias bei='b reinstall  --verbose'
alias brm='b remove  --verbose'
alias bd='b desc'
alias bl='b leaves'
alias bs='b search'
alias bdtree='b deps --tree'
alias bino='b info'
alias buses='b uses --installed'

alias binup='bin update -ayc'


# ============================================================================
# DIRECTORY NAVIGATION
# ============================================================================
alias lldir='cd $(sk --prompt="Library > " --height=40% < $CPP_LIB_DIR/index.txt)'     # Navigate To Directory From Index File
alias cpdir='cd ~/Developer/cxx_lang'                  # Navigate To C++ Development Directory
alias cdir='cd ~/Developer/c_lang'                     # Navigate To C Development Directory
alias zgdir='cd ~/Developer/zig'                       # Navigate To zig Development Directory
alias godir='cd ~/Developer/go_lang'                   # Navigate To go Development Directory
alias rdir='cd ~/Developer/rust_lang'                  # Navigate To rust Development Directory
alias pydir='cd ~/Developer/python_lang'               # Navigate To python Development Directory
alias rbdir='cd ~/Developer/ruby_lang'                 # Navigate To ruby Development Directory
alias gdir='cd ~/Developer/git_repository'             # Navigate To Git Repository Directory
alias bdir='cd ~/.local/bin'                           # Navigate To Local Binaries Directory
alias zdir='cd ~/.config/zsh'                          # Navigate To zsh config Directory
alias bkdir='cd ~/.local/share/bookmarks'              # Navigate To bookmarks  Directory
alias .dir='cd $DOT_FILE'                              # Navigate To your dotfiles Directory
alias .con='cd ~/.config'                              # Navigate To your local config Directory


# ============================================================================
# DOCUMENTATION / REFERENCE LINKS
# ============================================================================
# https://github.com/PeterFeicht/cppreference-doc/releases/
# https://en.cppreference.com/Cppreference:Archives
alias cppref='open ~/.local/share/cppreference-2025/reference/en/cpp.html'
alias cref='open ~/.local/share/cppreference-2025/reference/en/c.html'
alias devdoc='open https://devdocs.io/offline'
alias dis='open https://discord.com/app'

# https://github.com/jeaye/stdman
alias cppman='man -M "$HOME/.local/share/cppreference_man_page/share/man" 3'


# ============================================================================
# FIREFOX
# ============================================================================
# alias firefox='exec /Applications/Firefox.app/Contents/MacOS/firefox'
# alias firefox='open -a /Applications/Firefox.app'   # Launch Firefox
alias firefox-p='firefox --private-window'         # Launch Firefox in private mode


# ============================================================================
# LS AND FILE MANAGEMENT
# ============================================================================
# Enable colorized output for common commands
alias grep='grep -iI --color=auto'
alias fgrep='fgrep -iI --color=auto'
alias egrep='egrep -iI --color=auto'
alias diff='diff --color=auto'
alias rsync='rsync -vrPlu'
alias rclone='rclone -vP'
alias which='which -a'
alias rg='grep --exclude-dir={.git,venv,node_modules,build} -rn'
# alias rg='grep --exclude-dir={.git,venv,node_modules,build} --color=auto -iIrnE'
# alias which_all='type -a'

# Common ls shortcuts
alias ls='ls --color=auto -GFh'
alias ll='ls -l'                       # List with human-readable sizes
alias la='ls -A'                       # List all files, excluding . and ..
alias l='ls -lA'                       # Detailed list including hidden files
alias lh='ls -ld --color=auto .[^.]*'  # List hidden directories

# File operation aliases with safety prompts
alias cp='cp -ipP'       # Copy with interactive prompt, preserving permissions, attributes, and symbolic links
alias mv='mv -vi'        # Move with interactive prompt
alias du='du -hs'        # Display disk usage in human-readable format
alias bc='bc --quiet -l' # The command like cal Calculator
alias df='df -h'
alias mime='file --mime --mime-type'
alias scp='scp -pr'
alias nl='nl -ba'
alias af='alias | grep -i --'


# ============================================================================
# HIMALAYA CLI MAIL CLIENT
# ============================================================================
alias hm='himalaya'
alias hmlist='himalaya envelope list'
alias hmstate='hm mailbox list --counts'
alias hminbox='hmlist --mailbox INBOX'
alias hmbin='hmlist --mailbox "[Gmail]/Bin"'
alias hmdraft='hmlist --mailbox "[Gmail]/Drafts"'
alias hmsent='hmlist --mailbox "[Gmail]/Sent Mail"'
alias hmspam='hmlist --mailbox "[Gmail]/Spam"'
alias hm_down_att='himalaya attachment download'
alias hmread='himalaya message read'
alias compose='himalaya message write'
alias newmail='hm message compose'

# export MML_CONFIG="/Users/pritam/Developer/git_repository/dotfiles/darwin/config/himalaya/config.toml"

# "[Gmail]/Important"
# "[Gmail]/Starred"

# function hmread() {
# 	himalaya message read $@ --json |
# 	jq -r '.parts[0].body.Text'
# }

function hmexport() {
	himalaya message export $@ \
	&& open "$TMPDIR/index.html"
}


# ============================================================================
# VNSTAT / VNSTATI NETWORK MONITOR
# ============================================================================
alias vns='vnstat'
alias vns5='vnstat -5'
alias vnsl='vnstat --live'

# --- More views ---
alias vnsd='vnstat -d'                    # daily traffic
alias vnsm='vnstat -m'                    # monthly traffic
alias vnsy='vnstat -y'                    # yearly traffic
alias vnsh='vnstat -h'                    # hourly traffic
alias vnshg='vnstat -hg'                  # hourly graph
alias vnst='vnstat -t'                    # top days

# --- Export / parsable ---
alias vnsj='vnstat --json'                # JSON output (pipe friendly)
alias vnsx='vnstat --xml'                 # XML output
alias vnso='vnstat --oneline'             # one line summary (great for status bars)

# --- Live & traffic test ---
alias vnslt='vnstat --live 1'             # live in bytes/s mode
alias vnslb='vnstat --live 0'             # live in packets mode
alias vnstr='vnstat -tr 10'               # measure traffic for 10 seconds

# --- 95th percentile ---
alias vns95='vnstat --95th'               # 95th percentile (for ISP billing)

# --- Date range queries ---
alias vnstoday='vnstat -d -b $(date +%Y-%m-%d) -e $(date +%Y-%m-%d)'   # today only
alias vnsweek='vnstat -d -b $(date -v-7d +%Y-%m-%d)'                   # last 7 days
alias vnsmonth='vnstat -m -b $(date +%Y-%m)'                            # this month

# --- Utility ---
alias vnsif='vnstat --iflist'             # list all available interfaces
alias vnsdb='vnstat --dbiflist'           # list interfaces in database
alias vnsdebug='vnstat --debug'           # debug mode

# --- vnstati (image/graph exports) ---
alias vni='vnstati -i en0'
alias vni5='vni -5           -o $TMPDIR/vnstati_5min.png         && echo "$TMPDIR/vnstati_5min.png"        &&  peek $TMPDIR/vnstati_5min.png'
alias vnid='vni -d           -o $TMPDIR/vnstati_daily.png        && echo "$TMPDIR/vnstati_daily.png"       &&  peek $TMPDIR/vnstati_daily.png'
alias vnih='vni --hours      -o $TMPDIR/vnstati_hours.png        && echo "$TMPDIR/vnstati_hours.png"       &&  peek $TMPDIR/vnstati_hours.png'
alias vnihg='vni --hoursgraph -o $TMPDIR/vnstati_hoursgraph.png  && echo "$TMPDIR/vnstati_hoursgraph.png"  &&  peek $TMPDIR/vnstati_hoursgraph.png'

alias vnim='vni -m           -o $TMPDIR/vnstati_monthly.png      && echo "$TMPDIR/vnstati_monthly.png"     &&  peek $TMPDIR/vnstati_monthly.png'
alias vniy='vni -y           -o $TMPDIR/vnstati_yearly.png       && echo "$TMPDIR/vnstati_yearly.png"      &&  peek $TMPDIR/vnstati_yearly.png'
alias vnit='vni -t           -o $TMPDIR/vnstati_top.png          && echo "$TMPDIR/vnstati_top.png"         &&  peek $TMPDIR/vnstati_top.png'
alias vnis='vni -s           -o $TMPDIR/vnstati_summary.png      && echo "$TMPDIR/vnstati_summary.png"     &&  peek $TMPDIR/vnstati_summary.png'
alias vni5g='vni -5g         -o $TMPDIR/vnstati_5mingraph.png    && echo "$TMPDIR/vnstati_5mingraph.png"   &&  peek $TMPDIR/vnstati_5mingraph.png'

# --- Summary layouts ---
alias vnihs='vni --hsummary  -o $TMPDIR/vnstati_hsummary.png     && echo "$TMPDIR/vnstati_hsummary.png"    &&  peek $TMPDIR/vnstati_hsummary.png'
alias vnivs='vni --vsummary  -o $TMPDIR/vnstati_vsummary.png     && echo "$TMPDIR/vnstati_vsummary.png"    &&  peek $TMPDIR/vnstati_vsummary.png'

# --- 95th percentile (useful for bandwidth billing) ---
alias vni95='vni --95th 0    -o $TMPDIR/vnstati_95th.png         && echo "$TMPDIR/vnstati_95th.png"        &&  peek $TMPDIR/vnstati_95th.png'


# ============================================================================
# EDITOR / CONFIG SHORTCUTS
# ============================================================================
# Shortcuts for editing configuration files
alias enrc='$EDITOR   ~/.config/nvim/init.lua'      # Edit NeoVim config
alias enhc='$EDITOR   ~/.config/helix'              # Edit helix config
alias enhc='$EDITOR   ~/.config/helix/config.toml'  # Edit helix config
alias ezdir='$EDITOR  ~/.config/zsh'                # Edit functon file
alias eza='$EDITOR    ~/.config/zsh/alias.zsh'      # Edit alias file
alias efz='$EDITOR    ~/.config/zsh/functions.sh'   # Edit functon file


# ============================================================================
# HEXDUMP
# ============================================================================
# Generate nicer-looking hexadecimal dumps
alias hd='command hexdump -C'
alias hexdump='hexdump -v \
	-e \""[2m│[22m0x%08.8_ax[2m│[22m "\" \
	-e '\''16/1 "%02X "'\'' \
	-e \"" [2m│[22m"\" \
	-e '\''16/1 "%_p" "'\''"[2m│[22m"'\''\n"'\'


# ============================================================================
# MACOS SYSTEM UTILITIES
# ============================================================================

# --- Filesystem / disk / attributes ---
alias umount='diskutil unmount'                     # Apple recommend diskutil(1) be used instead of umount(1)
alias unquarantine='xattr -rd com.apple.quarantine' # Remove annoying extended attributes added to downloads
alias typecode='GetFileInfo -t'    # Print 4-character creator/type codes
alias creatorcode='GetFileInfo -c' # Print 4-character creator/type codes

# --- Terminal ---
# Resize Terminal.app to fill the screen
alias fit="printf "\""\e[3;0;0t\e[4;0;9999t"\"
alias FIT="for i in /dev/ttys???; do fit > "$i"; done"

# --- Opening apps / editors on current directory ---
# alias o.='open .'                                                                          # Open current directory in Finder
alias o='open .'                                                                           # Open current directory in Finder
alias c.='code .'                                                                          # Open current directory in VS Code
alias zed='zed --existing'
alias z.='command zed .'                                                                           # Open current directory in Zed editor
alias v='${__MPV_CMD[@]}'
alias cdn='cd "$($DOT_FILE/bin_scripts/cdN.sh)"'
alias zed_editor='export EDITOR="zed--wait"'                                               # setting EDITOR = zed

# --- Git / VCS ---
alias tigs='tig status'                                                                    # Open git status in tig

# --- Databases ---
alias sqldump='sqlite3 /dev/stdin .dump <'                                                 # Dump an SQLite database in human-readable form

# --- Find / cleanup ---
alias prune='find -L . -name . -o -type d -prune -o -type l -exec rm -v {} +'              # Delete broken symlinks in the current directory
# alias findexe='find . -type f -perm +111'                                                  # Delete broken symlinks in the current directory
alias findexe='fd --type executable -H '                                                   # Delete broken symlinks in the current directory
alias hardlinks='find . \! -type d \! -links 1'                                            # List files with at least one hard-link
alias xxd='xxd -R always'                                                                  # Generate nicer-looking hexadecimal dumps
alias per='find . -type f -exec chmod -v 644 {} \; ; find . -type d -exec chmod -v 755 {} \;' # Fix permissions
alias chownroot='sudo chown -R root:wheel'                                                 # Change ownership to root
alias chownself='sudo chown -R pritam:staff'                                               # Change ownership to user

# --- Preview / power / hardware ---
alias peek='qlmanage -p >/dev/null 2>&1  -- '                                              # Preview a file using Quick Look
alias batt_heath='system_profiler SPPowerDataType | grep -E "Condition|Cycle Count|Maximum Capacity"'
alias poweroff='sudo poweroff'

# --- Tree / directory listing ---
alias tree='tree -a --dirsfirst --noreport'                                                # Hide summary lines in tree(1) output
alias tree_project='tree --gitignore --gitfile ~/.config/git/gitignore -I ".git" $(realpath)'
alias treels='tree -spughDF --metafirst --timefmt="%b-%d-%Y %I:%M %p"'
# alias tre='tre -a -E ".git"'                                                               # Display directory tree

# --- Media ---
alias ffplay='ffplay -alwaysontop -loop -1 -sn -loglevel warning -stats -seek_interval 5'  # Play a video file in loop
alias sayy='pbpaste | command say -i'                                                      # Convert clipboard text to speech
alias agg='agg -v --idle-time-limit 0.7 --fps-cap 30 --font-size 20 --font-family "JetBrains Mono"'

# --- Language / dev tools ---
alias co='cargo'                                                                            # Use rust cargo as co
alias cob='RUSTFLAGS="-C prefer-dynamic" cargo build'                                       # dynamic-linked debug build

alias python='python3 -u'                                                                  # Use Python 3 as default
alias ninja_tree='ninja -t targets'                                                        # Display Ninja build targets
alias tokei='tokei --sort code --num-format commas'
alias sp2tab='perl -i -pe '\''1 while s/^(\t*) {4}/$1\t/mg'\'''                            # Convert leading groups of four spaces into tabs

# --- Environment / misc info ---
alias envpath='envinspector | less'                                                        # Print the environment variable in prettiest form
alias nq='networkquality -s'                                                               # Check network quality
alias sf='command ls -AF | grep -i'                                                        # Search files in current directory
alias findcommand='apropos'
alias seelog='tail -n 1 -f --'                                                             # Tail logs
alias exportlib='source $LIBS_DIR/env'                                                     # Load library environment
alias exportembdlib='source $DOT_FILE/../global/embedded/embedded-ENV.sh'                  # Load embedded environment
alias hfind='grep < "$HISTFILE"'
alias colorPicker='pastel pick 2> /dev/null | pastel format hex | tr -d "\012" |  pbcopy'  #
alias sk='sk --case=smart --reverse'
alias find_font='fc-list : family | sk'
alias ghetags='gh repo edit --add-topic'

alias rss='yarr -open'
alias rssht='rss -db $XDG_DATA_HOME/yarr/hindustan_times.sqlite'

# --- Archives ---
alias bsdtar='bsdtar --acls --fflags --xattrs --mac-metadata'                              # Archive macOS-specific filesystem attributes
alias ex='bsdtar -vxf'                                                                     # Extract archives

# --- Downloads / transfer ---
alias wget='caffeinate -iw "$(pgrep wget)" & wget -c'                                      # Download with wget
alias wgetc='wget --load-cookies ~/.cache/extract_cookies/cookies_firefox.txt'             # Download with wget with cookies on
alias eget='eget --download-only'                                                          # Tell eget to only download the System wise release zip file
alias aria2c='caffeinate -iw $(pgrep aria2c) & aria2c --dir . '                            # aria2c download file in $PWD
alias rclone_gui='rclone rcd --rc-web-gui --rc-no-auth'                                    # configure our rclone with webui
# alias gui-docker=''                                                                        # configure our docker with webui

# --- Local servers ---
# alias live-server='open 'http://localhost:8085/'  &&  python3 -m http.server 8085'                     # Start live server with python
# alias bk='(sleep 0.5; open "https://[::]:8443/")&  https-server -d ~/Developer/web-dev/LocalMarks'     # Open bookmarks server with https
# alias bkk='live-server -K 0 -P 8086 -B open -I ~/Developer/web-dev/LocalMarks'                            # Open bookmarks server
alias bk='local-mark -K 0 -P 8087 -B open ~/.local/share/bookmarks/*.json'                                # Open bookmarks server
# alias bk='open "http://localhost:8080/"  &&  shiori server'                                            # Open bookmarks server


alias https-server='python3 -m http.server 8443 --tls-key "$MK_CERT_DIR/localhost+2-key.pem" --tls-cert "$MK_CERT_DIR/localhost+2.pem"'

# alias host_ftp_server='rclone serve ftp "$PWD" --addr :2121 --user $USER --pass 12426'
# alias host_sftp_server='rclone serve sftp "$PWD" --addr :2121 --user u --pass s'

alias host_rclone_http_server='rclone serve http . --addr 0.0.0.0:2121 --user $USER --pass $OPENCODE_SERVER_PASSWORD'
alias host_ftp_server='python3 -m pyftpdlib --write --username $USER --password $OPENCODE_SERVER_PASSWORD'
alias host_sftp_server='sudo systemsetup -setremotelogin on' # The port will be 22

# ============================================================================
# Opencode
# ============================================================================
alias oc='opencode --continue'                                          # Download with wget
# alias ocw='caffeinate -i opencode web'   # Download with wget
alias ocs='caffeinate -i opencode serve --port 4096 --hostname 0.0.0.0'   # Download with wget

# ============================================================================
# EXIFTOOL / METADATA
# ============================================================================
alias exprobe='ffprobe -v quiet -print_format json -show_format -show_streams'
alias exf='exiftool -sort -P -overwrite_original_in_place' # Modify metadata
alias exfcpy='exf -TagsFromFile'                           # Copy metadata from another file
alias stripmeta='exiftool -All= -overwrite_original'
# alias x='exiftool -a -U'
# alias X='x -b -X'


# ============================================================================
# IP AND MAC ADDRESS
# ============================================================================
# Fetch WAN (public) IP address
alias myip="curl -sL https://ifconfig.me/ip   &&   echo   ' '   &&   curl -s http://checkip.dyndns.org/ | sed 's/[a-zA-Z<>/ :]//g'"

# Fetch LAN (local) IP address
alias lanip='ipconfig getifaddr en0'
