For **Sway + Wayland + PipeWire/WirePlumber**, these are the tools most people use:

### GUI Mixer (recommended)

#### pavucontrol

Despite the name, it works perfectly with PipeWire through `pipewire-pulse`.

Install:

```bash
sudo apt install pavucontrol
```

Features:

* Change speaker volume
* Change microphone gain
* Select default input/output devices
* Per-application volume control
* Monitor active audio streams

Launch:

```bash
pavucontrol
```

Many Sway users still use this as their primary audio control panel. ([Reddit][1])

---

### Native CLI Manager (my preference on a headless system)

#### `wpctl`

WirePlumber's official command-line tool for managing audio devices, volume, mute state, and defaults. ([pipewire.pages.freedesktop.org][2])

Show devices:

```bash
wpctl status
```

Increase volume:

```bash
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
```

Decrease volume:

```bash
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
```

Toggle mute:

```bash
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

Toggle microphone mute:

```bash
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
```

([Linux Command Library][3])

---

### Sway Keybindings

Add to `~/.config/sway/config`:

```bash
bindsym XF86AudioRaiseVolume exec wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
```

`-l 1` prevents volume from exceeding 100%. ([Linux Command Library][3])

---

### For a Status Bar

#### Waybar

Waybar has built-in PipeWire/PulseAudio modules, and many Sway setups use it to display volume and microphone state. Community examples commonly integrate it with `wpctl`. ([Reddit][4])

---

### For Advanced Routing

#### qpwgraph

Install:

```bash
sudo apt install qpwgraph
```

Useful if you want:

* OBS routing
* Virtual microphones
* Loopback devices
* JACK-style audio patching
* Debugging PipeWire connections

---

For a minimal **headless Debian + Sway** setup, I'd install only:

```bash
sudo apt install pipewire wireplumber pavucontrol qpwgraph
```

and use:

* `wpctl` for keyboard shortcuts
* `pavucontrol` for occasional GUI management
* `qpwgraph` when you need to debug or reroute audio.

[1]: https://www.reddit.com/r/cachyos/comments/1t5ek3z/opening_pavucontrol_breaks_audio_pipewirepulse/?utm_source=chatgpt.com "Opening pavucontrol breaks audio (pipewire-pulse)"
[2]: https://pipewire.pages.freedesktop.org/wireplumber/tools/wpctl.html?utm_source=chatgpt.com "wpctl(1) — WirePlumber 0.5.13 documentation"
[3]: https://linuxcommandlibrary.com/man/wpctl?utm_source=chatgpt.com "wpctl man | Linux Command Library"
[4]: https://www.reddit.com/r/swaywm/comments/xtxys5?utm_source=chatgpt.com "[OC] Pipewire/Wireplumber module for Waybar"







If you've installed **only Sway** on a minimal Debian system, you'll quickly discover that Sway gives you a window manager, but not all the "desktop services" that GNOME/KDE normally provide.

A practical starter stack looks like this:

## Terminal

Pick one:

* foot (recommended)
* kitty
* Alacritty

```bash
sudo apt install foot
```

---

## Launcher

Pick one:

* fuzzel (lightweight)
* wofi

```bash
sudo apt install fuzzel
```

Sway config:

```bash
bindsym $mod+d exec fuzzel
```

---

## Status Bar

### Waybar

```bash
sudo apt install waybar
```

In your Sway config:

```bash
bar {
    swaybar_command waybar
}
```

Shows:

* Workspaces
* Clock
* Battery
* CPU
* Memory
* Network
* Volume

---

## Notifications

### mako

```bash
sudo apt install mako
```

Autostart:

```bash
exec mako
```

Without a notification daemon, many apps silently fail to show notifications.

---

## Clipboard

### wl-clipboard

```bash
sudo apt install wl-clipboard
```

Examples:

```bash
echo hello | wl-copy
wl-paste
```

---

## Audio

If you're not already using it:

### PipeWire

### WirePlumber

```bash
sudo apt install pipewire wireplumber pipewire-pulse
```

GUI mixer:

```bash
sudo apt install pavucontrol
```

---

## File Manager

Pick one:

* Thunar
* PCManFM

```bash
sudo apt install thunar
```

---

## Screenshots

### grim

### slurp

```bash
sudo apt install grim slurp
```

Example:

```bash
grim -g "$(slurp)" screenshot.png
```

---

## Lock Screen

### swaylock

```bash
sudo apt install swaylock
```

Binding:

```bash
bindsym $mod+Shift+l exec swaylock
```

---

## Idle/Suspend Management

### swayidle

```bash
sudo apt install swayidle
```

Example:

```bash
exec swayidle -w \
  timeout 300 'swaylock -f' \
  timeout 600 'systemctl suspend'
```

---

## Brightness Control (laptops)

### brightnessctl

```bash
sudo apt install brightnessctl
```

---

## Network Management

### NetworkManager

```bash
sudo apt install network-manager
```

CLI:

```bash
nmcli device wifi list
nmcli device wifi connect "SSID"
```

TUI:

```bash
sudo apt install nmtui
```

```bash
nmtui
```

---

## Polkit Authentication

Many GUI apps need this.

### polkit-kde-agent-1

or

### lxqt-policykit

```bash
sudo apt install lxqt-policykit
```

Autostart:

```bash
exec lxqt-policykit-agent
```

---

## File Chooser/Desktop Integration

### xdg-desktop-portal-wlr

```bash
sudo apt install xdg-desktop-portal xdg-desktop-portal-wlr
```

Needed for:

* Screen sharing
* Flatpaks
* Browser file dialogs
* Some Electron apps

---

## A minimal but comfortable Sway setup

```bash
sudo apt install \
  foot \
  fuzzel \
  waybar \
  mako \
  wl-clipboard \
  pipewire \
  wireplumber \
  pavucontrol \
  swaylock \
  swayidle \
  grim \
  slurp \
  brightnessctl \
  network-manager \
  lxqt-policykit \
  xdg-desktop-portal \
  xdg-desktop-portal-wlr \
  thunar
```

That gives you roughly 90% of the conveniences of a full desktop environment while keeping the system lightweight and fully under your control.
