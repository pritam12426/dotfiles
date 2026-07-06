#!/usr/bin/env python3

"""
link_common.py — mirror files from cwd into one or more target directories
as relative symlinks.

Walks the current directory recursively and, for every file, creates a
relative symlink in each target directory at the matching relative path.
"""

import argparse
import os
import shutil
import sys
from fnmatch import fnmatch
from pathlib import Path

# ── Defaults ───────────────────────────────────────────────────────────────────

DEFAULT_TARGETS = ["../darwin", "../debian"]
# DEFAULT_TARGETS = ["../temp"]
DEFAULT_EXCLUDES = [
	"linux-macos-diagnostics.md",
	"/README.md",
	".git",
	".DS_Store",
	".git/*",
	"temp*",
	"Temp*",
	"node_modules",
	"node_modules/*",
	"__pycache__",
	"__pycache__/*",
	"*.pyc",
]

# ── ANSI helpers ───────────────────────────────────────────────────────────────

GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"
DIM = "\033[2m"
BOLD = "\033[1m"
R = "\033[0m"


def link_line(msg: str) -> None:
	print(f"  {GREEN}[ LINK ]{R}  {msg}")


def skip_line(msg: str) -> None:
	print(f"  {YELLOW}[ SKIP ]{R}  {DIM}{msg}{R}", file=sys.stderr)


def dry_line(msg: str) -> None:
	print(f"  {YELLOW}[ DRY  ]{R}  {msg}")


def fail_line(msg: str) -> None:
	print(f"  {RED}[ FAIL ]{R}  {msg}", file=sys.stderr)


def status_ok(msg: str) -> None:
	print(f"  {GREEN}[  OK  ]{R}  {msg}")


def status_bad(msg: str) -> None:
	print(f"  {RED}[BROKEN]{R}  {msg}")


def status_miss(msg: str) -> None:
	print(f"  {YELLOW}[MISSING]{R} {msg}")


# ── CLI ────────────────────────────────────────────────────────────────────────


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(
		description="Create relative symbolic links from target directories to files in the current directory.",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog=f"""\
examples:
  %(prog)s                           link to default targets ({", ".join(DEFAULT_TARGETS)})
  %(prog)s --dry-run                 preview without creating anything
  %(prog)s --targets ../fedora       link to a custom target
  %(prog)s -t ../fedora -t ../arch   link to multiple targets
  %(prog)s --status                  report link state without changing anything
  %(prog)s --exclude '*.bak'         skip files matching a glob pattern
""",
	)
	parser.add_argument(
		"-n",
		"--dry-run",
		action="store_true",
		help="show what would be done without creating any symlinks",
	)
	parser.add_argument(
		"-t",
		"--targets",
		action="append",
		default=[],
		metavar="DIR",
		help=f"target directory (relative to cwd); repeatable, defaults to {' '.join(DEFAULT_TARGETS)}",
	)
	parser.add_argument(
		"-v",
		"--verbose",
		action="store_true",
		help="print each symlink being created (also shows skips)",
	)
	parser.add_argument(
		"-f",
		"--force",
		action="store_true",
		help="overwrite existing symlinks and files",
	)
	parser.add_argument(
		"-e",
		"--exclude",
		action="append",
		default=[],
		metavar="PATTERN",
		help="glob pattern to exclude (repeatable); added to built-in excludes",
	)
	parser.add_argument(
		"--status",
		action="store_true",
		help="report link state (ok / broken / missing) without making any changes",
	)
	return parser.parse_args()


# ── Exclusion matching ──────────────────────────────────────────────────────────


def is_excluded(relative: Path, patterns: list[str]) -> bool:
	"""Check relative path (and its parts) against glob exclude patterns."""
	rel_str = str(relative)
	name = relative.name
	for pattern in patterns:
		if fnmatch(name, pattern) or fnmatch(rel_str, pattern):
			return True
		# Also match if any parent directory component matches
		for part in relative.parts[:-1]:
			if fnmatch(part, pattern.rstrip("/*")):
				return True
	return False


