#!/usr/bin/env python3

"""
dotmason — Safe dotfiles / GUI application backup & restore utility.

Features:
- Backup and restore dotfiles defined in TOML manifests
- Structured hook system (pre/post backup & restore)
- Dry-run mode for zero-risk preview
- Tree preview mode
- Doctor mode to detect missing configs
- Selective group operations

Author: Pritam Kumar <84720825+pritam12426@users.noreply.github.com>   <github.com/pritam12426>
"""

import argparse
import subprocess
from os import environ
from pathlib import Path
from shutil import copy2
from sys import path
from tomllib import load

parser = argparse.ArgumentParser(prog="dotmason", description="Dotfiles backup & restore tool")
parser.add_argument("action", choices=["backup", "restore", "doctor"], nargs="?", default="backup")
parser.add_argument("groups", nargs="*", help="Operate only on given config names")
parser.add_argument("-n", "--dry-run", action="store_true", help="Dry run mode")
parser.add_argument("-F", "--force", action="store_true", help="Over ride the existing file")
parser.add_argument("--tree", action="store_true", help="Preview file operations as tree")
parser.add_argument("--no-hooks", action="store_true", help="Do not run any hooks")
args = parser.parse_args()

DRY_RUN: bool = args.dry_run
RESTORE: bool = args.action == "restore"
DOCTOR: bool = args.action == "doctor"
FORCE: bool = args.force
ONLY_GROUPS: set = set(args.groups)
NO_RUN_HOOKS: bool = False

WORKING_DIR: Path = Path(path[0])
CONFIGURATION_FILES_DATA: list[dict] = []

DOT_ENV = environ.get("DOT_FILE")
if not DOT_ENV:
	parser.error("❌ DOT_FILE environment variable not set")

DOT_FILES_DIR = Path(DOT_ENV).expanduser()


def restore_confnig_file(data: dict) -> None:
	SOURCE_ROOT = Path(DOT_FILES_DIR) / "dotmason"
	TARGET_ROOT = Path("~").expanduser()

	for rel in data["configuration_files"]:
		source_file: Path = SOURCE_ROOT / rel
		target_file: Path = TARGET_ROOT / rel

		if not source_file.is_file():
			print(
				f"[Skip] Missing backup file `{data['name']}`  $DOT_FILE/dotmason/{rel}"
			)
			continue

		if DRY_RUN:
			print(f"[Dry] Restoring `{data['name']}` $DOT_FILE/{rel}")
			continue

		target_file.parent.mkdir(parents=True, exist_ok=True)
		print(f"Restoring `{data['name']}` $DOT_FILE/{rel}")

		# Perform the actual backup
		try:
			target_file.parent.mkdir(parents=True, exist_ok=True)
			copy2(source_file, target_file)
			print(f"✅ Backed up `{data['name']}`: ~/{rel}")
		except Exception as e:
			print(f"❌ Error backing up {rel}: {e}")


def backup_config_file(data: dict) -> None:
	SOURCE_ROOT = Path("~").expanduser()
	TARGET_ROOT = Path(DOT_FILES_DIR) / "dotmason"

	# We use this to track if we should skip the rest of THIS package
	decision: bool | None = None

	for rel in data["configuration_files"]:
		source_file: Path = SOURCE_ROOT / rel
		target_file: Path = TARGET_ROOT / rel

		# 1. Check if source exists
		if not source_file.is_file():
			print(f"❌ [Skip] Missing source: ~/{rel}")
			continue

		# 2. Handle Dry Run
		if DRY_RUN:
			print(f"🔍 [Dry] Would backup ~/{rel}")
			continue

		# 3. Handle Overwrite Logic
		if target_file.exists() and not FORCE:
			# If we already decided to skip all for this package
			if decision is False:
				print(f"⏭️  Skipping ~/{rel}")
				continue

		# If we haven't asked yet, ask now
		if decision is None and not FORCE:
			resp = input(f"⚠️  Files for '{data['name']}' already exist. Overwrite all? [y/N]: ").lower()
			decision = (resp == "y")

			if not decision:
				print(f"⏭️  Skipping ~/{rel}")
				continue

		# 4. Perform the actual backup
		try:
			target_file.parent.mkdir(parents=True, exist_ok=True)
			copy2(source_file, target_file)
			print(f"✅ Backed up `{data['name']}`: ~/{rel}")
		except Exception as e:
			print(f"❌ Error backing up {rel}: {e}")


