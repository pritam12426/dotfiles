# Dotmason

**dotmason** is a safe, declarative dotfiles & GUI application backup/restore utility powered by TOML manifests.

It allows you to:

* Back up and restore selected configuration files from your home directory.
* Run structured hooks before and after backup/restore.
* Preview operations using a tree view.
* Perform dry-runs for zero-risk testing.
* Diagnose missing files and backups with `doctor` mode.
* Operate only on selected configuration groups.

---

## Installation

Download the script and make the it executable:

```bash
mkdir -p ~/.local/bin/dotmason
cd ~/.local/bin/dotmason
curl -sSlf "https://raw.githubusercontent.com/pritam12426/dotfiles/refs/heads/main/darwin/hooks/dotmason/dotmason.py" -o "dotmason"
chmod +x dotmason.py
ln "$PWD/dotmason.py" ~/.local/bin/dotmason
```


---

## Environment Variable

dotmason requires a backup root directory defined using the `DOT_FILE` environment variable.

```bash
export DOT_FILE="$HOME/dotfiles"
```

All backups are stored inside:

```
$DOT_FILE/dotmason/
```

---

## Usage

```bash
dotmason [action] [groups...] [options]
```

### Actions

| Action  | Description                            |
| ------- | -------------------------------------- |
| backup  | Backup dotfiles (default)              |
| restore | Restore dotfiles from backup           |
| doctor  | Check missing source files and backups |

### Options

| Flag          | Description                                |
| ------------- | ------------------------------------------ |
| -n, --dry-run | Show operations without modifying anything |
| --tree        | Preview file operations as a tree          |
| --no-hooks    | Disable all hooks                          |

---

## Examples

Backup everything:

```bash
dotmason
```

Restore only `zsh` and `git` groups:

```bash
dotmason restore zsh git
```

Dry-run with tree preview:

```bash
dotmason backup --tree -n
```

Run doctor mode:

```bash
dotmason doctor
```

---

## Project Layout

```
dotmason/
├── dotmason.py
├── zsh.toml
├── git.toml
└── vscode.toml
```

Each `.toml` file represents a **configuration group**.

---

## TOML Manifest Structure

Each TOML file **must** contain:

| Key                   | Type   | Required |
| --------------------- | ------ | -------- |
| `name`                | string | ✅ Yes    |
| `configuration_files` | array  | ✅ Yes    |

Other fields are optional and may be omitted or set to `null`.

---

### Minimal Example

```toml
name = "zsh"
description = "Zsh configuration files"

configuration_files = [
	".zshrc",
	".zprofile",
	".config/zsh/aliases.zsh"
]
```

---

### Full Example

```toml
name = "git"
description = "Git configuration files"

configuration_files = [
	".gitconfig",
	".config/git/ignore"
]

[hooks.pre_backup]
	steps = [
		{ command = "git", args = ["status"], silent = true }
	]
	
[hooks.post_backup]
	steps = [
		{ command = "echo", args = ["Git backuping successfully"] }
	]



[hooks.pre_restore]
	steps = [
		{ command = "echo", args = ["Git restoring some files"] }
	]

[hooks.post_restore]
	steps = [
		{ command = "echo", args = ["Git restored successfully"] }
	]
```

---

## Hooks System

Hooks allow you to run commands before or after backup and restore.

Supported hook stages:

* `pre_backup`
* `post_backup`
* `pre_restore`
* `post_restore`

### Hook Format

```toml
[hooks.pre_backup]
steps = [
  { command = "echo", args = ["Preparing backup..."], silent = false }
]
```

| Field   | Type    | Description                      |
| ------- | ------- | -------------------------------- |
| command | string  | Executable command name          |
| args    | array   | Optional command arguments       |
| silent  | boolean | Suppress output (default: false) |

---

## Backup Layout

Backups are stored in:

```
$DOT_FILE/dotmason/<relative_path_from_home>
```

Example:

```
~/.zshrc        →  $DOT_FILE/dotmason/.zshrc
~/.config/git/ignore → $DOT_FILE/dotmason/.config/git/ignore
```

---

## Doctor Mode

Doctor checks both system and backup health:

```bash
dotmason doctor
```

Example output:

```
Checking `zsh`
 ❌ Missing source: ~/.zprofile
 ⚠️  No backup: $DOT_FILE/dotmason/.zshrc
```

---

## Safety

* Dry-run mode prevents any filesystem change.
* Tree mode previews every operation before execution.
* Hooks can be fully disabled with `--no-hooks`.
