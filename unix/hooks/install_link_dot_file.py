#!/usr/bin/env python3 -u

"""
install_link_dot_file.py — symlink dotfiles into system locations

Reads $DOT_FILE/hooks/config_link.json and creates symlinks from the
dotfiles repo into the correct system paths.

Usage:
  install_link_dot_file.py [options]

Options:
  -n, --dry-run         Preview changes without writing anything
  -v, --verbose         Show already-linked and skipped entries too
  --force               Overwrite real files (not just stale symlinks)
  --unlink              Remove all symlinks this script would create
  --status              Report link state without making any changes
  --only <section>      Run only the entry whose dot_file_source_dir matches
  -h, --help            Show this help
"""

import argparse
import sys
from json import load
from os import environ
from pathlib import Path

# ── Resolve dotfile root ───────────────────────────────────────────────────────


def get_dot_file_root() -> Path:
	raw = environ.get("DOT_FILE", "")
	if not raw:
		print("❌  $DOT_FILE is not set.", file=sys.stderr)
		sys.exit(1)
	p = Path(raw)
	if not p.exists():
		print(f"❌  $DOT_FILE does not exist: {p}", file=sys.stderr)
		sys.exit(1)
	return p


DOT_FILE_ROOT: Path = get_dot_file_root()
CONFIG_LINKS_FILE: Path = DOT_FILE_ROOT / "hooks" / "config_link.json"

# ── ANSI helpers ───────────────────────────────────────────────────────────────

R = "\033[0m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"
DIM = "\033[2m"
BOLD = "\033[1m"


def ok(msg: str) -> None:
	print(f"  {GREEN}✔{R}  {msg}")


def skip(msg: str) -> None:
	print(f"  {YELLOW}–{R}  {DIM}{msg}{R}")


def fail(msg: str) -> None:
	print(f"  {RED}✘{R}  {msg}", file=sys.stderr)


def info(msg: str) -> None:
	print(f"  {CYAN}i{R}  {DIM}{msg}{R}")


def dry(msg: str) -> None:
	print(f"  {YELLOW}~{R}  {msg}")


def verbose(msg: str, show: bool) -> None:
	if show:
		print(f"  {DIM}·  {msg}{R}")


# ── Summary tracker ────────────────────────────────────────────────────────────


class Summary:
	def __init__(self) -> None:
		self.linked = 0
		self.already = 0
		self.skipped = 0
		self.failed = 0
		self.unlinked = 0
		self.repaired = 0
		self.broken = 0

	def print(self, mode: str) -> None:
		print(f"\n{BOLD}Summary{R}")
		print("─" * 40)
		if mode == "unlink":
			print(f"  {GREEN}Unlinked {R}   {self.unlinked}")
			print(f"  {YELLOW}Skipped  {R}   {self.skipped}")
			print(f"  {RED}Failed   {R}   {self.failed}")
		elif mode == "status":
			print(f"  {GREEN}Linked   {R}   {self.already}")
			print(f"  {RED}Broken   {R}   {self.broken}")
			print(f"  {YELLOW}Missing  {R}   {self.failed}")
			print(f"  {YELLOW}Skipped  {R}   {self.skipped}")
		else:
			print(f"  {GREEN}Linked   {R}   {self.linked}")
			print(f"  {GREEN}Repaired {R}   {self.repaired}")
			print(f"  {DIM}Already  {R}   {self.already}")
			print(f"  {YELLOW}Skipped  {R}   {self.skipped}")
			print(f"  {RED}Failed   {R}   {self.failed}")
		print()


# ── Core link / unlink / status logic ─────────────────────────────────────────


def short(path: Path) -> str:
	"""Return a human-friendly path: ~/... for home paths, else absolute."""
	try:
		return f"~/{path.relative_to(Path.home())}"
	except ValueError:
		return str(path)


def dot_rel(path: Path) -> str:
	"""Return $DOT_FILE/... relative label."""
	try:
		return f"$DOT_FILE/{path.relative_to(DOT_FILE_ROOT)}"
	except ValueError:
		return str(path)


