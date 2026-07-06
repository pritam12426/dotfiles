#!/usr/bin/env python3

"""
extract-cookies — extract browser cookies to Netscape or JSON format

Supported browsers:
  firefox, chrome, brave

Usage:
  extract-cookies [options]

Examples:
  extract-cookies --browser firefox
  extract-cookies --browser chrome --filter github.com
  extract-cookies --browser firefox --list-profiles
  extract-cookies --browser brave --format json --file ~/cookies.json
"""

from datetime import datetime, timezone
from genericpath import islink
from pathlib import Path
import argparse
import json
import os
import platform
import shutil
import sqlite3
import sys
import tempfile


# ── Platform helpers ───────────────────────────────────────────────────────────

IS_MACOS = False
IS_LINUX = False
IS_WINDOWS = False

if (_platform := platform.system() == "Darwin"):
	IS_MACOS = True
elif (_platform == "Linux"):
	IS_LINUX = True
elif (_platform == "Windows"):
	IS_WINDOWS = True

# ── Browser profile discovery ──────────────────────────────────────────────────

def firefox_profiles() -> list[Path]:
	"""Return all Firefox cookies.sqlite paths across profiles."""
	if IS_MACOS:
		base = Path("~/Library/Application Support/Firefox/Profiles").expanduser()
	elif IS_LINUX:
		base = Path("~/.mozilla/firefox").expanduser()
	elif IS_WINDOWS:
		base = Path(os.environ.get("APPDATA", "")) / "Mozilla/Firefox/Profiles"
	else:
		return []
	return sorted(base.glob("*/cookies.sqlite"))


def chromium_profiles(browser: str) -> list[Path]:
	"""Return all Cookies DB paths for Chrome-family browsers."""
	dirs: dict[str, dict] = {
		"chrome": {
			"Darwin": "~/Library/Application Support/Google/Chrome",
			"Linux": "~/.config/google-chrome",
			"Windows": str(Path(os.environ.get("LOCALAPPDATA", "")) / "Google/Chrome/User Data"),
		},
		"brave": {
			"Darwin": "~/Library/Application Support/BraveSoftware/Brave-Browser",
			"Linux": "~/.config/BraveSoftware/Brave-Browser",
			"Windows": str(Path(os.environ.get("LOCALAPPDATA", "")) / "BraveSoftware/Brave-Browser/User Data"),
		},
	}
	system = platform.system()
	base_str = dirs.get(browser, {}).get(system)
	if not base_str:
		return []
	base = Path(base_str).expanduser()
	# Default profile + named profiles
	paths = []
	for candidate in [base / "Default/Cookies", base / "Default/Network/Cookies"]:
		if candidate.exists():
			paths.append(candidate)
	for profile_dir in sorted(base.glob("Profile */Cookies")):
		paths.append(profile_dir)
	for profile_dir in sorted(base.glob("Profile */Network/Cookies")):
		paths.append(profile_dir)
	return paths


# ── Profile listing ────────────────────────────────────────────────────────────


def list_profiles(browser: str) -> None:
	paths = firefox_profiles() if browser == "firefox" else chromium_profiles(browser)
	if not paths:
		print(f"  No {browser} profiles found.")
		return
	for i, p in enumerate(paths):
		print(f"  [{i}] {p}")


# ── Safe DB copy ───────────────────────────────────────────────────────────────


def safe_copy(src: Path) -> Path:
	"""Copy a (possibly locked) SQLite DB to a secure temp file."""
	suffix = src.suffix
	fd, tmp_path = tempfile.mkstemp(suffix=suffix, prefix="extract_cookies_")
	os.close(fd)
	tmp = Path(tmp_path)
	shutil.copy2(src, tmp)
	# Also copy WAL/SHM if present (ensures consistent snapshot)
	for ext in ("-wal", "-shm"):
		sidecar = src.with_suffix(src.suffix + ext)
		if sidecar.exists():
			shutil.copy2(sidecar, tmp.with_suffix(tmp.suffix + ext))
	return tmp


# ── Cookie dataclass ───────────────────────────────────────────────────────────


