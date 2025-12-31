## Login as root & update system

```bash
su -
apt update && apt upgrade -y
apt install sudo -y
```

---

## Add user to sudoers

Replace `pritam` with your username if needed.

```bash
usermod -aG sudo <|username|>
```

Then log out and back in:

```bash
exit
logout
```

Test:

```bash
sudo whoami
```

Expected output:

```text
root
```

---

## Get LAN IP address

Used for SSH from the host machine.

```bash
hostname -I | awk '{print $1}'
```

---

## Connect from host via SSH

From your main computer:

```bash
ssh <user>@<ip>
```

---

## ✅ 5. Fix locale warnings

Install and configure UTF-8 locale properly.

```bash
sudo apt install locales -y
sudo dpkg-reconfigure locales
```

Select:

```
en_US.UTF-8 UTF-8
```

Then set it:

```bash
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
```

Reload:

```bash
source /etc/default/locale
```

---

## Install Nala (better APT UI)

```bash
sudo /bin/apt install nala
```

---

## Install core development tools

```bash
sudo apt install -y \
git curl wget gettext 
```

```sh
sudo apt install \
	build-essential \
	cmake cmake-extras 
```

---

## Install modern CLI tools

```bash
sudo apt install -y \
	fd-find fzf bat zoxide tig \
	zip tmux btop gnupg zsh
```

Debian installs `fd` as `fdfind`, so we link it.

```bash
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
```

---

## Set Zsh as default shell

```bash
chsh -s $(which zsh)
```

Logout and login again.


---




## INSTALLATION OF DOT FILES

``` sh
mkdir -p "$HOME/Developer/git_repository"
cd "$HOME/Developer/git_repository"

# Change the https origin to ssh url with git command
git clone "https://github.com/pritam12426/dotfile.git" dotfiles

cd dotfiles/debian
export DOT_FILE="$PWD"
./install.zsh
```

## References 

