#!/usr/bin/env -S python3 -u

from json import load
from os import environ
from pathlib import Path
from urllib.parse import urlparse
from typing import Literal

DOT_FILES_DIR: Path = Path(environ["DOT_FILE"])
# DOT_FILES_DIR: Path = Path("/Users/pritam/Developer/git_repository/dotfiles/darwin")
WRITE_BACKUP_DATA: Path = (DOT_FILES_DIR / "auto_generated" /"__back_data.txt")
WRITE_BACKUP_DATA.open("w").close()
PathType = Literal["all", "folder", "file"]


class backupBinCommandData:
	BIN_CONFIG_PATH: Path = Path("~/.config/bin/config.json").expanduser()
	BIN_CONFIG_PATH_OBJECT: dict = dict()
	DB_ALL_URLS: list[str] = list()
	URL_HASH: dict = dict()

	def __init__(self) -> None:
		if not self.BIN_CONFIG_PATH.exists():
			print(f'bin config is not valide "{self.BIN_CONFIG_PATH}"')
			return

		self.readJson()

	def readJson(self) -> None:
		with self.BIN_CONFIG_PATH.open() as f:
			self.BIN_CONFIG_PATH_OBJECT = load(f).get("bins")

	def resolve_url(self, url: str) -> str:
		url = url.strip()

		# Auto-fix missing scheme
		if not url.startswith(("http://", "https://")):
			url = "https://" + url

		parsed = urlparse(url)

		parsed = urlparse(url)

		host = parsed.netloc.lower()

		# Fix shorthand hosts
		if host == "github":
			host = "github.com"
		elif host == "gitlab":
			host = "gitlab.com"

		parts = [p for p in parsed.path.split("/") if p]

		# ---- URL_HASH host counter ----
		self.URL_HASH[host] = self.URL_HASH.get(host, 0) + 1

		if len(parts) < 2:
			raise ValueError("Invalid repository URL")

		owner, repo = parts[0], parts[1]

		return f"https://{parsed.netloc}/{owner}/{repo}"

	def print_url_hash(self) -> None:
		for i in self.URL_HASH.keys():
			print(f"{i}:\t {self.URL_HASH.get(i)}")

	def writeData(self, destination_path: Path) -> None:
		for binary in self.BIN_CONFIG_PATH_OBJECT.keys():
			url: str = self.BIN_CONFIG_PATH_OBJECT.get(binary, {}).get("url", "")
			url = self.resolve_url(url)
			self.DB_ALL_URLS.append(url)

		self.DB_ALL_URLS.sort(key=str.casefold)

		fd = destination_path.open("w")
		fd.write("# ========== BIN INSTALL LINKS ==========\n\n")
		for i in self.DB_ALL_URLS:
			fd.write(f'{i}\n')
		fd.close()

		self.print_url_hash()


class backupBasedOnDirectories:
	BACKUP_FILE_MESSAGE: str = str()
	TARGET_DIRECTORY: Path = Path()

	def __init__(self, dir: Path, msg: str) -> None:
		if not dir.exists():
			return

		self.TARGET_DIRECTORY = dir
		self.BACKUP_FILE_MESSAGE = msg


	def writeData(self, destination_path: Path, path_type: PathType = "all"):
		"""
		Write a list of items in TARGET_DIRECTORY to the destination file.

		Args:
		    destination_path: Path to the output file
		    path_type: "all" (default), "folder" (only directories), or "file" (only files)
		"""
		with destination_path.open("a") as fd:
			print(f"Backuping the \"{self.BACKUP_FILE_MESSAGE}\"")
			fd.write(f"# ========== {self.BACKUP_FILE_MESSAGE} ==========\n")

			for item in self.TARGET_DIRECTORY.iterdir():
				if item.name == ".DS_Store":
					continue

				# Apply filtering based on path_type
				if path_type == "folder" and item.is_dir():
					fd.write(f"{item.name}\n")
				elif path_type == "file" and item.is_file():
					fd.write(f"{item.name}\n")
				elif path_type == "all":
					# For "all", we include everything (except .DS_Store)
					if item.is_dir():
						fd.write(f"D: {item.name}\n")
					elif item.is_file():
						fd.write(f"f: {item.name}\n")

			fd.write("\n\n")


b = backupBasedOnDirectories(Path("~/Library/Fonts").expanduser(), "Fonts list")
b.writeData(WRITE_BACKUP_DATA, "folder")

b = backupBasedOnDirectories(Path("/usr/local/big_library"), "CPP Install libs")
b.writeData(WRITE_BACKUP_DATA, "all")

b = backupBasedOnDirectories(Path("/Applications"), "GUI applications")
b.writeData(WRITE_BACKUP_DATA, "folder")

b = backupBasedOnDirectories(Path("~/.local/dev-tools").expanduser(), "Dev-tools")
b.writeData(WRITE_BACKUP_DATA, "all")

b = backupBinCommandData()
b.writeData(DOT_FILES_DIR / "auto_generated" / "__bin_command_urls.txt")
