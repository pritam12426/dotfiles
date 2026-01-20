#!/bin/bash

# Source:
#   https://codeberg.org/justaguylinux/sway-setup/src/branch/main/install.sh
#   https://codeberg.org/justaguylinux/sway-setup
#   https://www.youtube.com/watch?v=ARQOglfzrbQ

# Sway Setup Installer
# Based on JustAGuy Linux DWM Setup

set -e

# Command line options
ONLY_CONFIG=false
EXPORT_PACKAGES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --only-config)
            ONLY_CONFIG=true
            shift
            ;;
        --export-packages)
            EXPORT_PACKAGES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages)"
            echo "  --export-packages  Export package lists for different distros and exit"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/sway"
TEMP_DIR="/tmp/sway_$$"
LOG_FILE="$HOME/sway-install.log"

# Logging and cleanup
exec > >(tee -a "$LOG_FILE") 2>&1
trap "rm -rf $TEMP_DIR" EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
msg() { echo -e "${CYAN}$*${NC}"; }

# Export package lists for different distros
export_packages() {
    echo "=== Sway Setup - Package Lists for Different Distributions ==="
    echo

    # Combine all packages
    local all_packages=(
        "${PACKAGES_CORE[@]}"
        "${PACKAGES_SWAY[@]}"
        "${PACKAGES_UI[@]}"
        "${PACKAGES_FILE_MANAGER[@]}"
        "${PACKAGES_AUDIO[@]}"
        "${PACKAGES_UTILITIES[@]}"
        "${PACKAGES_FONTS[@]}"
        "${PACKAGES_BUILD[@]}"
    )

    echo "DEBIAN/UBUNTU:"
    echo "sudo apt install ${all_packages[*]}"
    echo

    # Arch equivalents
    local arch_packages=(
        "sway swayidle swaylock swaybg waybar"
        "wofi wmenu foot autotiling sway-notification-center"
        "grim slurp wl-clipboard cliphist"
        "brightnessctl playerctl"
        "wlr-randr wdisplays kanshi"
        "xdg-desktop-portal-wlr swappy wtype"
        "thunar thunar-archive-plugin thunar-volman"
        "gvfs dialog mtools smbclient cifs-utils unzip"
        "pavucontrol pulsemixer pamixer pipewire-pulse"
        "network-manager-applet polkit-gnome"
        "nwg-look eog firefox wezterm geany"
        "ttf-jetbrains-mono-nerd"
        "noto-fonts-emoji papirus-icon-theme"
        "gawk"
    )

    echo "ARCH LINUX:"
    echo "sudo pacman -S ${arch_packages[*]}"
    echo

    # Fedora equivalents
    local fedora_packages=(
        "sway swayidle swaylock swaybg waybar"
        "wofi wmenu foot sway-notification-center"
        "grim slurp wl-clipboard"
        "brightnessctl playerctl"
        "wlr-randr wdisplays kanshi"
        "xdg-desktop-portal-wlr swappy wtype"
        "thunar thunar-archive-plugin thunar-volman"
        "gvfs dialog mtools samba-client cifs-utils unzip"
        "pavucontrol pulsemixer pamixer pipewire-pulseaudio"
        "network-manager-applet polkit-gnome"
        "nwg-look eog firefox wezterm geany"
        "jetbrains-mono-fonts-all"
        "google-noto-emoji-fonts papirus-icon-theme"
        "gawk"
    )

    echo "FEDORA:"
    echo "sudo dnf install ${fedora_packages[*]}"
    echo

    echo "NOTE: Some packages may have different names or may not be available"
    echo "in all distributions. You may need to:"
    echo "  - Find equivalent packages in your distro's repositories"
    echo "  - Install some tools from source"
    echo "  - Use alternative package managers (AUR for Arch, Flatpak, etc.)"
    echo
    echo "After installing packages, you can use:"
    echo "  $0 --only-config    # To copy just the Sway configuration files"
}

# Check if we should export packages and exit
if [ "$EXPORT_PACKAGES" = true ]; then
    export_packages
    exit 0
fi

# Banner
clear
echo -e "${CYAN}"
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |S|w|a|y| |S|e|t|u|p|    | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |W|a|y|l|a|n|d| |W|M|    | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo -e "${NC}\n"

read -p "Install Sway? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Update system
if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo apt-get update && sudo apt-get upgrade -y
else
    msg "Skipping system update (--only-config mode)"
fi

# Package groups for better organization
PACKAGES_CORE=(
    sway swayidle gtklock swaybg waybar
    xwayland build-essential
)

PACKAGES_SWAY=(
    wofi wmenu foot sway-notification-center autotiling
    grim slurp wl-clipboard cliphist
    brightnessctl playerctl
    wlr-randr
    xdg-desktop-portal-wlr swappy wtype
)

PACKAGES_UI=(
    nwg-look network-manager-gnome lxpolkit
)

PACKAGES_FILE_MANAGER=(
    thunar thunar-archive-plugin thunar-volman
    gvfs-backends dialog mtools smbclient cifs-utils unzip
)

PACKAGES_AUDIO=(
    pavucontrol pulsemixer pamixer pipewire-audio
)

PACKAGES_UTILITIES=(
    avahi-daemon acpi acpid
    fd-find xdg-user-dirs-gtk
    kanshi eog nwg-displays
    gawk
    libnotify-bin libnotify-dev libusb-0.1-4
)

