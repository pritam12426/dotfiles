#!/usr/bin/env -S python3 -u

import argparse
import sys
import time
from datetime import datetime, timezone
from os import environ
from pathlib import Path
from typing import Literal

# ── Types ──────────────────────────────────────────────────────────────────────

PathType = Literal["all", "folder", "file"]
Format = Literal["txt", "md"]

# ── ANSI helpers ───────────────────────────────────────────────────────────────

ANSI_GREEN = "\033[32m"
ANSI_YELLOW = "\033[33m"
ANSI_RED = "\033[31m"
ANSI_RESET = "\033[0m"
ANSI_BOLD = "\033[1m"
ANSI_DIM = "\033[2m"


def ok(msg: str) -> None:
	print(f"  {ANSI_GREEN}✔{ANSI_RESET}  {msg}")


def skip(msg: str) -> None:
	print(f"  {ANSI_YELLOW}–{ANSI_RESET}  {ANSI_DIM}{msg}{ANSI_RESET}")


def err(msg: str) -> None:
	print(f"  {ANSI_RED}✘{ANSI_RESET}  {msg}", file=sys.stderr)


def section_header(label: str, fmt: Format) -> str:
	return f"## {label}\n\n" if fmt == "md" else f"# ========== {label} ==========\n"


def section_footer() -> str:
	return "\n\n"


# ── Summary tracker ────────────────────────────────────────────────────────────


class Summary:
	def __init__(self) -> None:
		self.rows: list[tuple[str, int, str]] = []

	def add(self, label: str, count: int, status: str = "ok") -> None:
		self.rows.append((label, count, status))

	def print(self) -> None:
		print(f"\n{ANSI_BOLD}{'Section':<30} {'Items':>6}  Status{ANSI_RESET}")
		print("─" * 48)
		for label, count, status in self.rows:
			colour = ANSI_GREEN if status == "ok" else ANSI_YELLOW
			print(f"  {label:<28} {count:>6}  {colour}{status}{ANSI_RESET}")
		print()


# ── Directory backup ───────────────────────────────────────────────────────────


class BackupDirectory:
	def __init__(self, directory: Path, label: str) -> None:
		self.directory = directory
		self.label = label
		self.exists = directory.exists()

	def collect(self, path_type: PathType = "all") -> list[str]:
		if not self.exists:
			return []
		lines: list[str] = []
		for item in sorted(self.directory.iterdir()):
			if item.name.startswith(".DS_Store"):
				continue
			if path_type == "folder" and item.is_dir():
				lines.append(item.name)
			elif path_type == "file" and item.is_file():
				lines.append(item.name)
			elif path_type == "all":
				prefix = "D:" if item.is_dir() else "f:"
				lines.append(f"{prefix} {item.name}")
		return lines

	def write(
		self,
		destination: Path,
		path_type: PathType = "all",
		fmt: Format = "txt",
		dry_run: bool = False,
		summary: Summary | None = None,
	) -> None:
		if not self.exists:
			skip(f"{self.label:<28} → directory not found: {self.directory}")
			if summary:
				summary.add(self.label, 0, "skipped")
			return

		lines = self.collect(path_type)
		header = section_header(self.label, fmt)

		if dry_run:
			print(f"\n{ANSI_DIM}{header.rstrip()}{ANSI_RESET}")
			for line in lines:
				print(f"    {line}")
		else:
			with destination.open("a") as fd:
				fd.write(header)
				for line in lines:
					fd.write(f"{line}\n")
				fd.write(section_footer())

		ok(f"{self.label:<28} → {len(lines)} item(s)")
		if summary:
			summary.add(self.label, len(lines))


# ── CLI ────────────────────────────────────────────────────────────────────────

SECTIONS = ["fonts", "cpp", "apps", "devtools"]


packageDataBackup = argparse.ArgumentParser(prog="packageDataBackup", formatter_class=argparse.RawDescriptionHelpFormatter)
packageDataBackup.add_argument("--only", choices=SECTIONS, metavar="SECTION", help=f"Run only one section. Choices: {', '.join(SECTIONS)}")
packageDataBackup.add_argument("--output", metavar="PATH", help="Override default backup output file path")
packageDataBackup.add_argument("--dry-run", action="store_true", help="Preview output without writing any files")
packageDataBackup.add_argument("--check", action="store_true", help="Validate bin URLs via HTTP HEAD")
packageDataBackup.add_argument("--format", choices=["txt", "md"], default="txt", metavar="FORMAT", help="Output format: txt (default) or md (Markdown)")


# ── Main ───────────────────────────────────────────────────────────────────────

args = packageDataBackup.parse_args()

dot_files_dir = Path(environ.get("DOT_FILE", "")).expanduser()
if not dot_files_dir or not dot_files_dir.exists():
	err(f"$DOT_FILE is not set or does not exist: '{dot_files_dir}'")
	sys.exit(1)

fmt: Format = args.format

backup_file = Path(args.output).expanduser() if args.output else dot_files_dir / "auto_generated" / f"__back_data.{'md' if fmt == 'md' else 'txt'}"

now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
mode_tag = f"{ANSI_YELLOW}[dry-run]{ANSI_RESET} " if args.dry_run else ""
print(f"\n{ANSI_BOLD}packageDataBackup{ANSI_RESET}  {mode_tag}{ANSI_DIM}{now}{ANSI_RESET}")
if not args.dry_run:
	print(f"  output → {backup_file}")
print()

t_start = time.monotonic()
summary = Summary()
only = args.only

# ── Init backup file with timestamp header ─────────────────────────────────
if not args.dry_run and (only is None or only != "bin"):
	backup_file.parent.mkdir(parents=True, exist_ok=True)
	with backup_file.open("w") as fd:
		fd.write(f"# Package Data Backup\n\n_Generated: {now}_\n\n" if fmt == "md" else f"# Generated: {now}\n\n")

# ── Directory sections ─────────────────────────────────────────────────────
if only is None or only == "fonts":
	BackupDirectory(Path("~/Library/Fonts").expanduser(), "Fonts list").write(backup_file, "folder", fmt, args.dry_run, summary)

if only is None or only == "cpp":
	BackupDirectory(Path("/usr/local/big_library"), "CPP Install libs").write(backup_file, "all", fmt, args.dry_run, summary)

if only is None or only == "apps":
	BackupDirectory(Path("/Applications"), "GUI applications").write(backup_file, "folder", fmt, args.dry_run, summary)

if only is None or only == "devtools":
	BackupDirectory(Path("~/.local/dev-tools").expanduser(), "Dev-tools").write(backup_file, "all", fmt, args.dry_run, summary)

# ── Summary ────────────────────────────────────────────────────────────────
elapsed = time.monotonic() - t_start
summary.print()
print(f"  {ANSI_DIM}Completed in {elapsed:.2f}s{ANSI_RESET}\n")