- [Github awesome-tuis](https://github.com/rothgar/awesome-tuis/)
- [Terminaltrove](https://terminaltrove.com)
- [Suckless](https://suckless.org/rocks/)
- [Asciinema](https://asciinema.org/)
- [FreeCodeCamp](https://www.freecodecamp.org/news/essential-cli-tui-tools-for-developers/)
- [Github - Alhadis](https://github.com/Alhadis/.files)

## Some release binary managers

- [brew](https://brew.sh/)
- [bin](https://github.com/marcosnils/bin)
- [kelp](https://github.com/crhuber/kelp)
- [pkgx](https://github.com/pkgxdev/pkgx)  `Nice tool`
- [rudix](https://github.com/rudix-mac/rudix)
- [pkgsrc](https://www.pkgsrc.org/)   `Nice tool`
- [asdf](https://github.com/asdf-vm/asdf)

## Install with Bin command

- [adbtuifm](https://github.com/darkhz/adbtuifm) (Not Regularly Used)
- [age](https://github.com/FiloSottile/age) (Regularly Used)
- [rage](https://github.com/FiloSottile/age) (Regularly Used)
- [arduino-cli](https://github.com/arduino/arduino-cli)  (Regularly Used)
- [asciinema](https://github.com/asciinema/asciinema)  (Not Regularly Used)
- [atac](https://github.com/Julien-cpsn/ATAC)  (Not Regularly Used)
- [bat](https://github.com/charlie0129/batt/releases)  (Regularly Used)
- [batt](https://github.com/charlie0129/batt)  (Regularly Used)
- [broot](https://github.com/Canop/broot)  (Not Regularly Used)
- [caligula](https://terminaltrove.com/caligula/)  (Not Regularly Used)
- [cargo-seek](https://github.com/tareqimbasher/cargo-seek) (Not Regularly Used)
- [croc](https://github.com/schollz/croc) (Not Regularly Used)
- [d2](https://github.com/terrastruct/d2) (Regularly Used)
- [dog](https://github.com/ogham/dog) with RUST (Regularly Used)
- [doggo](https://github.com/mr-karan/doggo)  (Regularly Used)
- [dra](https://terminaltrove.com/dra/) (Not Regularly Used)
- [dua](https://terminaltrove.com/dua/) (Not Regularly Used)
- [duf](https://github.com/muesli/duf) (Not Regularly Used)
- [dust](https://github.com/bootandy/dust) (Not Regularly Used)
- [eget](/Users/pritam/.local/dev-tools/eget-1.3.4/) (Regularly Used)
- [fd](https://github.com/sharkdp/fd) (Regularly Used)
- [fzf](https://github.com/junegunn/fzf) (Regularly Used)
- [gh](https://github.com/cli/cli) (Regularly Used)
- [gopass](https://github.com/gopasspw/gopass) (Regularly Used)
- [himalaya](https://github.com/pimalaya/himalaya?tab=readme-ov-file) (Regularly Used)
- [hurl](https://hurl.dev/) (Regularly Used)
- [joshuto - ranger](https://github.com/kamiyaa/joshuto) (Regularly Used)
- [lazydocker](https://github.com/jesseduffield/lazydocker) (Not Regularly Used)
- [lazygit](https://github.com/jesseduffield/lazygit) (Not Regularly Used)
- [lf](https://github.com/gokcehan/lf) (Regularly Used)
- [n8n](https://github.com/n8n-io/n8n) (Regularly Used)
- [navi](https://github.com/denisidoro/navi) `alternative for tldr` (Regularly Used)
- [neocmakelsp](https://github.com/neocmakelsp/neocmakelsp) (Regularly Used)
- [numbat](https://github.com/sharkdp/numbat) (Regularly Used)
- [onefeatch](https://github.com/o2sh/onefetch) (Regularly Used)
- [pinentry-touchid](https://github.com/jorgelbg/pinentry-touchid) (Not Regularly Used)
- [rclone](https://github.com/rclone/rclone)  (Regularly Used)
- [readeck](https://codeberg.org/readeck/readeck) `Good alternatives for shiori` (Regularly Used)
- [rg](https://github.com/BurntSushi/ripgrep)  (Regularly Used)
- [ruff](https://github.com/astral-sh/ruff)  (Regularly Used)
- [scrcpy](https://github.com/Genymobile/scrcpy) (Regularly Used)
- [shellcheck](https://github.com/koalaman/shellcheck)  (Regularly Used)
- [shfmt](https://github.com/patrickvane/shfmt) (Regularly Used)
- [shiori](https://github.com/go-shiori/shiori) (Regularly Used)
- [sk](https://github.com/skim-rs/skim) `A fuzzy finder written in Rust.` (Regularly Used)
- [syncthing](https://syncthing.net)(Regularly Used)
- [taplo](https://github.com/tamasfe/taplo) (Regularly Used)
- [tinymist](https://github.com/Myriad-Dreamin/tinymist/) (Regularly Used)
- [tldr](https://github.com/tealdeer-rs/tealdeer) (Regularly Used)
- [tre](https://github.com/dduan/tre) (Not Regularly Used)
- [typst](https://github.com/typst/typst) (Regularly Used)
- [webui for docker - portainer](https://github.com/portainer/portainer) (Not Regularly Used)
- [wireproxy](https://www.youtube.com/watch?v=ESr0xid-kl4) (Regularly Used)
- [zellij](https://github.com/zellij-org/zellij) (Not Regularly Used)
- [zenity](https://github.com/ncruces/zenity) (Regularly Used)
- [qmv](https://github.com/itchyny/mmv) (Regularly Used)

## Manual / Releases

- [fastfetch](https://github.com/fastfetch-cli/fastfetch) `manually install this for the  Releases page` then after like the binary with bin.json (Regularly Used)
- [gnu stow](https://www.gnu.org/software/stow/) `install manually with   https://formulae.brew.sh/formula/stow ` (Regularly Used)
- [hx](https://github.com/helix-editor/helix) `manually install this for the  Releases page` (Regularly Used)
- [mac-cleanup](https://github.com/mac-cleanup) `manually install this for the  Releases page` (Regularly Used)
- [pandoc](https://github.com/jgm/pandoc) `manually install this for the  Releases page` (Regularly Used)
- [privacy-sexy](https://github.com/undergroundwires/privacy.sexy) `manually install this for the  Releases page` (Not Regularly Used)
- [shadowsocks](https://github.com/shadowsocks) `manually install this for the  Releases page` (Not Regularly Used)
- [sleek](https://github.com/nrempel/sleek) `sql formater manually install this for the  Releases page` (Regularly Used)
- [sqlmap](https://github.com/sqlmapproject/sqlmap) `manually install this for the  Releases page` (Regularly Used)
- [vidir](https://github.com/trapd00r/vidir) `manually install this for the  Releases page` (Not Regularly Used)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) Media downlader. `manually install this for the  Releases page` (Regularly Used)

## Github / Binary / Build From Source

- [aria2c](https://github.com/aria2/aria2) `You have the binary on you github` (Regularly Used)
- [live-server](https://github.com/lomirus/live-server) `You have the binary on you github or instlal with cargo ` (Regularly Used)
- [clock](https://www.youtube.com/watch?v=0rUBhqR6ckw&t=12242s) `You have the binary on you github` (Regularly Used)
- [cointop](https://github.com/cointop-sh/cointop) `You have the binary on you github` (Regularly Used)
- [entr](https://github.com/eradman/entr) `You have the binary on you github / build from source for new verison esay to install` (Regularly Used)
- [envpath]() `You have the binary on you github` (Regularly Used)
- [fclones](https://terminaltrove.com/fclones/) duplicate files on your system `you have the binary on you github` (Regularly Used)
- [gsed]() `You have the binary on you github` (Regularly Used)
- [htop]() `You have the binary on you github` (Regularly Used)
- [ncdu]() `You have the binary on you github` (Regularly Used)
- [pkg-config]() `You have the binary on you github` (Not Regularly Used)
- [pkgconf]() `You have the binary on you github` (Regularly Used)
- [pstree](https://github.com/FredHucht/pstree) `You have the binary on you github` (Regularly Used)
- [tig](https://github.com/jonas/tig) `You have the binary on you github / build from source for new verison esay to install` (Regularly Used)
- [time](https://timewarrior.net) `You have the binary on you github` (Regularly Used)
- [timew](https://timewarrior.net/) `You have the binary on you github` (Regularly Used)
- [tree]() `you have the binary on you github` (Regularly Used)
- [typst-live](https://github.com/ItsEthra/typst-live) `You have the binary on you github` (Regularly Used)

## Ships With Command Line Tools

- [clang-stat-cache]() `Ships with command online tools  /Library/Developer/CommandLineTools/usr/bin` (Not Regularly Used)
- [clang-tidy]() `Ships with command online tools  /Library/Developer/CommandLineTools/usr/bin` (Not Regularly Used)

## Other / Unspecified

- [adb](https://github.com/Genymobile/scrcpy) tool for working with add `Static binary is there of the googel adb page or go with scrcpy` (Regularly Used) - [axel](https://github.com/axel-download-accelerator/axel) (Not Regularly Used)
- [sntop](https://terminaltrove.com/sntop/) (Not Regularly Used)
- [goaccess](https://terminaltrove.com/goaccess/) (Not Regularly Used)
- [fastfetch / neofeatch]() (Not Regularly Used)
- [doxygen]() (Not Regularly Used)
- [gradle]() (Regularly Used)
- [jdtls]() (Not Regularly Used)
- [ninja]() (Regularly Used)
- [osm]() (Regularly Used)
- [rr]() (Regularly Used)
- [rrr]() (Regularly Used)
- [rrrr]() (Not Regularly Used)
- [sql-fmt]() (Not Regularly Used)
