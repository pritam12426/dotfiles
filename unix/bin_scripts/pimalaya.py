#!/usr/bin/env python -u

"""
A python tool to download and update pimalaya tools for your system.

Usage:
    pimalaya.py list
    pimalaya.py install [TOOL ...] [--force]
    pimalaya.py update  [TOOL ...] [--force]

With no TOOL arguments, install/update act on every tool in PIMALAYA_TOOLS.
"""

"""
Note:
    I originally assumed release assets followed <repo>.<platform>-<arch>.zip
    (eg: himalaya.aarch64-darwin.zip). Checking pimalaya/himalaya's own
    install.sh shows the real pattern is:

        himalaya.$target.tgz

    where $target is one of: x86_64-linux, aarch64-linux, armv6l-linux,
    armv7l-linux, i686-linux, x86_64-darwin, aarch64-darwin.

    Rather than hardcode an extension that might differ per-tool (mml,
    himalaya-tui may not match exactly, and himalaya-tui may have no
    release assets at all yet), this script fetches the real asset list
    from the GitHub Releases API and matches against $target directly.
    Whatever the extension turns out to be, we handle it at extract time
    by sniffing the archive (tarfile vs zipfile).
"""

import argparse
import json
import os
import platform
import shutil
import sys
import tarfile
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

# --------------------------------------------------------------------------
# Config / constants
# --------------------------------------------------------------------------

HOME: str | None = os.getenv("HOME") or os.path.expanduser("~")
GITHUB_AUTH_TOKEN: str | None = os.getenv("GITHUB_AUTH_TOKEN")

PIMALAYA_HOME: Path = Path(HOME) / ".local/dev-tools/pimalaya"
BIN_DIR: Path = Path(HOME) / ".local/bin"
MANIFEST_FILE: Path = PIMALAYA_HOME / "manifest.json"

PIMALAYA_ORG: str = "pimalaya"
GITHUB_API: str = "https://api.github.com"

PIMALAYA_TOOLS: tuple[str, ...] = (
	"himalaya",
	"cardamum",
	"calendula",
	"ortie",
	"mml",
)


# --------------------------------------------------------------------------
# Platform / architecture detection
# --------------------------------------------------------------------------


def detect_target() -> str:
	"""
	Return the pimalaya-style target triple used in release asset names,
	e.g. "x86_64-linux", "aarch64-darwin". Mirrors the logic in
	pimalaya/himalaya's install.sh so it stays consistent with upstream.
	"""
	system = platform.system()  # "Linux", "Darwin", "Windows"
	machine = platform.machine().lower()  # "x86_64", "arm64", "aarch64", ...

	arch_map = {
		"x86_64": "x86_64",
		"amd64": "x86_64",
		"arm64": "aarch64",
		"aarch64": "aarch64",
		"armv6l": "armv6l",
		"armv7l": "armv7l",
		"i386": "i686",
		"i686": "i686",
		"x86": "i686",
	}
	arch = arch_map.get(machine)
	if arch is None:
		die(f"Unsupported architecture: {machine!r}")

	if system == "Linux":
		os_name = "linux"
	elif system == "Darwin":
		os_name = "darwin"
	elif system == "Windows":
		die("Windows isn't handled by this script yet — pimalaya's release assets for Windows (if any) may use a different naming scheme. Add a case here once you've checked a real release page.")
	else:
		die(f"Unsupported system: {system!r}")

	return f"{arch}-{os_name}"


def die(message: str) -> None:
	print(f"❌ {message}", file=sys.stderr)
	sys.exit(1)


# --------------------------------------------------------------------------
# GitHub API
# --------------------------------------------------------------------------


def github_request(url: str) -> dict:
	headers = {"Accept": "application/vnd.github+json"}
	if GITHUB_AUTH_TOKEN:
		headers["Authorization"] = f"Bearer {GITHUB_AUTH_TOKEN}"

	req = Request(url, headers=headers)
	try:
		with urlopen(req) as resp:
			return json.loads(resp.read())
	except HTTPError as e:
		if e.code == 403:
			die(f"GitHub API rate-limited or forbidden for {url}. Set GITHUB_AUTH_TOKEN to raise your rate limit.")
		if e.code == 404:
			die(f"Nothing found at {url} (404).")
		die(f"GitHub API error {e.code} for {url}: {e.reason}")
	except URLError as e:
		die(f"Network error reaching {url}: {e.reason}")


