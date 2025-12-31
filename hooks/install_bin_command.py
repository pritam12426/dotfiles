#!/usr/bin/env -S python -u

from subprocess import run
from pathlib import Path

URLS_FILE: Path = Path("auto_generated/__bin_command_urls.txt")
if not URLS_FILE.exists():
	raise  RuntimeError

if not URLS_FILE.exists():
	print("Error")

def installGithubreleasesWithBinCommand(url: str):
	if input(f'\t "{url}" [Y/n]: ').strip().lower() != "y":
		return

	run(
		[
			"bin",
			"install",
			url
		]
	)
	print("============================================")


urls: list[str] = [
	line.strip()
	for line in URLS_FILE.read_text().splitlines()
	if line.strip() and not line.lstrip().startswith("#")
]

total_url: int = len(urls)
for counter, url in enumerate(urls, 1):
	print(f"\n📦 Installing program {counter}/{total_url}")
	installGithubreleasesWithBinCommand(url)
