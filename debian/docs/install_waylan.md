Nice — this fits perfectly into your setup doc 👍
Here’s a **clean, practical “Install Wayland stack” section** for **headless Debian → Sway / Wayland** style systems.

You can paste this directly into your `.md` file.

---

## ✅ Install Wayland Stack (Debian Headless)

This installs the core Wayland ecosystem without pulling a full desktop environment.

---

## 🧱 1. Install base Wayland packages

```bash
sudo apt install -y \
wayland-protocols \
xwayland \
seatd \
dbus-user-session \
libinput-tools \
mesa-utils \
mesa-vulkan-drivers
```

Enable seatd:

```bash
sudo systemctl enable seatd
sudo systemctl start seatd
sudo usermod -aG seat pritam
```

Log out and back in after this.

---

## 🪟 2. Install Sway (Wayland WM)

```bash
sudo apt install -y \
sway swaybg swaylock swayidle \
foot waybar wofi grim slurp
```

What these do:

* `sway` → window manager
* `foot` → Wayland terminal
* `waybar` → status bar
* `wofi` → app launcher
* `grim + slurp` → screenshots

---

## 🎨 3. GPU + rendering support

For Intel / AMD:

```bash
sudo apt install -y \
firmware-linux \
intel-media-va-driver-non-free \
mesa-va-drivers
```

For NVIDIA (you have RTX 3060 on another box 😉):

```bash
sudo apt install -y nvidia-driver firmware-misc-nonfree
```

Reboot after NVIDIA install.

---

## 🔑 4. Login without a display manager (TTY → Sway)

Add this to `~/.profile`:

```bash
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec sway
fi
```

Now login on tty1 → auto starts Wayland.

---

## 🔊 5. Audio (PipeWire)

```bash
sudo apt install -y \
pipewire pipewire-audio \
wireplumber pavucontrol
```

Enable:

```bash
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber
```

---

## 🌐 6. Network helpers

```bash
sudo apt install -y \
network-manager network-manager-gnome
```

Enable:

```bash
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
```

Then use:

```bash
nmtui
```

---

## 🧠 7. XDG + portals (important for Wayland apps)

```bash
sudo apt install -y \
xdg-desktop-portal \
xdg-desktop-portal-wlr
```

---

## 🧪 8. Test Wayland

```bash
echo $XDG_SESSION_TYPE
```

Should show:

```text
wayland
```

Check renderer:

```bash
glxinfo -B
```

---

## ⚡ Minimal Sway launch (manual)

If you don’t auto-start:

```bash
dbus-run-session sway
```

---

## 🧼 Notes for your style

* No display manager (clean, fast).
* TTY → Wayland like Hyprland workflow.
* Works great over SSH for config.
* Matches your **Debian + headless + WM mindset**.

---

## 🚀 Optional extras

```bash
sudo apt install -y \
polkit-kde-agent-1 \
brightnessctl playerctl
```

Add polkit to Sway config:

```bash
exec /usr/lib/polkit-kde-authentication-agent-1
```

---

If you want next, I can add:

* ✅ **Hyprland on Debian**
* ✅ **Wayland fonts + theming**
* ✅ **Sway config starter**
* ✅ **NVIDIA Wayland tuning**
* ✅ **A one-shot installer script**

Just tell me 😄
