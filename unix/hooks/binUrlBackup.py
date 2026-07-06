#!/usr/bin/env -S python3 -u

import argparse
import subprocess
import sys
import time
import urllib.request
from datetime import datetime, timezone
from json import load
from os import environ
from pathlib import Path
from urllib.parse import urlparse

# ── Constants ──────────────────────────────────────────────────────────────────

NOT_USING_TAG = "# NOT USING"

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


def info(msg: str) -> None:
	print(f"  {ANSI_DIM}{msg}{ANSI_RESET}")


# ── URL resolver ───────────────────────────────────────────────────────────────


def resolve_url(url: str, url_hash: dict[str, int]) -> str:
	"""
	Normalise a raw URL to https://<host>/<owner>/<repo> form.
	Tracks host counts in url_hash.
	Raises ValueError on unparseable input.
	"""
	url = url.strip()

	if not url.startswith(("http://", "https://")):
		url = "https://" + url

	parsed = urlparse(url)
	host = parsed.netloc.lower()

	# Expand shorthand hosts
	if host == "github":
		host = "github.com"
	elif host == "gitlab":
		host = "gitlab.com"

	parts = [p for p in parsed.path.split("/") if p]
	if len(parts) < 2:
		raise ValueError(f"Cannot parse owner/repo from: {url!r}")

	owner, repo = parts[0], parts[1]
	url_hash[host] = url_hash.get(host, 0) + 1

	return f"https://{host}/{owner}/{repo}"


# ── Existing file parser ───────────────────────────────────────────────────────


def parse_existing_file(path: Path) -> dict[str, bool]:
	"""
	Read an existing output file and return:
	  { url: is_not_using }
	where is_not_using=True means the line was already marked # NOT USING.

	Ignores header/comment lines that aren't URLs.
	"""
	if not path.exists():
		return {}

	result: dict[str, bool] = {}
	for raw_line in path.read_text(encoding="utf-8").splitlines():
		line = raw_line.strip()

		# Skip blank lines and pure comment lines (header etc.)
		if not line or (line.startswith("#") and "http" not in line):
			continue

		# Already marked as NOT USING: "https://... # NOT USING"
		if NOT_USING_TAG in line:
			url = line.split()[0].strip()
			if url.startswith("http"):
				result[url] = True  # not using
			continue

		# Markdown list item: "- https://..."
		if line.startswith("- "):
			line = line[2:].strip()

		if line.startswith("http"):
			result[line] = False  # active

	return result


# ── Merge logic ────────────────────────────────────────────────────────────────


def merge_urls(
	current_urls: list[str],
	existing: dict[str, bool],
) -> list[tuple[str, bool]]:
	"""
	Merge current config URLs with previously known URLs.

	Returns list of (url, not_using) tuples, sorted case-insensitively.

	Rules:
	  - In current config                  → (url, False)   — active
	  - In file before, gone from config   → (url, True)    — NOT USING
	  - Was already NOT USING, still gone  → (url, True)    — stays NOT USING
	  - Was NOT USING but came back        → (url, False)   — restored to active
	"""
	current_set = set(current_urls)
	merged: dict[str, bool] = {}

	# All current config URLs are active
	for url in current_set:
		merged[url] = False

	# Previously known URLs not in current config → NOT USING
	for url, was_not_using in existing.items():
		if url not in current_set:
			merged[url] = True  # mark as NOT USING

	return sorted(merged.items(), key=lambda x: x[0].casefold())


# ── BackupBinUrls ──────────────────────────────────────────────────────────────


