# dotfiles

Personal configuration files managed with a custom symlink-based deployment system. Supports macOS (`darwin/`) and Debian (`debian/`).

## Structure

| Path | Description |
|------|-------------|
| `darwin/` | macOS configuration (primary platform) |
| `debian/` | Debian/Linux configuration |
| `global/` | Platform-agnostic templates, scripts, and libraries |
| `unix/` | Cross-platform references and diagnostics guide |
| `windows/` | Windows (placeholder) |

Each platform directory follows the same layout:

```
<platform>/
  install.zsh            -- Main setup script
  update.sh              -- Backup/update script
  config/                -- Per-tool config directories (50+ tools)
  etc/                   -- System-level rc files (.bashrc, .curlrc, etc.)
  bin_scripts/           -- Custom utility scripts (deployed to ~/.local/bin)
  hooks/                 -- Symlink engine and automation scripts
  auto_generated/        -- System state backups
```

## Deployment

Dotfiles are deployed via a custom Python symlink engine. Platform manifests (`hooks/config_link.json`) map source paths to target locations.

### macOS

```sh
git clone https://github.com/pritam12426/dotfile.git ~/Developer/git_repository/dotfiles
cd dotfiles/darwin
export DOT_FILE="$PWD"
./install.zsh
```

### Debian

Same pattern — see `debian/README.md` for details.

## Tools Configured

**Shell:** Zsh (modular), Bash, Fish · **Multiplexers:** tmux, Zellij
**Editors:** Neovim, Helix, Zed · **Git** (with binary diff drivers)
**File Managers:** lf, joshuto, nnn, broot
**Prompt:** Starship (Nord palette)
**System:** btop, htop, fastfetch, glance, ncdu
**Download/Media:** aria2, yt-dlp, gallery-dl, mpv, qBittorrent
**Email/Reading:** himalaya, newsboat, shiori, readeck
**Languages:** Rust/Cargo, Node/npm, Python/pip/uv, TOML/taplo, ruff
**Security:** rclone, wireproxy, KeePassXC
**Task Management:** taskwarrior, tealdeer
**Code Quality:** clang-format, tidy

Custom scripts (42) and static binaries (31) are available in `bin_scripts/` and `binary_exe/` respectively.

## GUI Backups (macOS)

dotmason manages declarative backups of GUI app preferences (IINA, Stats, Telegram, Terminal, etc.) via TOML manifests.

## References

See [REFERENCES.md](REFERENCES.md) for TUI/CLI resource links.

## License

MIT