# ── Summary ────────────────────────────────────────────────────────────────────


class Summary:
	def __init__(self) -> None:
		self.linked = 0
		self.skipped = 0
		self.would = 0
		self.failed = 0
		self.ok = 0
		self.broken = 0
		self.missing = 0

	def print(self, mode: str) -> None:
		print(f"\n{BOLD}Summary{R}")
		print("─" * 40)
		if mode == "status":
			print(f"  {GREEN}OK       {R}  {self.ok}")
			print(f"  {RED}Broken   {R}  {self.broken}")
			print(f"  {YELLOW}Missing  {R}  {self.missing}")
		elif mode == "dry-run":
			print(f"  {YELLOW}Would link{R}  {self.would}")
			print(f"  {YELLOW}Would skip{R}  {self.skipped}")
		else:
			print(f"  {GREEN}Linked   {R}  {self.linked}")
			print(f"  {YELLOW}Skipped  {R}  {self.skipped}")
			print(f"  {RED}Failed   {R}  {self.failed}")
		print()


# ── Core walk ──────────────────────────────────────────────────────────────────


def collect_files(cwd: Path, script_path: Path, targets: list[Path], excludes: list[str]) -> list[Path]:
	"""Return sorted list of files to link, excluding self, excludes, and target dirs nested in cwd."""
	target_resolved = {t.resolve() for t in targets}
	files: list[Path] = []

	for item in sorted(cwd.rglob("*")):
		if not item.is_file():
			continue

		resolved = item.resolve()

		# Skip the script itself
		if resolved == script_path:
			continue

		# Skip anything inside a target dir that happens to be nested in cwd
		if any(resolved == t or t in resolved.parents for t in target_resolved):
			continue

		relative = item.relative_to(cwd)

		if is_excluded(relative, excludes):
			continue

		files.append(item)

	return files


def do_link(
	item: Path,
	cwd: Path,
	target_dir: Path,
	*,
	force: bool,
	verbose: bool,
	summary: Summary,
) -> None:
	relative = item.relative_to(cwd)
	link = target_dir / relative
	rel_target = os.path.relpath(item, link.parent)

	# ── .gitignore: copy instead of symlink ──
	if item.name == ".gitignore":
		exists = link.is_symlink() or link.exists()
		if exists and not force:
			skip_line(f"{link} already exists (use -f to overwrite)")
			summary.skipped += 1
			return
		link.parent.mkdir(parents=True, exist_ok=True)
		if exists and force:
			if link.is_dir() and not link.is_symlink():
				fail_line(f"{link} is a real directory — refusing to remove")
				summary.failed += 1
				return
			link.unlink()
		try:
			shutil.copy2(item, link)
			summary.linked += 1
			if verbose:
				link_line(f"{link} ← (copied from {item})")
		except OSError as e:
			fail_line(f"{link}: {e}")
			summary.failed += 1
		return

	# ── Regular files: symlink ──
	exists = link.is_symlink() or link.exists()

	if exists and not force:
		if link.is_symlink():
			try:
				if link.resolve() == item.resolve():
					if verbose:
						skip_line(f"{link}  (already linked)")
					summary.skipped += 1
					return
			except OSError:
				pass  # broken symlink, fall through to skip-with-warning
		skip_line(f"{link} already exists (use -f to overwrite)")
		summary.skipped += 1
		return

	link.parent.mkdir(parents=True, exist_ok=True)

	if exists and force:
		try:
			if link.is_dir() and not link.is_symlink():
				fail_line(f"{link} is a real directory — refusing to remove (force only handles files/symlinks)")
				summary.failed += 1
				return
			link.unlink()
		except OSError as e:
			fail_line(f"Could not remove {link}: {e}")
			summary.failed += 1
			return

	try:
		link.symlink_to(rel_target)
		summary.linked += 1
		if verbose:
			link_line(f"{link} -> {rel_target}")
	except OSError as e:
		fail_line(f"{link}: {e}")
		summary.failed += 1