class Cookie:
	__slots__ = ("host", "path", "secure", "expiry", "name", "value", "http_only")

	def __init__(self, host, path, secure, expiry, name, value, http_only=False):
		self.host = host
		self.path = path
		self.secure = bool(secure)
		self.expiry = int(expiry) if expiry else 0
		self.name = name
		self.value = value
		self.http_only = bool(http_only)

	@property
	def include_subdomain(self) -> bool:
		return self.host.startswith(".")

	def is_expired(self) -> bool:
		if self.expiry == 0:
			return False
		return self.expiry < int(datetime.now(timezone.utc).timestamp())

	def to_netscape(self) -> str:
		return "\t".join(
			[
				self.host,
				"TRUE" if self.include_subdomain else "FALSE",
				self.path,
				"TRUE" if self.secure else "FALSE",
				str(self.expiry),
				self.name,
				self.value,
			]
		)

	def to_dict(self) -> dict:
		return {
			"host": self.host,
			"path": self.path,
			"name": self.name,
			"value": self.value,
			"secure": self.secure,
			"http_only": self.http_only,
			"expiry": self.expiry,
			"include_subdomain": self.include_subdomain,
			"expired": self.is_expired(),
		}


# ── Extractors ─────────────────────────────────────────────────────────────────


def extract_firefox(db_path: Path, domain_filter: str | None, no_expired: bool) -> list[Cookie]:
	tmp = safe_copy(db_path)
	try:
		con = sqlite3.connect(tmp)
		cur = con.cursor()
		query = """
            SELECT
                host,
                path,
                isSecure,
                expiry,
                name,
                value,
                isHttpOnly
        FROM
            moz_cookies
        """
		params: list = []
		if domain_filter:
			query += " WHERE host LIKE ?"
			params.append(f"%{domain_filter}%")
		rows = cur.execute(query, params).fetchall()
		con.close()
	finally:
		tmp.unlink(missing_ok=True)
		for ext in ("-wal", "-shm"):
			tmp.with_suffix(tmp.suffix + ext).unlink(missing_ok=True)

	cookies = [Cookie(*r) for r in rows]
	if no_expired:
		cookies = [c for c in cookies if not c.is_expired()]
	return cookies


def extract_chromium(db_path: Path, domain_filter: str | None, no_expired: bool) -> list[Cookie]:
	tmp = safe_copy(db_path)
	try:
		con = sqlite3.connect(tmp)
		cur = con.cursor()
		# Chrome stores expiry as microseconds since 1601-01-01
		# Convert to Unix timestamp: subtract 11644473600 seconds
		query = """
                SELECT
                    host_key,
                    path,
                    i s_secure,
                    CAST((expires_utc / 1000000) - 11644473600 AS INTEGER),
                    name,
                    CAST(encrypted_value AS TEXT),
                    is_httponly
                FROM
                    cookies
        """
		params: list = []
		if domain_filter:
			query += " WHERE host_key LIKE ?"
			params.append(f"%{domain_filter}%")
		rows = cur.execute(query, params).fetchall()
		con.close()
	finally:
		tmp.unlink(missing_ok=True)
		for ext in ("-wal", "-shm"):
			tmp.with_suffix(tmp.suffix + ext).unlink(missing_ok=True)

	# Note: encrypted_value is AES-encrypted on real installs.
	# This gives you the raw bytes; decryption requires OS keychain access
	# and is out of scope for this tool.
	cookies = [Cookie(*r) for r in rows]
	if no_expired:
		cookies = [c for c in cookies if not c.is_expired()]
	return cookies


# ── Output writers ─────────────────────────────────────────────────────────────


def write_netscape(cookies: list[Cookie], out_file: Path | None) -> None:
	lines = ["# Netscape HTTP Cookie File", "# Generated by extract-cookies\n"]
	lines += [c.to_netscape() for c in cookies]
	content = "\n".join(lines) + "\n"
	if out_file:
		out_file.parent.mkdir(parents=True, exist_ok=True)
		out_file.write_text(content, encoding="utf-8")
		out_file.chmod(0o600)
		print(f"[+] Saved {len(cookies)} cookies → {out_file}")
		print("[!] Keep this file private — it contains active login sessions.")
	else:
		print(content, end="")