def latest_release(tool: str) -> dict:
	url = f"{GITHUB_API}/repos/{PIMALAYA_ORG}/{tool}/releases/latest"
	return github_request(url)


def find_asset(release: dict, target: str) -> dict | None:
	"""
	Look for an asset whose filename contains the target triple
	(eg. "aarch64-darwin"), regardless of extension (.tgz, .zip, ...).
	"""
	for asset in release.get("assets", []):
		name = asset.get("name", "")
		if target in name:
			return asset
	return None


# --------------------------------------------------------------------------
# Download / extract
# --------------------------------------------------------------------------


def format_size(num_bytes: float) -> str:
	for unit in ("B", "KB", "MB", "GB"):
		if num_bytes < 1024:
			return f"{num_bytes:.1f}{unit}"
		num_bytes /= 1024
	return f"{num_bytes:.1f}TB"


def print_progress(downloaded: int, total: int | None, bar_width: int = 30) -> None:
	if total:
		fraction = min(downloaded / total, 1.0)
		filled = int(bar_width * fraction)
		bar = "█" * filled + "░" * (bar_width - filled)
		line = f"\r   [{bar}] {fraction * 100:5.1f}%  {format_size(downloaded)}/{format_size(total)}"
	else:
		# No Content-Length header — fall back to a byte counter with no bar.
		line = f"\r   downloaded {format_size(downloaded)}"
	print(line, end="", flush=True)


def download(url: str, dest: Path) -> None:
	print(f"☁️  Downloading {url}")
	headers = {}
	if GITHUB_AUTH_TOKEN:
		headers["Authorization"] = f"Bearer {GITHUB_AUTH_TOKEN}"

	req = Request(url, headers=headers)
	chunk_size = 64 * 1024
	try:
		with urlopen(req) as resp, open(dest, "wb") as f:
			total = resp.length  # None if the server omits Content-Length
			downloaded = 0
			while True:
				chunk = resp.read(chunk_size)
				if not chunk:
					break
				f.write(chunk)
				downloaded += len(chunk)
				print_progress(downloaded, total)
	except (HTTPError, URLError) as e:
		print()  # move off the progress line before the error
		die(f"Download failed for {url}: {e}")

	print()  # move off the progress line
	print(f"✅ Saved to {dest}")


def extract(archive: Path, dest: Path) -> None:
	dest.mkdir(parents=True, exist_ok=True)
	print(f"📤 Extracting {archive.name} → {dest}")

	if tarfile.is_tarfile(archive):
		with tarfile.open(archive) as tf:
			tf.extractall(dest)
	elif zipfile.is_zipfile(archive):
		with zipfile.ZipFile(archive) as zf:
			zf.extractall(dest)
	else:
		die(f"Don't know how to extract {archive.name} (not tar or zip).")


def find_binary(extracted_dir: Path, tool: str) -> Path | None:
	"""
	Release archives contain a single binary named after the tool
	(see install.sh: `cp -f -- "$tmpdir/$binary" "$PREFIX/bin/$binary"`).
	Search recursively in case the archive nests it in a subfolder.
	"""
	candidates = [p for p in extracted_dir.rglob(tool) if p.is_file()]
	if not candidates:
		return None
	return candidates[0]


# --------------------------------------------------------------------------
# Manifest
# --------------------------------------------------------------------------


def load_manifest() -> dict:
	if not MANIFEST_FILE.exists():
		return {}
	with open(MANIFEST_FILE) as f:
		return json.load(f)


def save_manifest(manifest: dict) -> None:
	MANIFEST_FILE.parent.mkdir(parents=True, exist_ok=True)
	with open(MANIFEST_FILE, "w") as f:
		json.dump(manifest, f, indent=2, sort_keys=True)


# --------------------------------------------------------------------------
# Install / update
# --------------------------------------------------------------------------


