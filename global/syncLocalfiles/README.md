# pushfile

> A fast & lightweight rclone wrapper for syncing local files to remote storage.

`pushfile` is a small C program that lets you declare your sync targets once in a config file and push them to any remote supported by [rclone](https://rclone.org) with a single command.

---

## Requirements

- **C17** compiler (gcc or clang)
- **rclone** installed and configured (`rclone config`)
- **argp** — built into glibc on Linux; install via `brew install argp-standalone` on macOS

---

## Build

```sh
make          # optimised release build
make debug    # debug build with -g3 -DDEBUG
make install  # install to /usr/local/bin (use PREFIX= to override)
make clean
```

---

## Configuration

All sync targets are defined in `src/config_array.c`. Each entry is a `Config_entity` struct:

```c
Config_entity G_all_configs[] = {
    {
        .target_name          = "zsh_config",
        .local_path           = "/home/user/.config/zsh",
        .remote_location      = "Gdrive:/rclone/backups/",
        .exclude_file_pattern = NULL,          // path to rclone exclude-from file, or NULL
        .bwlimit              = NULL,          // e.g. "10M", or NULL for unlimited
        .delete_on_remote     = false,         // mirror deletions to remote
        .checksum             = false,         // use checksums instead of mod-time
        .description          = "Z shell config",
    },

    { 0 }  // sentinel — must stay last
};
```

### Field reference

| Field | Required | Description |
|---|---|---|
| `target_name` | yes | Short identifier used in logs and `--list` output |
| `local_path` | yes | Absolute path to the local file or directory to sync |
| `remote_location` | yes | rclone remote destination (e.g. `Gdrive:/path/`) |
| `exclude_file_pattern` | no | Path to an [rclone exclude file](https://rclone.org/filtering/); skipped if `NULL` |
| `bwlimit` | no | Bandwidth cap passed to rclone (e.g. `"5M"`); `NULL` = unlimited |
| `delete_on_remote` | no | If `true`, files deleted locally are also deleted on the remote |
| `checksum` | no | If `true`, uses checksums for change detection instead of mod-time + size |
| `description` | no | Human-readable description shown in `--detailed` output |

> **Note:** `_type` (directory vs regular file) is detected automatically by `validate_config()` at startup via `stat()`. You do not need to set it.

### Global rclone options

Extra flags applied to every rclone call can be set in `src/project_config.h`:

```c
#define RCLONE_OPT "--transfers 4 --retries 3"
```

---

## Usage

```
pushfile [OPTION...] [TARGET(s)...]
```

### Options

| Flag | Short | Description |
|---|---|---|
| `--list` | `-l` | List all valid sync targets |
| `--detailed` | `-d` | List targets with full details |
| `--index INDEX` | `-I` | Sync only the entry at INDEX |
| `--dry-run` | `-n` | Show what would change without making any changes |
| `--only-dir` | `-D` | Sync directory entries only |
| `--only-file` | `-F` | Sync regular file entries only |
| `--interactive` | `-i` | Prompt before each sync |
| `--bwlimit LIMIT` | `-B` | Override bandwidth limit (e.g. `10M`) |
| `--log-level LEVEL` | `-L` | Set log verbosity: `error`, `warn`, `info` (default), `debug` |

### Examples

```sh
# Sync everything
pushfile

# See what would be synced without making changes
pushfile --dry-run

# List all configured targets
pushfile --list
pushfile --detailed

# Sync only the entry at index 0
pushfile --index 0

# Sync only directories, with a bandwidth cap
pushfile --only-dir --bwlimit 5M

# Interactive mode — confirm each target before syncing
pushfile --interactive

# Verbose debug output
pushfile --log-level debug
```

---

## How it works

1. At startup, `validate_config()` walks every entry in `G_all_configs[]` and checks:
   - `local_path` exists on disk (determines whether it is a file or directory)
   - `remote_location` is non-empty
   - `exclude_file_pattern`, if set, exists on disk
   - Entries that fail any check are skipped with a warning.
2. The valid entries are collected into `G_all_valid_configs[]`.
3. For each entry selected by the CLI flags, `run_rclone_IPC()` forks a child process and `execvp`s `rclone sync` with the appropriate arguments.
4. The parent waits for each child and reports success or failure.

---

## Project structure

```
src/
├── main.c            # CLI argument parsing, sync loop
├── config.h          # Config_entity struct, validate_config() declaration
├── config.c          # validate_config(), print_config(), print_config_detailed()
├── config_array.h    # extern declarations for G_all_configs and related arrays
├── config_array.c    # The actual sync target definitions — edit this file
├── runner.h          # run_rclone_IPC() declaration
├── runner.c          # fork+execvp rclone subprocess implementation
├── log.h             # LOG_ERROR / LOG_WARN / LOG_INFO / LOG_DEBUG macros
├── log.c             # push_file_log() implementation
└── project_config.h  # Version, name, global rclone options
```

---

## License

See [LICENSE](LICENSE).