def write_json(cookies: list[Cookie], out_file: Path | None) -> None:
	data = [c.to_dict() for c in cookies]
	content = json.dumps(data, indent=2, ensure_ascii=False)
	if out_file:
		out_file.parent.mkdir(parents=True, exist_ok=True)
		out_file.write_text(content, encoding="utf-8")
		out_file.chmod(0o600)
		print(f"[+] Saved {len(cookies)} cookies → {out_file}")
		print("[!] Keep this file private — it contains active login sessions.")
	else:
		print(content)


# ── CLI ────────────────────────────────────────────────────────────────────────


def resolve_output(args: argparse.Namespace) -> Path | None:
	if args.file == "-":
		return None
	if args.file:
		return Path(args.file).expanduser()
	ext = "json" if args.format == "json" else "txt"
	return Path(f"~/.cache/extract_cookies/{args.browser}_cookies.{ext}").expanduser()


browsers = ["firefox", "chrome", "brave"]
parser = argparse.ArgumentParser(prog="extract-cookies")
parser.add_argument("--browser", "-b", choices=browsers, default="firefox", metavar="BROWSER", help=f"Browser to extract from. Choices: {', '.join(browsers)}. (default: firefox)")
parser.add_argument("--profile", "-p", type=int, default=0, metavar="N", help="Profile index to use (see --list-profiles). Default: 0 (first found)")
parser.add_argument("--list-profiles", action="store_true", help="List available profiles for the chosen browser and exit")
parser.add_argument("--filter", "-f", metavar="DOMAIN", help="Only extract cookies matching this domain (e.g. github.com)")
parser.add_argument("--no-expired", action="store_true", help="Skip cookies that have already expired")
parser.add_argument("--format", choices=["netscape", "json"], default="netscape", help="Output format (default: netscape)")
parser.add_argument("--file", "-o", metavar="PATH", help=("Output file path. Defaults: ~/.cache/extract_cookies/firefox_cookies.txt (netscape) or ~/.cache/extract_cookies/firefox_cookies.json (json). Pass '-' to print to stdout."))


args = parser.parse_args()

# --list-profiles
if args.list_profiles:
	print(f"Profiles for {args.browser}:")
	list_profiles(args.browser)
	sys.exit(0)

# ── Discover DB path ───────────────────────────────────────────────────────
if args.browser == "firefox":
	paths = firefox_profiles()
	if not paths:
		print("[-] No Firefox profiles found.", file=sys.stderr)
		sys.exit(1)
	if args.profile >= len(paths):
		print(f"[-] Profile index {args.profile} out of range (0–{len(paths) - 1}).", file=sys.stderr)
		sys.exit(1)
	db = paths[args.profile]
	print(f"[*] Using profile: {db.parent.name}")
	print(f"[*] Extracting cookies{f' for {args.filter}' if args.filter else ''}...")
	cookies = extract_firefox(db, args.filter, args.no_expired)
else:
	paths = chromium_profiles(args.browser)
	if not paths:
		print(f"[-] No {args.browser} profiles found.", file=sys.stderr)
		sys.exit(1)
	if args.profile >= len(paths):
		print(f"[-] Profile index {args.profile} out of range (0–{len(paths) - 1}).", file=sys.stderr)
		sys.exit(1)
	db = paths[args.profile]
	print(f"[*] Using profile: {db.parent.name}")
	print(f"[*] Extracting cookies{f' for {args.filter}' if args.filter else ''}...")
	cookies = extract_chromium(db, args.filter, args.no_expired)

if not cookies:
	print("[-] No cookies found matching your criteria.")
	sys.exit(0)

print(f"[+] Found {len(cookies)} cookie(s).")

# ── Write output ───────────────────────────────────────────────────────────
out_file = resolve_output(args)

if args.format == "json":
	write_json(cookies, out_file)
else:
	write_netscape(cookies, out_file)
