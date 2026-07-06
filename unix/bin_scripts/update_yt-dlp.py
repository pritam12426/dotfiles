#!/usr/bin/env python3 -u
"""
update_yt-dlp.py — fetch the latest yt-dlp macOS release from GitHub
and install it under ~/.local/dev-tools/, symlinking the binary to
~/.local/bin/yt-dlp.
"""

import json
import sys
import urllib.request
from os import X_OK, access, getenv
from pathlib import Path
from subprocess import CalledProcessError, run

# ── constants ──────────────────────────────────────────────────────────────────

INSTALL_PREFIX: Path = Path("~/.local/dev-tools").expanduser()
BIN_DIR:        Path = Path("~/.local/bin").expanduser()
ARCHIVE_TMP:    Path = Path("/tmp/yt-dlp-update.zip")
GITHUB_API_URL: str  = "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
ASSET_NAME:     str  = "yt-dlp_macos.zip"
BINARY_NAME:    str  = "yt-dlp"


# ── helpers ────────────────────────────────────────────────────────────────────


def _auth_headers() -> dict:
	headers = {
		"User-Agent": "yt-dlp-updater",
		"Accept": "application/vnd.github+json",
	}
	token = getenv("GITHUB_AUTH_TOKEN")
	if token:
		print("🔖 Using GITHUB_AUTH_TOKEN from environment")
		headers["Authorization"] = f"Bearer {token}"
	return headers


def _normalize_version(tag: str) -> str:
	"""Strip a leading 'v' so '2024.11.18' and 'v2024.11.18' compare equal."""
	return tag.lstrip("v")


def _local_version() -> str:
	"""Return the newest installed version string, or '' if none found."""
	if not INSTALL_PREFIX.exists():
		return ""
	versions = [p.name.removeprefix("yt_dlp-v") for p in INSTALL_PREFIX.glob("yt_dlp-v*") if p.is_dir()]
	return sorted(versions)[-1] if versions else ""


# ── core logic ─────────────────────────────────────────────────────────────────


def fetch_release() -> tuple[str, str]:
	"""Return (version, download_url) for the latest GitHub release."""
	req = urllib.request.Request(GITHUB_API_URL, headers=_auth_headers())
	with urllib.request.urlopen(req) as resp:
		data = json.load(resp)

	version = _normalize_version(data.get("tag_name", ""))
	if not version:
		raise RuntimeError("Could not determine latest version from GitHub API response")

	for asset in data.get("assets", []):
		if asset.get("name") == ASSET_NAME:
			return version, asset["browser_download_url"]

	raise RuntimeError(f"{ASSET_NAME} not found in the latest release")


def download(url: str) -> None:
	"""Download *url* to ARCHIVE_TMP, clobbering any leftover temp file."""
	# Remove stale temp file so we never accidentally resume an old partial download.
	ARCHIVE_TMP.unlink(missing_ok=True)

	print(f"☁️  Downloading {url}")
	cmd = ["wget", "--show-progress", "-qL", "-O", str(ARCHIVE_TMP)]

	token = getenv("GITHUB_AUTH_TOKEN")
	if token:
		cmd.extend(["--header", f"Authorization: Bearer {token}"])

	cmd.append(url)
	run(cmd, check=True)
	print(f"✅ Saved to {ARCHIVE_TMP}")


def extract(dest: Path) -> None:
	dest.mkdir(parents=True, exist_ok=True)
	print(f"📤 Extracting {ARCHIVE_TMP.name} → {dest}")
	run(["bsdtar", "-xf", str(ARCHIVE_TMP), "-C", str(dest)], check=True)


def symlink_binary(install_dir: Path) -> None:
	"""Find the binary named 'yt-dlp' in *install_dir* and symlink it into BIN_DIR."""
	binary = install_dir / BINARY_NAME
	if not binary.exists():
		# Fallback: first executable file in the directory
		candidates = [p for p in install_dir.iterdir() if p.is_file() and access(p, X_OK)]
		if not candidates:
			raise RuntimeError(f"No executable found in {install_dir}")
		binary = candidates[0]
		print(f"⚠️  '{BINARY_NAME}' not found directly; using {binary.name}")

	BIN_DIR.mkdir(parents=True, exist_ok=True)
	link = BIN_DIR / BINARY_NAME
	link.unlink(missing_ok=True)
	link.symlink_to(binary)
	print(f"🔗 Symlinked {link} → {binary}")


def remove_old_version(old_ver: str) -> None:
	if not old_ver:
		return
	old_path = INSTALL_PREFIX / f"yt_dlp-v{old_ver}"
	if old_path.exists():
		print(f"🗑️  Removing old version {old_path}")
		run(["rm", "-rf", str(old_path)], check=True)


def install(version: str, url: str, old_ver: str) -> None:
	print("─" * 80)
	install_dir = INSTALL_PREFIX / f"yt_dlp-v{version}"

	if install_dir.exists():
		print(f"⚠️  Install directory already exists: {install_dir}")
		print("    Skipping download; re-linking binary.")
	else:
		download(url)
		extract(install_dir)
		print(f"🗑️  Removing temp archive {ARCHIVE_TMP}")
		ARCHIVE_TMP.unlink(missing_ok=True)
		remove_old_version(old_ver)

	symlink_binary(install_dir)
	print("\n✅ yt-dlp installed successfully.")


def verify() -> None:
	result = run([BINARY_NAME, "--version"], capture_output=True, text=True)
	if result.returncode == 0:
		print(f"👍 yt-dlp active version: {result.stdout.strip()}")
	else:
		print(f"⚠️  Could not verify yt-dlp: {result.stderr.strip()}", file=sys.stderr)


# ── entry point ────────────────────────────────────────────────────────────────
try:
	latest_ver, download_url = fetch_release()
except Exception as exc:
	print(f"❌ Failed to fetch release info: {exc}", file=sys.stderr)
	sys.exit(1)

local_ver = _local_version()

print(f"   local  : {local_ver or '(none)'}")
print(f"   latest : {latest_ver}")

if local_ver == latest_ver:
	print("\n✅ yt-dlp is already up to date.")
	sys.exit(0)

print(f"\n🚀 Update available: {local_ver or 'none'} → {latest_ver}")
try:
	install(latest_ver, download_url, local_ver)
	verify()
except CalledProcessError as exc:
	print(f"❌ Installation failed: {exc}", file=sys.stderr)
	sys.exit(1)