class BackupBinUrls:
	CONFIG_PATH = Path("~/.config/bin/config.json").expanduser()

	def __init__(self) -> None:
		self._config: dict[str, dict] = {}
		self._url_hash: dict[str, int] = {}
		self.loaded = False

		if not self.CONFIG_PATH.exists():
			err(f'bin config not found: "{self.CONFIG_PATH}"')
			return

		self._read_config()
		self.loaded = True

	def _read_config(self) -> None:
		with self.CONFIG_PATH.open() as f:
			self._config = load(f).get("bins", {})

	def collect(self) -> list[str]:
		"""Resolve and return sorted list of URLs from config."""
		urls: list[str] = []
		errors: list[str] = []

		for binary, meta in self._config.items():
			raw_url = meta.get("url", "")
			try:
				urls.append(resolve_url(raw_url, self._url_hash))
			except ValueError as e:
				errors.append(f"{binary}: {e}")

		for e_msg in errors:
			err(f"Bad URL — {e_msg}")

		return sorted(urls, key=str.casefold)

	def print_host_summary(self) -> None:
		if not self._url_hash:
			return
		print(f"\n  {ANSI_DIM}Host distribution:{ANSI_RESET}")
		for host, count in sorted(self._url_hash.items()):
			print(f"    {host:<30} {count}")

	def check_urls(self) -> None:
		"""HTTP HEAD each active URL and report reachability."""
		urls = self.collect()
		print(f"\n  Checking {len(urls)} URL(s)…")
		for url in urls:
			try:
				req = urllib.request.Request(url, method="HEAD")
				with urllib.request.urlopen(req, timeout=8):
					ok(url)
			except Exception as e:
				err(f"{url}  ({e})")

	def install_urls(self, dry_run: bool = False) -> None:
		"""
		Run `bin install <url>` for every active URL (those without # NOT USING).
		Skips URLs already marked NOT USING — those are retired and shouldn't be installed.
		"""
		if not self.loaded:
			skip("BackupBinUrls — config not loaded, skipping")
			return

		urls = self.collect()  # only active URLs from config
		if not urls:
			skip("No active URLs to install.")
			return

		print(f"\n  Installing {len(urls)} package(s) via `bin install`…\n")
		failed: list[str] = []

		for url in urls:
			if dry_run:
				print(f"  {ANSI_DIM}[dry-run] bin install {url}{ANSI_RESET}")
				continue
			try:
				result = subprocess.run(
					["bin", "install", url],
					check=False,
					capture_output=False,  # let bin's own output stream through
				)
				if result.returncode == 0:
					ok(url)
				else:
					err(f"bin install exited {result.returncode} for: {url}")
					failed.append(url)
			except FileNotFoundError:
				err("`bin` command not found — is https://github.com/marcosnils/bin installed?")
				sys.exit(1)
			except Exception as e:
				err(f"{url}  ({e})")
				failed.append(url)

		if failed:
			print(f"\n  {ANSI_YELLOW}{len(failed)} install(s) failed:{ANSI_RESET}")
			for u in failed:
				print(f"    {u}")

	def write(
		self,
		destination: Path,
		dry_run: bool = False,
	) -> dict[str, int]:
		"""
		Merge current URLs with existing file, write result.
		Returns stats dict: {active, not_using, total}.
		"""

		if not self.loaded:
			skip("BackupBinUrls — config not loaded, skipping")
			return {"active": 0, "not_using": 0, "total": 0}

		current_urls = self.collect()
		existing = parse_existing_file(destination)
		merged = merge_urls(current_urls, existing)

		active = sum(1 for _, nu in merged if not nu)
		not_using = sum(1 for _, nu in merged if nu)

		# ── Build output lines ─────────────────────────────────────────────────
		now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

		header_lines = [
			f"# Generated: {now}\n",
			"# ========== BIN INSTALL LINKS ==========\n\n",
		]
		body_lines = []
		for url, not_use in merged:
			if not_use:
				body_lines.append(f"{url}  {NOT_USING_TAG}\n")
			else:
				body_lines.append(f"{url}\n")
		all_lines = header_lines + body_lines

		# ── Dry-run: print to terminal ─────────────────────────────────────────
		if dry_run:
			print(f"\n  {ANSI_DIM}[dry-run] would write → {destination}{ANSI_RESET}")
			for line in all_lines:
				stripped = line.rstrip()
				if NOT_USING_TAG in stripped:
					print(f"    {ANSI_YELLOW}{stripped}{ANSI_RESET}")
				elif stripped.startswith("http"):
					print(f"    {stripped}")
				elif stripped:
					print(f"  {ANSI_DIM}{stripped}{ANSI_RESET}")
		else:
			destination.parent.mkdir(parents=True, exist_ok=True)
			destination.write_text("".join(all_lines), encoding="utf-8")

		# ── Report ─────────────────────────────────────────────────────────────
		ok(f"Bin URLs → {active} active, {ANSI_YELLOW}{not_using} not using{ANSI_RESET}, {active + not_using} total")
		if not_using:
			info(f"Retired URLs are kept and marked '{NOT_USING_TAG}'")
		self.print_host_summary()

		return {"active": active, "not_using": not_using, "total": active + not_using}


# ── CLI (standalone mode) ──────────────────────────────────────────────────────


parser = argparse.ArgumentParser(prog="binUrlBackup.py", formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument("--output", metavar="PATH", help="Override default output file path")
parser.add_argument("--dry-run", action="store_true", help="Preview without writing or installing")
parser.add_argument("--check", action="store_true", help="Validate URLs via HTTP HEAD")
parser.add_argument("--install", action="store_true", help="Run `bin install` for every active URL")


args = parser.parse_args()

dot_files_dir = Path(environ.get("DOT_FILE", "")).expanduser()
if not dot_files_dir or not dot_files_dir.exists():
	err(f"$DOT_FILE is not set or does not exist: '{dot_files_dir}'")
	sys.exit(1)

if args.output:
	output_path = Path(args.output).expanduser()
else:
	output_path = dot_files_dir / "auto_generated" / "__bin_command_urls.txt"

now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
mode_tag = f"{ANSI_YELLOW}[dry-run]{ANSI_RESET} " if args.dry_run else ""
print(f"\n{ANSI_BOLD}binUrlBackup{ANSI_RESET}  {mode_tag}{ANSI_DIM}{now}{ANSI_RESET}\n")

t_start = time.monotonic()
b = BackupBinUrls()

if args.check:
	b.check_urls()
elif args.install:
	b.install_urls(dry_run=args.dry_run)
else:
	b.write(output_path, dry_run=args.dry_run)

elapsed = time.monotonic() - t_start
print(f"\n  {ANSI_DIM}Completed in {elapsed:.2f}s{ANSI_RESET}\n")