def install_or_update(tool: str, target: str, manifest: dict, force: bool) -> None:
	print(f"\n— {tool} —")
	release = latest_release(tool)
	tag = release.get("tag_name", "unknown")

	current = manifest.get(tool, {})
	if current.get("version") == tag and not force:
		print(f"✔️  Already up to date ({tag}). Use --force to reinstall.")
		return

	asset = find_asset(release, target)
	if asset is None:
		print(f"⚠️  No release asset for target {target!r} in {tool} {tag}. Skipping (this tool may not ship prebuilt binaries for your platform).")
		return

	tool_dir = PIMALAYA_HOME / tool
	if tool_dir.exists():
		shutil.rmtree(tool_dir)  # clean slate so an update never mixes old + new files

	with tempfile.TemporaryDirectory() as tmp:
		archive_path = Path(tmp) / asset["name"]
		download(asset["browser_download_url"], archive_path)
		# Extract the whole archive tree straight into PIMALAYA_HOME/<tool>/
		# rather than temp-extracting and copying just the binary out.
		extract(archive_path, tool_dir)

	binary = find_binary(tool_dir, tool)
	if binary is None:
		die(f"Couldn't find a '{tool}' binary inside {asset['name']} after extraction — check {tool_dir} manually.")
	binary.chmod(0o755)

	# Convenience symlink into bin/ so tool_dir doesn't need to be on PATH
	# directly — this links to the extracted binary, it doesn't copy it.
	BIN_DIR.mkdir(parents=True, exist_ok=True)
	symlink = BIN_DIR / tool
	if symlink.is_symlink() or symlink.exists():
		symlink.unlink()
	symlink.symlink_to(binary)

	manifest[tool] = {
		"version": tag,
		"asset": asset["name"],
		"target": target,
		"path": str(binary),
		"installed_at": datetime.now(timezone.utc).isoformat(),
	}
	save_manifest(manifest)
	print(f"✅ {tool} {tag} extracted to {tool_dir}")
	print(f"   binary: {binary}  (symlinked from {symlink})")


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def cmd_list(args: argparse.Namespace) -> None:
	manifest = load_manifest()
	print(f"Pimalaya home: {PIMALAYA_HOME}\n")
	for tool in PIMALAYA_TOOLS:
		info = manifest.get(tool)
		if info:
			print(f"  {tool:<14} {info['version']:<12} ({info['installed_at']})")
		else:
			print(f"  {tool:<14} not installed")


def cmd_install(args: argparse.Namespace) -> None:
	target = detect_target()
	manifest = load_manifest()
	tools = args.tools or list(PIMALAYA_TOOLS)
	for tool in tools:
		install_or_update(tool, target, manifest, force=args.force)


def cmd_update(args: argparse.Namespace) -> None:
	# Same underlying logic as install: install_or_update() already skips
	# tools that are already current unless --force is passed.
	cmd_install(args)


def build_parser() -> argparse.ArgumentParser:
	parser = argparse.ArgumentParser(
		prog="pimalaya.py",
		description="Download and update pimalaya tools from GitHub.",
	)
	sub = parser.add_subparsers(dest="command", required=True)

	p_list = sub.add_parser("list", help="Show installed versions.")
	p_list.set_defaults(func=cmd_list)

	p_install = sub.add_parser("install", help="Install one or more tools.")
	p_install.add_argument(
		"tools",
		nargs="*",
		choices=PIMALAYA_TOOLS,
		metavar="TOOL",
		help=f"Tools to install (default: all — {', '.join(PIMALAYA_TOOLS)}).",
	)
	p_install.add_argument("--force", action="store_true", help="Reinstall even if already current.")
	p_install.set_defaults(func=cmd_install)

	p_update = sub.add_parser("update", help="Update one or more tools.")
	p_update.add_argument(
		"tools",
		nargs="*",
		choices=PIMALAYA_TOOLS,
		metavar="TOOL",
		help=f"Tools to update (default: all — {', '.join(PIMALAYA_TOOLS)}).",
	)
	p_update.add_argument("--force", action="store_true", help="Reinstall even if already current.")
	p_update.set_defaults(func=cmd_update)

	return parser


def main() -> None:
	parser = build_parser()
	args = parser.parse_args()
	args.func(args)


if __name__ == "__main__":
	main()
