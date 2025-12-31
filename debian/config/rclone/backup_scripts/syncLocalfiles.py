#!/usr/bin/env -S python -u

import argparse
from json import load
from pathlib import Path
from subprocess import run

SYNC_DATA: Path          = Path("~/.config/rclone/backup_scripts/sync_data.json").expanduser()
DEFAULT_REMOTE_NAME: str = "Gdrive"
ROOT_REMOTE_DIR: str     = "/rclone/Dhanno/"
GLOBAL_EXCLUDE: Path     = Path("~/.config/rclone/backup_scripts/exclude_files.txt").expanduser()

DRY_RUN: bool         = False
ONLY_FILES: bool      = False
ONLY_DIRS: bool       = False
INTERACTIVE: bool     = False
CONFIRM_SYNC: bool    = False
LOG_FILE: None | str  = None
BW_LIMIT: None | str  = None

if not SYNC_DATA.exists():
	print(f"Missing: {SYNC_DATA}")
	exit(1)

SYNC_OBJECTS = load(SYNC_DATA.open())


def ask(q):
	return input(f"{q} [Y/n]: ").strip().lower() in ("", "y", "yes")


def restore(entry):
	local = Path(entry["local"]).expanduser()

	remote_name: str = entry.get("remote_name", DEFAULT_REMOTE_NAME)
	remote = f"{remote_name}:{ROOT_REMOTE_DIR}{entry['remote']}"

	cmd = [
		"rclone",
		"copy",
		remote,
		str(local),
		"-Pv"
	]

	print_mode = ""
	if DRY_RUN or entry.get("dry_run"):
		print_mode += " (Dry run)"
		cmd.append("--dry-run")

	print(f" ♻️  Restoring{print_mode} \"{entry.get('name', 'Unnamed')}\"")
	print(f"\t\t{local} <- {remote}")

	run(cmd)


def sync(entry):
	if not entry.get("enabled", True):
		return

	local = Path(entry["local"]).expanduser()
	if not local.exists():
		print(f"❌ Missing: {local}")
		return

	if ONLY_FILES and not local.is_file():
		return
	if ONLY_DIRS and not local.is_dir():
		return

	if INTERACTIVE and not ask(f"Sync {local}?"):
		return

	mode = entry.get("mode", "sync")
	remote_name: str = entry.get("remote_name", DEFAULT_REMOTE_NAME)
	remote = f"{remote_name}:{ROOT_REMOTE_DIR}{entry['remote']}"

	print_mode = mode
	if DRY_RUN or entry.get("dry_run"):
		print_mode += " --dry-run"

	print(f" ☁️  {entry.get('name', 'Unnamed')} ({print_mode})")
	print(f"\t{local} → {remote}")

	cmd = ["rclone", mode, "-Pv"]

	if DRY_RUN or entry.get("dry_run"):
		cmd.append("--dry-run")
	if entry.get("checksum"):
		cmd.append("--checksum")
	if entry.get("ignore_existing"):
		cmd.append("--ignore-existing")

	if not entry.get("delete", True):
		cmd.append("--ignore-existing")

	bw = entry.get("bwlimit") or BW_LIMIT
	if bw:
		cmd.append(f"--bwlimit={bw}")

	exc: Path = Path(entry.get("exclude")).expanduser()
	cmd += (
		["--exclude-from", str(exc)] if exc else ["--exclude-from", str(GLOBAL_EXCLUDE)]
	)

	if LOG_FILE:
		cmd += ["--log-file", LOG_FILE]

	cmd += [str(local), remote]

	if CONFIRM_SYNC and mode == "sync":
		if not ask("⚠️  Confirm destructive sync?"):
			return

	# print(cmd)
	run(cmd)


parser = argparse.ArgumentParser(
	description="Powerful rclone-based backup tool for syncing selected local files and directories to (rclone's Remotes)",
	formatter_class=argparse.ArgumentDefaultsHelpFormatter,
)

