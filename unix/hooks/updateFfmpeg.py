#!/usr/bin/env -S python3 -u

# https://ffmpeg.martin-riedl.de/
# https://osxexperts.net/
# https://github.com/eugeneware/ffmpeg-static
# https://github.com/descriptinc/ffmpeg-ffprobe-static


"""
updateFfmpeg.py — fetch the latest ffmpeg/ffprobe/ffplay macOS build from
https://ffmpeg.martin-riedl.de/ and install it under ~/.local/dev-tools/,
symlinking each binary into ~/.local/bin/.
"""

import argparse
import sys
import urllib.request
from os import X_OK, access
from urllib.parse import urljoin
from pathlib import Path
from subprocess import CalledProcessError, run

# ── constants ──────────────────────────────────────────────────────────────────

INSTALL_PREFIX: Path = Path("~/.local/dev-tools").expanduser()
BIN_DIR:        Path = Path("~/.local/bin").expanduser()
ARCHIVE_DIR:    Path = Path("/tmp/ffmpeg-update")

DEFAULT_BUILD_TYPE: str = "release"  # "release" (stable, versioned) or "snapshot" (latest dev build)
DEFAULT_ARCH:       str = "arm64"    # "arm64" for Apple Silicon, "amd64" for Intel

# Cloudflare (fronting ffmpeg.martin-riedl.de) serves a 404 to non-browser
# User-Agents on the redirect probe, even though it's just a HEAD request.
BROWSER_USER_AGENT: str = (
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
	"(KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"
)

BINARIES: list[str] = ["ffmpeg", "ffprobe", "ffplay"]


# ── cli ────────────────────────────────────────────────────────────────────────


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(
		description="Update ffmpeg/ffprobe/ffplay from ffmpeg.martin-riedl.de"
	)
	parser.add_argument(
		"--check",
		action="store_true",
		help="Only check whether an update is available; don't download or install anything.",
	)
	parser.add_argument(
		"-n", "--dry-run",
		action="store_true",
		help="Show what would be downloaded/installed without touching the filesystem.",
	)
	parser.add_argument(
		"--force",
		action="store_true",
		help="Reinstall even if the local version already matches the latest.",
	)
	parser.add_argument(
		"--build-type",
		choices=["release", "snapshot"],
		default=DEFAULT_BUILD_TYPE,
		help=f"Which build channel to use (default: {DEFAULT_BUILD_TYPE}).",
	)
	parser.add_argument(
		"--arch",
		choices=["arm64", "amd64"],
		default=DEFAULT_ARCH,
		help=f"Target architecture (default: {DEFAULT_ARCH}).",
	)
	parser.add_argument(
		"-v", "--verbose",
		action="store_true",
		help="Print resolved URLs and extra detail as the script runs.",
	)
	return parser.parse_args()


# ── helpers ────────────────────────────────────────────────────────────────────


def _resolve_version(base_url: str, verbose: bool) -> tuple[str, str]:
	"""
	Follow the redirect for ffmpeg.zip without downloading it, and pull the
	version out of the resolved Location header, e.g.
	.../macos/arm64/1783011502_8.1.2/ffmpeg.zip -> "8.1.2"
	Returns (version, resolved_base_url).
	"""
	probe_url = f"{base_url}/ffmpeg.zip"
	if verbose:
		print(f" 🔎 Probing {probe_url}")

	req = urllib.request.Request(probe_url, method="HEAD", headers={"User-Agent": BROWSER_USER_AGENT})

	try:
		# Opener that does NOT follow redirects, so we can read Location ourselves.
		class NoRedirect(urllib.request.HTTPRedirectHandler):
			def redirect_request(self, *args, **kwargs):
				return None

		opener = urllib.request.build_opener(NoRedirect)
		resp = opener.open(req)
		raw_location = resp.geturl()
	except urllib.error.HTTPError as exc:
		raw_location = exc.headers.get("Location") if exc.headers else None
		if not raw_location:
			raise RuntimeError(f"Could not resolve redirect for {probe_url}: {exc}")

	# The server may return a relative Location (e.g. "/download/macos/arm64/...")
	# instead of a full URL. urljoin resolves it against the request URL either way.
	location = urljoin(probe_url, raw_location)
	if verbose:
		print(f" 🔎 Resolved to {location}")

	# location looks like: https://.../download/macos/arm64/<timestamp>_<version>/ffmpeg.zip
	parts = location.rstrip("/").split("/")
	version_segment = parts[-2]  # "<timestamp>_<version>"
	version = version_segment.split("_", 1)[-1]
	resolved_base = "/".join(parts[:-1])
	return version, resolved_base


def _local_version() -> str:
	"""Return the newest installed version string, or '' if none found."""
	if not INSTALL_PREFIX.exists():
		return ""
	versions = [p.name.removeprefix("ffmpeg-v") for p in INSTALL_PREFIX.glob("ffmpeg-v*") if p.is_dir()]
	return sorted(versions)[-1] if versions else ""


# ── core logic ─────────────────────────────────────────────────────────────────


def download(url: str, dest: Path) -> None:
	dest.unlink(missing_ok=True)
	run(
		["wget", "--show-progress", "-qL", "--user-agent", BROWSER_USER_AGENT, "-O", str(dest), url],
		check=True,
	)
	if not dest.exists() or dest.stat().st_size == 0:
		raise RuntimeError(f"Downloaded file missing or empty: {dest}")