PACKAGES_BUILD=(
    cmake meson ninja-build curl pkg-config wget
)

PACKAGES_FONTS=(
    fonts-recommended fonts-font-awesome fonts-noto-color-emoji
)

# Install packages by group
if [ "$ONLY_CONFIG" = false ]; then
    msg "Installing core Sway packages..."
    sudo apt-get install -y "${PACKAGES_CORE[@]}" || die "Failed to install core packages"

    msg "Installing Sway components..."
    sudo apt-get install -y "${PACKAGES_SWAY[@]}" || die "Failed to install Sway packages"

    msg "Installing UI components..."
    sudo apt-get install -y "${PACKAGES_UI[@]}" || die "Failed to install UI packages"

    msg "Installing file manager..."
    sudo apt-get install -y "${PACKAGES_FILE_MANAGER[@]}" || die "Failed to install file manager"

    msg "Installing audio support..."
    sudo apt-get install -y "${PACKAGES_AUDIO[@]}" || die "Failed to install audio packages"

    msg "Installing build tools..."
    sudo apt-get install -y "${PACKAGES_BUILD[@]}" || die "Failed to install build tools"

    msg "Installing system utilities..."
    sudo apt-get install -y "${PACKAGES_UTILITIES[@]}" || die "Failed to install utilities"

    # Try firefox-esr first (Debian), then firefox (Ubuntu)
    sudo apt-get install -y firefox-esr 2>/dev/null || sudo apt-get install -y firefox 2>/dev/null || msg "Note: firefox not available, skipping..."

    msg "Installing fonts..."
    sudo apt-get install -y "${PACKAGES_FONTS[@]}" || die "Failed to install fonts"

    # Enable services
    sudo systemctl enable avahi-daemon acpid
else
    msg "Skipping package installation (--only-config mode)"
fi

# Handle existing config
if [ -d "$CONFIG_DIR" ]; then
    clear
    read -p "Found existing Sway config. Backup? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
        msg "Backed up existing config"
    else
        clear
        read -p "Overwrite without backup? (y/n) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || die "Installation cancelled"
        rm -rf "$CONFIG_DIR"
    fi
fi

# Copy configs
msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"
cp -r "$SCRIPT_DIR"/config/* "$CONFIG_DIR"/ || die "Failed to copy configs"

# Create symlinks only for apps that require default locations
# Note: rofi, waybar, and swaync are configured with direct paths in sway config
ln -sf ~/.config/sway/gtklock ~/.config/gtklock
ln -sf ~/.config/sway/foot ~/.config/foot

# Setup directories
xdg-user-dirs-update
mkdir -p ~/Screenshots

# Butterscript helper
get_script() {
    wget -qO- "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/$1" | bash
}

# Install essential components
if [ "$ONLY_CONFIG" = false ]; then
    mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

    msg "Installing wezterm..."
    get_script "wezterm/install_wezterm.sh"
    
    msg "Installing rofi wayland..."
    get_script "setup/install_rofi_wayland.sh"

    msg "Installing fonts..."
    get_script "theming/install_nerdfonts.sh"

    msg "Installing themes..."
    get_script "theming/install_theme.sh"

    msg "Downloading wallpaper directory..."
    cd "$CONFIG_DIR"
    git clone --depth 1 --filter=blob:none --sparse https://codeberg.org/justaguylinux/butterscripts.git "$TEMP_DIR/butterscripts-wallpaper" || die "Failed to clone butterscripts"
    cd "$TEMP_DIR/butterscripts-wallpaper"
    git sparse-checkout set wallpaper || die "Failed to set sparse-checkout"
    cp -r wallpaper "$CONFIG_DIR"/ || die "Failed to copy wallpaper directory"
    
    msg "Downloading display manager installer..."
    wget -O "$TEMP_DIR/install_lightdm.sh" "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/system/install_lightdm.sh"
    chmod +x "$TEMP_DIR/install_lightdm.sh"
    msg "Running display manager installer..."
    # Run in current terminal session to preserve interactivity
    bash "$TEMP_DIR/install_lightdm.sh"

    # NVIDIA setup (auto-detects GPU and drivers)
    msg "Checking for NVIDIA GPU configuration..."
    bash "$SCRIPT_DIR/nvidia-setup.sh"

    # Optional tools
    clear
    read -p "Install optional tools (browsers, editors, etc)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg "Downloading optional tools installer..."
        wget -O "$TEMP_DIR/optional_tools.sh" "https://codeberg.org/justaguylinux/butterscripts/raw/branch/main/setup/optional_tools.sh"
        chmod +x "$TEMP_DIR/optional_tools.sh"
        msg "Running optional tools installer..."
        if bash "$TEMP_DIR/optional_tools.sh"; then
            msg "Optional tools completed successfully"
        else
            msg "Optional tools exited (this is normal if cancelled by user)"
        fi
    fi
else
    msg "Skipping external tool installation (--only-config mode)"
fi

# Done
echo -e "\n${GREEN}Installation complete!${NC}"
echo "1. Log out and select 'Sway' from your display manager"
echo "2. Or run 'sway' from a TTY"
echo "3. Press Super+Space for application launcher"
echo "4. Press Super+Shift+n for notification center"
echo "Installation log: $LOG_FILE"