parser.add_argument(
	"--list", "-L",
	action="store_true",
	help="List all configured backup entries and exit",
)

parser.add_argument(
	"--dry-run", "-n",
	action="store_true",
	help="Show what would be transferred without making any changes",
)

parser.add_argument(
	"--edit-json", "-E",
	action="store_true",
	help="Edit the JSON Configured Backup Entries",
)

parser.add_argument(
	"--only-files",
	action="store_true",
	help="Process only file entries (skip directories)",
)

parser.add_argument(
	"--only-dirs",
	action="store_true",
	help="Process only directory entries (skip files)",
)

parser.add_argument(
	"--interactive", "-i",
	action="store_true",
	help="Ask confirmation before syncing each entry",
)

parser.add_argument(
	"--confirm-sync",
	action="store_true",
	help="Require confirmation before any destructive sync operation",
)

parser.add_argument(
	"--log",
	metavar="FILE",
	help="Write detailed rclone logs to the specified file",
)

parser.add_argument(
	"--bwlimit",
	metavar="RATE",
	help="Limit upload bandwidth (e.g. 500k, 2M, 10M)",
)

sub = parser.add_subparsers(
	dest="cmd",
	help="Available subcommands",
)

sub.add_parser(
	"index",
	aliases=["I"],
	help="Sync only specific index numbers"
).add_argument(
	"idx",
	type=int,
	nargs="+",
	metavar="IDX",
	help="One or more index numbers to sync",
)

sub.add_parser(
	"restore",
	aliases=["R"],
	help="Remote only specific index numbers"
).add_argument(
	"idx",
	type=int,
	nargs="+",
	metavar="IDX",
	help="One or more index numbers to remote",
)

args = parser.parse_args()

DRY_RUN      = args.dry_run
ONLY_FILES   = args.only_files
ONLY_DIRS    = args.only_dirs
INTERACTIVE  = args.interactive
CONFIRM_SYNC = args.confirm_sync
LOG_FILE     = args.log
BW_LIMIT     = args.bwlimit

if args.edit_json:
	run(
		[
			f"$EDITOR {str(SYNC_DATA)}",
		],
		shell=True,
	)
	exit(0)

if args.list:
	print("\n📦 Configured Backup Entries\n" + "─" * 60)
	for i, e in enumerate(SYNC_OBJECTS):
		name   = e.get("name", "Unnamed")
		mode   = e.get("mode", "sync")
		en     = "✔  Enabled" if e.get("enabled", True) else "✘  Disabled"
		local  = Path(e["local"]).expanduser()
		type   = "  Folder" if local.is_dir() else "  File"
		remote = f"{e.get('remote_name', DEFAULT_REMOTE_NAME)}:{ROOT_REMOTE_DIR}{e['remote']}"
		desc   = e.get("description")

		print(f"[{i:02}] {name}")
		print(f"     Mode    : {mode}")
		print(f"     Status  : {en}")
		print(f"     Local   : {local}")
		print(f"     Type    : {type}")
		print(f"     Remote  : {remote}")
		if desc:
			print(f"     Info    : {desc}")
		print("")

	print("─" * 60)
	exit(0)


# =================================================
if args.cmd in ("index", "I"):
	total_object: int = len(args.idx)
	for i, e in enumerate(args.idx, 1):
		print(f"[{i}/{total_object}]", end=" ")
		sync(SYNC_OBJECTS[e])
	exit(0)

if args.cmd in ("restore", "R"):
	total_object: int = len(args.idx)
	for i, e in enumerate(args.idx, 1):
		print(f"[{i}/{total_object}]", end=" ")
		restore(SYNC_OBJECTS[e])
	exit(0)
# =================================================


total_object: int = len(SYNC_OBJECTS)
for i, e in enumerate(SYNC_OBJECTS, 1):
	print(f"[{i}/{total_object}]", end=" ")
	sync(e)