def extract(archive_path: Path, binary_name: str, dest_dir: Path) -> None:
	dest_dir.mkdir(parents=True, exist_ok=True)
	run(["bsdtar", "-xf", str(archive_path), "-C", str(dest_dir), binary_name], check=True)


def symlink_binary(binary_name: str, install_dir: Path) -> None:
	binary = install_dir / binary_name
	if not binary.exists():
		candidates = [p for p in install_dir.iterdir() if p.is_file() and access(p, X_OK)]
		if not candidates:
			raise RuntimeError(f"No executable found for {binary_name} in {install_dir}")
		binary = candidates[0]
		print(f" ⚠️  '{binary_name}' not found directly; using {binary.name}")

	binary.chmod(0o755)
	BIN_DIR.mkdir(parents=True, exist_ok=True)
	link = BIN_DIR / binary_name
	link.unlink(missing_ok=True)
	link.symlink_to(binary)
	print(f" 🔗 Symlinked {link} → {binary}")


def remove_old_version(old_ver: str) -> None:
	if not old_ver:
		return
	old_path = INSTALL_PREFIX / f"ffmpeg-v{old_ver}"
	if old_path.exists():
		print(f" 🗑️  Removing old version {old_path}")
		run(["rm", "-rf", str(old_path)], check=True)


def install(version: str, resolved_base: str, archive_dir: Path) -> None:
	install_dir = INSTALL_PREFIX / f"ffmpeg-v{version}"
	archive_dir.mkdir(parents=True, exist_ok=True)

	if install_dir.exists():
		print(f" ⚠️  Install directory already exists: {install_dir}")
		print("     Skipping download; re-linking binaries.")
	else:
		for name in BINARIES:
			archive_url = f"{resolved_base}/{name}.zip"
			archive_path = archive_dir / f"{name}.zip"

			print(f"\n ☁️  Downloading {name}\n\t{archive_url}")
			download(archive_url, archive_path)

			print(f" 📦  Extracting {name}")
			extract(archive_path, name, install_dir)
			archive_path.unlink(missing_ok=True)

	for name in BINARIES:
		symlink_binary(name, install_dir)


def verify() -> None:
	result = run(["ffmpeg", "-version"], capture_output=True, text=True)
	if result.returncode == 0:
		print(f"\n👍 ffmpeg active version: {result.stdout.splitlines()[0]}")
	else:
		print(f"\n⚠️  Could not verify ffmpeg: {result.stderr.strip()}", file=sys.stderr)


# ── entry point ────────────────────────────────────────────────────────────────


def main() -> None:
	args = parse_args()
	base_url = f"https://ffmpeg.martin-riedl.de/redirect/latest/macos/{args.arch}/{args.build_type}"

	try:
		latest_ver, resolved_base = _resolve_version(base_url, args.verbose)
	except Exception as exc:
		print(f"❌ Failed to resolve latest version: {exc}", file=sys.stderr)
		sys.exit(1)

	local_ver = _local_version()

	print(f"   local  : {local_ver or '(none)'}")
	print(f"   latest : {latest_ver}  ({args.build_type}, {args.arch})")

	up_to_date = local_ver == latest_ver

	if args.check:
		if up_to_date:
			print("\n✅ ffmpeg is already up to date.")
		else:
			print(f"\n🚀 Update available: {local_ver or 'none'} → {latest_ver}")
		sys.exit(0)

	if up_to_date and not args.force:
		print("\n✅ ffmpeg is already up to date.")
		sys.exit(0)

	if up_to_date and args.force:
		print(f"\n🔁 Already on {latest_ver}, but --force was given — reinstalling.")
	else:
		print(f"\n🚀 Update available: {local_ver or 'none'} → {latest_ver}")

	if args.dry_run:
		install_dir = INSTALL_PREFIX / f"ffmpeg-v{latest_ver}"
		print("\n🧪 Dry run — no files will be changed. Would do the following:")
		if args.force and install_dir.exists():
			print(f"   - remove existing install dir (force): {install_dir}")
		for name in BINARIES:
			print(f"   - download {resolved_base}/{name}.zip -> {install_dir / (name + '.zip')}")
			print(f"   - extract {name} -> {install_dir / name}")
			print(f"   - symlink {BIN_DIR / name} -> {install_dir / name}")
		if local_ver and local_ver != latest_ver:
			print(f"   - remove old version dir: {INSTALL_PREFIX / ('ffmpeg-v' + local_ver)}")
		sys.exit(0)

	try:
		install_dir = INSTALL_PREFIX / f"ffmpeg-v{latest_ver}"
		if args.force and install_dir.exists():
			print(f" 🗑️  --force given, removing existing install dir {install_dir}")
			run(["rm", "-rvf", str(install_dir)], check=True)

		install(latest_ver, resolved_base, ARCHIVE_DIR)
		remove_old_version(local_ver if local_ver != latest_ver else "")
		verify()
	except (CalledProcessError, RuntimeError) as exc:
		print(f"❌ Installation failed: {exc}", file=sys.stderr)
		sys.exit(1)


if __name__ == "__main__":
	main()