def make_link(
	source: Path,
	target: Path,
	*,
	dry_run: bool,
	force: bool,
	verbose_on: bool,
	summary: Summary,
) -> None:
	label = f"{short(target)} → {dot_rel(source)}"

	# ── Source missing ─────────────────────────────────────────────────────────
	if not source.exists():
		# Check if target is a broken symlink pointing nowhere
		if target.is_symlink() and not target.exists():
			fail(f"Broken symlink (source gone): {short(target)}")
			summary.broken += 1
		else:
			fail(f"Missing source: {dot_rel(source)}")
			summary.failed += 1
		return

	# ── Target is a symlink ────────────────────────────────────────────────────
	if target.is_symlink():
		if target.resolve() == source.resolve():
			verbose(f"Already linked: {label}", verbose_on)
			summary.already += 1
			return

		# Stale symlink — points somewhere else; repair it
		if dry_run:
			dry(f"Would repair stale link: {label}")
		else:
			target.unlink()
			target.symlink_to(source)
			ok(f"Repaired: {label}")
		summary.repaired += 1
		return

	# ── Target is a real file or directory ────────────────────────────────────
	if target.exists():
		if force:
			if dry_run:
				dry(f"Would overwrite (--force): {label}")
			else:
				target.unlink() if target.is_file() else __import__("shutil").rmtree(target)
				target.parent.mkdir(parents=True, exist_ok=True)
				target.symlink_to(source)
				ok(f"Forced: {label}")
			summary.linked += 1
		else:
			skip(f"Real file exists (use --force to overwrite): {short(target)}")
			summary.skipped += 1
		return

	# ── Create new symlink ─────────────────────────────────────────────────────
	target.parent.mkdir(parents=True, exist_ok=True)
	if dry_run:
		dry(f"Would link: {label}")
	else:
		target.symlink_to(source)
		ok(f"Linked: {label}")
	summary.linked += 1


def remove_link(
	source: Path,
	target: Path,
	*,
	dry_run: bool,
	verbose_on: bool,
	summary: Summary,
) -> None:
	label = short(target)

	if not target.exists() and not target.is_symlink():
		verbose(f"Not present: {label}", verbose_on)
		summary.skipped += 1
		return

	if target.is_symlink():
		if target.resolve() == source.resolve():
			if dry_run:
				dry(f"Would remove: {label}")
			else:
				target.unlink()
				ok(f"Removed: {label}")
			summary.unlinked += 1
		else:
			skip(f"Symlink points elsewhere, leaving alone: {label}")
			summary.skipped += 1
	else:
		skip(f"Real file, not touching: {label}")
		summary.skipped += 1


def status_link(
	source: Path,
	target: Path,
	*,
	summary: Summary,
) -> None:
	label = f"{short(target)}"

	if target.is_symlink():
		if not target.exists():
			fail(f"Broken symlink: {label}  (target: {target.resolve()})")
			summary.broken += 1
		elif target.resolve() == source.resolve():
			info(f"OK      {label}")
			summary.already += 1
		else:
			skip(f"Points elsewhere: {label}  → {target.resolve()}")
			summary.skipped += 1
	elif target.exists():
		skip(f"Real file: {label}")
		summary.skipped += 1
	else:
		fail(f"Missing: {label}")
		summary.failed += 1


# ── Per-config-entry dispatchers ───────────────────────────────────────────────


def iter_targeted(data: dict):
	"""Yield (source, target) pairs for link_files entries."""
	source_root = DOT_FILE_ROOT / data["dot_file_source_dir"]
	target_root = Path(data["system_target_dir"]).expanduser()
	ignores: list[str] = data.get("ignores", [])

	if not source_root.exists():
		fail(f"Source dir not found: {dot_rel(source_root)}")
		return

	for name, mapped in data["link_files"].items():
		if any(x in name for x in ignores):
			yield "ignore", name, None, None
			continue
		source = source_root / name
		target = target_root / (mapped or name)
		yield "link", name, source, target