def doctor(data: dict):
	print(f"\nChecking `{data['name']}`")
	home = Path("~").expanduser()
	backup = Path(DOT_FILES_DIR) / "dotmason"

	for rel in data["configuration_files"]:
		src = home / rel
		bak = backup / rel

		if not src.exists():
			print(f" ❌ Missing source: ~/{rel}")
		if not bak.exists():
			print(f" ⚠️  No backup: $DOT_FILE/dotmason/{rel}")


def run_hooks(data: dict, stage: str):
	if NO_RUN_HOOKS:
		print("Hooks disabled — skipping '%s' for `%s`" % (stage, data["name"]))
		return

	hooks = data.get("hooks", {}).get(stage, {}).get("steps", [])

	for step in hooks:
		cmd = [step["command"], *step.get("args", [])]
		silent = step.get("silent", False)

		print(f"[Hook:{stage}] {cmd[0]} ...", "[silent]" if silent else "")

		if DRY_RUN:
			continue

		try:
			subprocess.run(
				cmd,
				stdout=subprocess.DEVNULL if silent else None,
				stderr=subprocess.DEVNULL if silent else None,
				check=True,
			)
		except subprocess.CalledProcessError as e:
			print(f"[Hook failed] {e.cmd}\n{e.stderr.decode()}")


def print_tree(data: dict):
	if RESTORE:
		SOURCE_ROOT: str = "$DOT_FILE/" + "dotmason"
		TARGET_ROOT: str = "~/"
		mode = "RESTORE"
	else:
		SOURCE_ROOT: str = "~/"
		TARGET_ROOT = "$DOT_FILE/" + "dotmason"
		mode = "BACKUP"

	print(f"\n[{mode}] {data['name']}")
	for rel in data["configuration_files"]:
		src = SOURCE_ROOT + rel
		dst = TARGET_ROOT + rel
		print(f"  {src}  →  {dst}")


for i in WORKING_DIR.iterdir():
	if i.name.endswith(".toml"):
		with i.open("rb") as f:
			CONFIGURATION_FILES_DATA.append(load(f))
	# Todo: add try catch

# Todo: add a def for validating the file

if ONLY_GROUPS:
	CONFIGURATION_FILES_DATA = [
		c for c in CONFIGURATION_FILES_DATA if c.get("name", "").lower() in ONLY_GROUPS
	]

if args.no_hooks:
	NO_RUN_HOOKS = True

# ────────────────────────────────────────────────────────────────
# Main execution loop — processes every TOML config
# ────────────────────────────────────────────────────────────────
try:
	for cfg in CONFIGURATION_FILES_DATA:
		if description := cfg.get("description"):
			print(f'\nConfig description: "{description}"')

		# Tree preview mode — no filesystem changes
		if args.tree:
			print_tree(cfg)
			continue

		# Doctor mode — only validate system health
		if DOCTOR:
			doctor(cfg)
			continue

		# Backup mode
		if not RESTORE:
			run_hooks(cfg, "pre_backup")
			backup_config_file(cfg)
			run_hooks(cfg, "post_backup")

		# Restore mode
		else:
			run_hooks(cfg, "pre_restore")
			restore_confnig_file(cfg)
			run_hooks(cfg, "post_restore")
except KeyboardInterrupt:
	print("\n\n🛑 Operation cancelled by user. 👋 Goodbye! ...")
	exit(130)
