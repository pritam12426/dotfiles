#!/usr/bin/env -S python3 -u

from pathlib import Path
from subprocess import run

DOWNLOAD_CACHE_DIR: Path = Path("/tmp/updateFfmpge")
DOWNLOAD_CACHE_DIR.mkdir(exist_ok=True)

INSTALL_DIR: Path = Path("~/.local/dev-tools/ffmpeg").expanduser()
INSTALL_DIR.mkdir(parents=True, exist_ok=True)

# https://osxexperts.net/
VERSION: str = "80"

urls: list[dict[str, str]] = [
	{"url": f"https://www.osxexperts.net/ffprobe{VERSION}arm.zip", "command": "ffprobe"},
	{"url": f"https://www.osxexperts.net/ffplay{VERSION}arm.zip", "command": "ffplay"},
	{"url": f"https://www.osxexperts.net/ffmpeg{VERSION}arm.zip", "command": "ffmpeg"},
]


def installFFmpeg(object: dict[str, str]):
	url: str = object["url"]
	command_name: str = object["command"]
	DOWNLOAD_CACHE_DIR_FILE_NAME: Path = DOWNLOAD_CACHE_DIR / str(command_name + ".zip")
	print(f"\n ☁️  Downloading {command_name}\n\t{url}")
	run(
		[
			"wget",
			"--show-progress",
			"-qc",
			"-O",
			str(DOWNLOAD_CACHE_DIR_FILE_NAME),
			url,
		]
	)

	run(
		[
			"bsdtar",
			"-xf",
			str(DOWNLOAD_CACHE_DIR_FILE_NAME),
			"-C",
			INSTALL_DIR,
			command_name
		]
	)

for url in urls:
	installFFmpeg(url)

print(f"\nInstalled ffmpeg-v{VERSION}")
for i in INSTALL_DIR.iterdir():
	print(f" * {i.name} \t -> chmod 755")
