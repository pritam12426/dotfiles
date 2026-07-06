#!/usr/bin/env python3 -u

import argparse
import logging
import re
import subprocess
from pathlib import Path

TEMP_FILE_DIFF_FILE: Path = Path("/tmp/fix-uglyname.diff")


def format_string(_text: str) -> str:
	_new_text = re.sub(r"[^\x00-\x7F]+", "", _text)
	_new_text = re.sub(r"_+", "_", _new_text)
	_new_text = re.sub(r" +", "_", _new_text)

	for _i in r"!#$%&'()*,-./:;<=>?@[]^_`{|}~":
		if f"_{_i}" in _new_text:
			_new_text = _new_text.replace(f"_{_i}", f"{_i}")

		if f"{_i}_" in _new_text:
			_new_text = _new_text.replace(f"{_i}_", f"{_i}")

		if f"{_i}{_i}" in _new_text:
			_new_text = _new_text.replace(f"{_i}{_i}", _i)

	return _new_text.removesuffix("_").removeprefix("_").lower().replace(".", "_")


def rename_file(old_name: str) -> str:
	split_name = old_name.rsplit(".", maxsplit=1)

	if len(split_name) == 2:
		return f"{format_string(split_name[0])}.{split_name[1].lower()}"

	return format_string(split_name[0])


def print_name_diff(old: str, new: str) -> None:
	diff_text: str = ""

	# Header ONLY once (first call)
	# if not TEMP_FILE_DIFF_FILE.exists():
	# 	diff_text += "--- old\n"
	# 	diff_text += "+++ new\n"

	diff_text += "@@ -1 +1 @@\n"
	diff_text += f"-{old}\n"
	diff_text += f"+{new}\n"
	diff_text += "\n"

	with TEMP_FILE_DIFF_FILE.open("a", encoding="utf-8") as f:
		f.write(diff_text)

# Summary variables
RENAMED_HOME_ITEM = 0
RENAMED_FILES_COUNT = 0
SKIPPED_HIDDEN_COUNT = 0
SKIPPED_IGNORED_COUNT = 0
RENAMED_FOLDERS_COUNT = 0


# Initialize arguments
parser = argparse.ArgumentParser(description="A tool for fixing ugly [ file / folder ] names")
parser.add_argument("-n", "--dry-run", action="store_true", help="Show what would be changed without renaming")
parser.add_argument("-s", "--summary", action="store_true", help="Show rename summary")
parser.add_argument("-f", "--force", action="store_true", help="Allow renaming items directly inside home directory")
parser.add_argument("-d", "--diff", action="store_true", help="Show the difference between the old and new names")
parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output")
parser.add_argument("-i", "--ignore", nargs="+", help="File or folder names to ignore")
parser.add_argument("paths", nargs="+", help="Files or directories to fix")
args = parser.parse_args()


# Setup logging
logging.basicConfig(
	level=logging.INFO,
	# format="\033[92m%(asctime)s\033[0m - %(levelname)s - %(message)s",
	format="%(message)s",
)


# Paths
HOME_PATH = Path.home()

IGNORE_PATH = {
	"CMakeCache.txt",
	"CMakeLists.txt",
	"Makefile",
}

if args.ignore:
	IGNORE_PATH.update(args.ignore)


IS_HOME = False


for path in args.paths:
	old_abs_path = Path(path)

	if not old_abs_path.exists():
		logging.warning(f"Path does not exist: {old_abs_path}")
		continue

	old_dir_path = old_abs_path.parent
	old_base_name = old_abs_path.name

	# Skip hidden
	if old_base_name.startswith("."):
		SKIPPED_HIDDEN_COUNT += 1
		logging.info(f"Skipping hidden file/folder: {old_abs_path}")
		continue

	# Protect home directory
	if old_dir_path == HOME_PATH:
		if not IS_HOME:
			logging.warning(f"This file is not permitted to change: {old_base_name}")
			IS_HOME = True

		if not args.force:
			logging.warning(f"Skipping home item: {old_base_name}")
			continue
		else:
			RENAMED_HOME_ITEM += 1

	# Ignore list
	if old_base_name in IGNORE_PATH:
		SKIPPED_IGNORED_COUNT += 1
		logging.info(f"Skipping ignored file/folder: {old_base_name}")
		continue

	# ---------------- FILE ----------------

	if old_abs_path.is_file():
		new_file_base_name = rename_file(old_base_name)

		if new_file_base_name != old_base_name:
			new_abs_path = old_dir_path / new_file_base_name

			if new_abs_path.exists():
				if args.verbose:
					logging.error(f"Target already exists: {new_abs_path}")
				continue

			if args.verbose:
				logging.info(f"Renamed file: {old_base_name} → {new_file_base_name}")

			if args.diff:
				print_name_diff(old_base_name, new_file_base_name)

			if args.dry_run:
				logging.warning(f"[DRY-RUN] file: {old_base_name} → {new_file_base_name}")

			RENAMED_FILES_COUNT += 1

			if not args.dry_run and not args.diff:
				old_abs_path.rename(new_abs_path)

		elif args.verbose:
			logging.info(f"No change for file: {old_base_name}")

	# ---------------- FOLDER ----------------

	elif old_abs_path.is_dir():
		new_folder_name = format_string(old_base_name)

		if new_folder_name != old_base_name:
			new_abs_path = old_dir_path / new_folder_name

			if new_abs_path.exists():
				if args.verbose:
					logging.error(f"Target already exists: {new_abs_path}")
				continue

			if args.verbose:
				logging.info(f"Renamed folder: {old_base_name} → {new_folder_name}")

			if args.diff:
				print_name_diff(old_base_name, new_folder_name)

			if args.dry_run:
				logging.warning(f"[DRY-RUN] folder: {old_base_name} → {new_folder_name}")

			RENAMED_FOLDERS_COUNT += 1

			if not args.dry_run and not args.diff:
				old_abs_path.rename(new_abs_path)

		elif args.verbose:
			logging.info(f"No change for folder: {old_base_name}")


if args.diff and TEMP_FILE_DIFF_FILE.exists():
	subprocess.run(["diff-so-fancy", "--patch"], stdin=TEMP_FILE_DIFF_FILE.open())
	TEMP_FILE_DIFF_FILE.unlink(missing_ok=True)

# Summary
if args.summary:
	print("\n===== Summary =====")
	print(f"Renamed files:          {RENAMED_FILES_COUNT}")
	print(f"Renamed folders:        {RENAMED_FOLDERS_COUNT}")
	print(f"Skipped hidden items:   {SKIPPED_HIDDEN_COUNT}")
	print(f"Skipped ignored items:  {SKIPPED_IGNORED_COUNT}")
	print(f"Renamed home items:     {RENAMED_HOME_ITEM}")
	print("=====================")
