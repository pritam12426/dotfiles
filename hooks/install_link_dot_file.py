#!/usr/bin/env python3 -u

from json import load
from os import environ
from pathlib import Path
from sys import argv

DOT_FILE_ROOT: Path = Path(environ["DOT_FILE"])
CONFIG_LINKS_FILE: Path = DOT_FILE_ROOT / "hooks" / "config_link.json"

DRY_RUN = any(flag in argv for flag in ("--dry-run", "-n", "--dry"))

with CONFIG_LINKS_FILE.open("r") as f:
	CONFIG_LINKS = load(f)


def make_link(source: Path, target: Path) -> None:
	if not source.exists():
		print(f"❌ Missing source: $DOT_FILE/{source.relative_to(DOT_FILE_ROOT)}")
		return

	if target.is_symlink():
		if target.resolve() == source.resolve():
			# print(f"✔️  Already linked: {target}")
			return

		if not DRY_RUN:
			target.unlink()

	elif target.exists():
		print(f"‼️  Skipped (real file exists): {target}")
		return

	target.parent.mkdir(parents=True, exist_ok=True)
	relative_source = source.relative_to(DOT_FILE_ROOT)
	relative_target = target.relative_to(Path("~").expanduser())
	if DRY_RUN:
		print(f"[DRY] ~/{relative_target} -> $DOT_FILE/{relative_source}")
	else:
		print(f"✅ ~/{relative_target} -> $DOT_FILE/{relative_source}")
		target.symlink_to(source)


def link_targeted_files(data: dict) -> None:
	source_root = DOT_FILE_ROOT / data["dot_file_source_dir"]
	target_root = Path(data["system_target_dir"]).expanduser()
	ignores: list[str] = data.get("ignores", [])

	if not source_root.exists():
		print("❌ Not in you $DOT_FILE")
		return

	for name, mapped in data["link_files"].items():
		source = source_root / name

		if any(x in name for x in ignores):
			print(f"⚠️  Ignored {name}")
			continue

		target = target_root / (mapped or name)
		make_link(source, target)


def link_all_files(data: dict) -> None:
	dot_source = DOT_FILE_ROOT / data["dot_file_source_dir"]
	target_root = Path(data["system_target_dir"]).expanduser()
	ignores: list[str] = data.get("ignores", [])

	if not dot_source.exists():
		print("❌ Not in you $DOT_FILE")
		return

	for item in dot_source.iterdir():
		target = target_root / item.name

		if (str(item.name).startswith(".")):
			print(f"⛔️ IGNOREING $DOT_FILE/{item.relative_to(DOT_FILE_ROOT)}")
			continue

		if any(x in item.name for x in ignores):
			print(f"⚠️  Ignoring $DOT_FILE/{item.relative_to(DOT_FILE_ROOT)}")
			continue

		make_link(item, target)


for cfg in CONFIG_LINKS:
	print(f"⚒️  Workng dir $DOT_FILE/{cfg['dot_file_source_dir']}")
	if cfg["link_files"] is None:
		link_all_files(cfg)
	else:
		link_targeted_files(cfg)

	print()