def do_dry_run(
	item: Path,
	cwd: Path,
	target_dir: Path,
	*,
	force: bool,
	summary: Summary,
) -> None:
	"""Compute the TRUTHFUL outcome — would it link, skip, or overwrite?"""
	relative = item.relative_to(cwd)
	link = target_dir / relative
	rel_target = os.path.relpath(item, link.parent)

	# ── .gitignore: copy instead of symlink ──
	if item.name == ".gitignore":
		exists = link.is_symlink() or link.exists()
		if exists and not force:
			skip_line(f"{link} already exists (use -f to overwrite)")
			summary.skipped += 1
			return
		verb = "would overwrite & copy" if exists else "would copy"
		dry_line(f"{link} ← {item}  ({verb})")
		summary.would += 1
		return

	# ── Regular files: symlink ──
	exists = link.is_symlink() or link.exists()

	if exists and not force:
		if link.is_symlink():
			try:
				if link.resolve() == item.resolve():
					summary.skipped += 1
					return  # already correctly linked, nothing to report
			except OSError:
				pass
		skip_line(f"{link} already exists (use -f to overwrite)")
		summary.skipped += 1
		return

	verb = "would overwrite & link" if exists else "would link"
	dry_line(f"{link} -> {rel_target}  ({verb})")
	summary.would += 1


def do_status(
	item: Path,
	cwd: Path,
	target_dir: Path,
	*,
	summary: Summary,
) -> None:
	relative = item.relative_to(cwd)
	link = target_dir / relative

	# ── .gitignore: real file is OK ──
	if item.name == ".gitignore":
		if link.is_symlink():
			status_bad(f"{link} is a symlink, should be a copy")
			summary.broken += 1
		elif link.exists():
			summary.ok += 1
		else:
			status_miss(f"{link}")
			summary.missing += 1
		return

	# ── Regular files: symlink ──
	if link.is_symlink():
		if not link.exists():
			status_bad(f"{link}  (target missing: {link.resolve()})")
			summary.broken += 1
		else:
			try:
				if link.resolve() == item.resolve():
					summary.ok += 1
				else:
					status_bad(f"{link}  (points elsewhere: {link.resolve()})")
					summary.broken += 1
			except OSError:
				status_bad(f"{link}  (unresolvable)")
				summary.broken += 1
	elif link.exists():
		skip_line(f"{link}  (real file, not a symlink)")
		summary.broken += 1
	else:
		status_miss(f"{link}")
		summary.missing += 1


# ── Main ───────────────────────────────────────────────────────────────────────


def main() -> None:
	args = parse_args()
	cwd = Path.cwd()
	targets = [cwd / t for t in (args.targets or DEFAULT_TARGETS)]
	script_path = Path(__file__).resolve()
	excludes = DEFAULT_EXCLUDES + args.exclude

	mode = "status" if args.status else ("dry-run" if args.dry_run else "link")

	print(f"\n{BOLD}link_common{R}  {DIM}cwd={cwd}{R}")
	print(f"{DIM}  targets: {', '.join(str(t) for t in targets)}{R}\n")

	files = collect_files(cwd, script_path, targets, excludes)
	summary = Summary()

	for item in files:
		for target_dir in targets:
			if mode == "status":
				do_status(item, cwd, target_dir, summary=summary)
			elif mode == "dry-run":
				do_dry_run(item, cwd, target_dir, force=args.force, summary=summary)
			else:
				do_link(item, cwd, target_dir, force=args.force, verbose=args.verbose, summary=summary)

	summary.print(mode)

	if summary.failed > 0 or summary.broken > 0:
		sys.exit(1)


if __name__ == "__main__":
	main()