def iter_all(data: dict):
	"""Yield (source, target) pairs for all files in the source dir."""
	dot_source = DOT_FILE_ROOT / data["dot_file_source_dir"]
	target_root = Path(data["system_target_dir"]).expanduser()
	ignores: list[str] = data.get("ignores", [])

	if not dot_source.exists():
		fail(f"Source dir not found: {dot_rel(dot_source)}")
		return

	for item in sorted(dot_source.iterdir()):
		if item.name.startswith("."):
			yield "hidden", item.name, None, None
			continue
		if any(x in item.name for x in ignores):
			yield "ignore", item.name, None, None
			continue
		target = target_root / item.name
		yield "link", item.name, item, target


def process_entry(
	cfg: dict,
	*,
	mode: str,
	dry_run: bool,
	force: bool,
	verbose_on: bool,
	summary: Summary,
) -> None:
	section = cfg["dot_file_source_dir"]
	print(f"\n{BOLD}{section}{R}  {DIM}→ {cfg['system_target_dir']}{R}")

	iterator = iter_targeted(cfg) if cfg["link_files"] is not None else iter_all(cfg)

	for kind, name, source, target in iterator:
		if kind == "ignore":
			verbose(f"Ignored: {name}", verbose_on)
			summary.skipped += 1
			continue
		if kind == "hidden":
			verbose(f"Skipped hidden: {name}", verbose_on)
			summary.skipped += 1
			continue

		if mode == "unlink":
			remove_link(source, target, dry_run=dry_run, verbose_on=verbose_on, summary=summary)
		elif mode == "status":
			status_link(source, target, summary=summary)
		else:
			make_link(source, target, dry_run=dry_run, force=force, verbose_on=verbose_on, summary=summary)


# ── CLI ────────────────────────────────────────────────────────────────────────


def build_parser() -> argparse.ArgumentParser:
	p = argparse.ArgumentParser(prog="install_link_dot_file")
	p.add_argument("-n", "--dry-run", action="store_true", help="Preview changes without writing anything")
	p.add_argument("-v", "--verbose", action="store_true", help="Show already-linked and ignored entries")
	p.add_argument("--force", action="store_true", help="Overwrite real files (not just stale symlinks)")
	p.add_argument("--unlink", "--remove", action="store_true", help="Remove all symlinks this script would create")
	p.add_argument("--status", action="store_true", help="Report link state without making any changes")
	p.add_argument("--only", metavar="SECTION", help="Run only the entry whose dot_file_source_dir matches")
	return p


# ── Main ───────────────────────────────────────────────────────────────────────


def main() -> None:
	parser = build_parser()
	args = parser.parse_args()

	# Mutual exclusion
	exclusive = [args.dry_run, args.unlink, args.status].count(True)
	if exclusive > 1:
		parser.error("--dry-run, --unlink, and --status are mutually exclusive.")
	if args.force and (args.unlink or args.status):
		parser.error("--force cannot be combined with --unlink or --status.")

	# Determine mode
	if args.status:
		mode = "status"
	elif args.unlink:
		mode = "unlink"
	else:
		mode = "link"

	# Load config
	try:
		with CONFIG_LINKS_FILE.open("r") as f:
			config_links = load(f)
	except FileNotFoundError:
		fail(f"Config not found: {CONFIG_LINKS_FILE}")
		sys.exit(1)
	except Exception as e:
		fail(f"Failed to read config: {e}")
		sys.exit(1)

	# Header
	mode_tag = ""
	if args.dry_run:
		mode_tag = f"  {YELLOW}[dry-run]{R}"
	if args.status:
		mode_tag = f"  {CYAN}[status]{R}"
	if args.unlink:
		mode_tag = f"  {RED}[unlink]{R}"
	print(f"\n{BOLD}install_link_dot_file{R}{mode_tag}")
	print(f"{DIM}  $DOT_FILE = {DOT_FILE_ROOT}{R}")

	summary = Summary()

	for cfg in config_links:
		section = cfg.get("dot_file_source_dir", "")
		if args.only and args.only != section:
			continue
		process_entry(
			cfg,
			mode=mode,
			dry_run=args.dry_run,
			force=args.force,
			verbose_on=args.verbose,
			summary=summary,
		)

	summary.print(mode)


if __name__ == "__main__":
	main()
