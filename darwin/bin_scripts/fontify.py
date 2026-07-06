#!/usr/bin/env python3

import argparse
import requests
import logging
from json import JSONDecodeError, dump, dumps, load
from pathlib import Path
from subprocess import run

# ---------------- paths & constants ----------------
VERSION_MAJOR: int = 1
VERSION_MINOR: int = 1
VERSION_PATCH: int = 0
VERSION: str = f"v{VERSION_MAJOR}.{VERSION_MINOR}.{VERSION_PATCH}"
VERSION_NAME: str = "fontify-functionalities"

CACHE_DIRECTORY: Path = Path("~/Library/Application Support/fontify").expanduser()
INSTALLED_FONTS_DIR: Path = Path("~/Library/Fonts").expanduser()
FONTIFY_DOWNLOAD_CACHE: Path = Path("/tmp/fontify")

INSTALLED_FONTS_DATA_BASE: Path = CACHE_DIRECTORY / Path("installed_fonts.json")
HOME_BREW_FONT_RAW_API_FILE: Path = CACHE_DIRECTORY / "__raw_homeBrew-Fontify.json"
HOME_BREW_FONT_API_FILE: Path = CACHE_DIRECTORY / "homeBrew-Fontify.json"
HOME_BREW_FONT_FZF_FILE_INDEX: Path = CACHE_DIRECTORY / "font_list_fzf.txt"
HOME_BREW_FONT_API_FILE_INDEX_CACHE: Path = CACHE_DIRECTORY / "font_token_index_cache.py"

# PROJECT_DIR: Path = Path(path[0])
API_URL: str = "https://formulae.brew.sh/api/cask.json"

FONTS_APT_DATA: list[dict] = list(dict())
ARGS: argparse.Namespace = argparse.Namespace()

logging.basicConfig(
	level=logging.INFO,
	format="\033[92m%(asctime)s\033[0m - %(levelname)s - %(message)s",
	style="%",
	datefmt="%Y-%m-%d %H:%M:%S"
)

# ---------------- core logic ----------------


def argparseInit() -> argparse.Namespace:
	parser = argparse.ArgumentParser(
		description="A CLI tool for installing fonts from the internet",
		formatter_class=argparse.ArgumentDefaultsHelpFormatter,
	)

	# Version
	parser.add_argument(
		"--version", "-v",
		action="version",
		version=f"{VERSION} ({VERSION_NAME})"
	)

	# Global backup flag (add BEFORE parsing)
	parser.add_argument(
		"--backup", "-B",
		action="store_true",
		help="Generate an install command for fontify which will be used to install font(s) again",
	)

	parser.add_argument(
		"--list-installed", "-L",
		action="store_true",
		help="List all the fonts you have installed",
	)

	parser.add_argument(
		"--purge", "-P",
		action="store_true",
		help="Purge the download cache",
	)

	parser.add_argument(
		"--about",
		action="store_true",
		help="Print the full info about this tool",
	)

	# Subcommands
	subparsers = parser.add_subparsers(
		dest="command",
		required=False,  # Allow running without a subcommand
		help="Available commands"
	)

	# INSTALL COMMAND ============================
	install_parser = subparsers.add_parser(
		"install",
		help="Install the font(s) by name or ID"
	)
	install_parser.add_argument(
		"fonts",
		nargs="+",
		help=f"Font(s) to install into '{INSTALLED_FONTS_DIR}'"
	)
	# =====================================================

	# Info command (ONLY ONCE!) ===========================
	info_parser = subparsers.add_parser(
		"info", aliases=["I"],
		help="Get information about the font(s)"
	)
	info_parser.add_argument(
		"fonts",
		nargs="+",  # At least one font required for info
		help="Font(s) to get info about",
	)
	# =====================================================
	# fzf command =======================
	fzf_parser = subparsers.add_parser(
		"fzf",
		help="Use fzf to interactively select font(s)"
	)
	fzf_mode = fzf_parser.add_mutually_exclusive_group(required=True)
	fzf_mode.add_argument(
		"--info",
		action="store_true",
		help="Show info for selected font(s)"
	)
	fzf_mode.add_argument(
		"--install",
		action="store_true",
		help="Install selected font(s)"
	)
	# ================================

	# SEARCH COMMAND ============================
	search_parser = subparsers.add_parser(
		"search",
		aliases=["S", "s"],
		help="Search for a font in the database"
	)
	search_parser.add_argument(
		"query",
		nargs="+",
		help="Search query (one or more terms)"
	)
	# ============================================

	# Update command ======================================
	update_parser = subparsers.add_parser(
		"update",
		aliases=["U"],
		help="Update font(s) in the database"
	)
	update_parser.add_argument(
		"fonts",
		nargs="*",
		metavar="FONT",
		help="Font names to update. If none provided, updates all font(s).",
	)
	# =====================================================

	# Uninstall ============================
	uninstall_parser = subparsers.add_parser(
		"uninstall",
		aliases=["rm"],
		help="Uninstall installed font(s)"
	)
	uninstall_parser.add_argument(
		"fonts",
		nargs="+",
		metavar="FONT",
		help="Font names / (install font index(s)) / Token(s)   see --info option for more info",
	)
	# ======================================

	# Parse arguments
	args = parser.parse_args()
	return args


def getFontsFromRawApi(force: bool = False) -> list[dict]:
	"""
	Parse Homebrew cask API and extract font casks.
	Writes:
	  - filtered JSON
	  - indexed font list
	Returns:
	  - list of font cask dicts
	"""

	# If parsed cache already exists → load & return
	if not force and HOME_BREW_FONT_API_FILE.exists():
		with HOME_BREW_FONT_API_FILE.open(encoding="utf-8") as f:
			return load(f)

	with HOME_BREW_FONT_RAW_API_FILE.open(encoding="utf-8") as f:
		data: list[dict] = load(f)

	fonts: list[dict] = []
	index_lines: str = ""
	valid_font_index = 0
	ignored = 0

	for cask in data:
		artifacts = cask.get("artifacts", [])

		# detect font artifact (ANY artifact containing "font")
		has_font: bool = any("font" in artifact for artifact in artifacts)

		if not has_font:
			ignored += 1
			continue

		url = cask.get("url", "")
		if url.endswith((".git", ".exe")):
			ignored += 1
			continue

		# ---- CONVERTS ARTIFACTS: list[dict] -> list[str] ----
		artifacts_to_list: list[str] = [
			f
			for item in artifacts
			for f in item.get("font", [])
			if isinstance(f, str)
		]

		artifacts_to_list.sort()

		# ---- UPDATE CASK OBJECT ----
		cask["artifacts"] = artifacts_to_list

		index_lines+=(f"{valid_font_index:04} | {', '.join(cask.get('name', []))}\n")
		fonts.append(cask)
		valid_font_index += 1

	# write filtered JSON
	try:
		with HOME_BREW_FONT_API_FILE.open("w", encoding="utf-8") as f:
			f.write(dumps(fonts, indent=2))
	except JSONDecodeError as e:
		logging.error(f"Corrupted JSON database: {e}")
		exit(1)

	# write index file
	with HOME_BREW_FONT_FZF_FILE_INDEX.open("w", encoding="utf-8") as f:
		f.write(index_lines)

	logging.info(
		"Fonts parsed: %d | Ignored (GUI, CLI) : %d", valid_font_index, ignored
	)

	return fonts


def getRawApiFile(force: bool = False) -> bool:
	# Download raw API if missing OR force is enabled

	if force or not HOME_BREW_FONT_RAW_API_FILE.exists():
		logging.info(
			"Downloading Homebrew cask API%s",
			" (forced) " if force else "",
		)

		result = run(
			[
				# you can use [curl, aria2c, xh, snatch] also here
				"wget",
				"--show-progress",
				"-q",
				"-O",
				str(HOME_BREW_FONT_RAW_API_FILE),
				API_URL,
			],
			check=True
		)

		if result.returncode != 0:
			raise RuntimeError("system command wget failed")

	return True


def getUrlFileInfo(url: str) -> dict:
	r = requests.head(url, allow_redirects=True, timeout=15)
	filename: str = "unknown_filename"
	cd = r.headers.get("Content-Disposition", "")

	if "filename=" in cd:
		filename = cd.split("filename=", 1)[1].strip('"')
		# print(f"Filename from Content-Disposition: {filename}")

	return {
		"final_url": r.url,
		"file_name": filename,
		"content_type": r.headers.get("Content-Type", "unknown"),
		"content_length": int(r.headers.get("Content-Length", "0")),
		"status": r.status_code,
	}


def install(fonts: list[int], update_type: bool = False) -> bool:
	install_font_db: dict[str, dict] = {}
	fun_run_type: str = "Updating: " if update_type else "Installing: "

	# ---- load existing database ----
	if INSTALLED_FONTS_DATA_BASE.exists():
		logging.info(
			"Loading installed fonts database: %s",
			INSTALLED_FONTS_DATA_BASE,
		)
		with INSTALLED_FONTS_DATA_BASE.open("r", encoding="utf-8") as f:
			install_font_db = load(f)

			if not install_font_db:
				logging.error("No fonts installed yet!!.")

	install_font_db_keys: list[str] = list(install_font_db.keys())
	font_will_be_install: list[dict] = []  # [ {"index": int, "url_info": dict} ]

	# ---- PRE-INSTALL / USER INFO COLLECTING DATA LOOP ----
	for idx in fonts:
		font_dict: dict = FONTS_APT_DATA[idx]

		# font names are lists → take primary name
		names: list[str] = font_dict.get("name", [])
		font_name: str   = names[0] if names else "unknown-font"
		version: str     = font_dict.get("version", "unknown")

		font_key: Path = Path(f"{INSTALLED_FONTS_DIR}/{font_name}-v{version}".lower().replace(" ", "_"))

		url: str = font_dict.get("url", "")

		# ---- Already installed check (path + sha256) ----
		if str(font_key) in install_font_db_keys:
			installed_font_db: dict[str, dict] = install_font_db[str(font_key)]
			if installed_font_db.get("sha256") == font_dict.get("sha256"):
				logging.info('Font "%s" already installed (v%s)', font_name, version)
				continue

		# ---- VALIDATE URL REACHABILITY ----
		logging.info('Gathering info about: Id - [%d] "%s"', idx, font_name)
		online_file_info: dict = getUrlFileInfo(url)
		if (
			online_file_info.get("status") != 200
			or online_file_info.get("content_type", "unknown") == "unknown"
		):
			logging.error("URL not reachable: %s", url)
			continue
		elif online_file_info.get("file_name", "") == "unknown_filename":
			logging.error("IDX [%d] Not have a valid name URL: %s-v%s", idx, url, version)
			continue

		font_will_be_install.append(
			{
				"index": idx,
				"url_info": online_file_info
			}
		)

	if len(font_will_be_install) == 0:
		logging.error("No fonts to install")
		exit(1)

	# ----- PRINT USER PROMPT AND INFO LOOP ------
	total_font_will_be_install: int = 0
	total_font_size_in_bytes: int   = 0
	print(f"\n{fun_run_type} fonts to \"{INSTALLED_FONTS_DIR}\"")

	for indx in font_will_be_install:
		idx: int = indx.get("index", 0)
		font_dict: dict = FONTS_APT_DATA[idx]

		artifacts: list[str] = font_dict.get("artifacts", [])
		artifacts_len: int = len(artifacts)

		names: list[str] = font_dict.get("name", [])
		url: str = font_dict.get("url", "")
		version: str = font_dict.get("version", "unknown")

		total_font_will_be_install += artifacts_len

		content_length = indx.get("url_info", {}).get("content_length", 0)
		try:
			total_font_size_in_bytes += int(content_length)
		except (TypeError, ValueError):
			pass  # ignore invalid size

		font_name = ", ".join(names) if names else "Unknown"

		print(f"ID: [{idx:4}] Font: \"{font_name}-v{version}\" Files: {artifacts_len}")

	total_font_size_in_mb: str = f"{total_font_size_in_bytes / (1024 * 1024):.2f} MB"

	confirm = (
		input(
			"============================================================\n"
			f"Total size: {total_font_size_in_mb}\n"
			f"Total: {total_font_will_be_install} files will be added [y/N]: "
		)
		.strip()
		.lower()
	)

	if confirm != "y":
		exit(1)

	# ---- INSTALL LOOP ----
	FONTIFY_DOWNLOAD_CACHE.mkdir(mode=0o744, exist_ok=True)
	for indx in font_will_be_install:
		idx: int = indx.get("index", 0)
		font_dict: dict = FONTS_APT_DATA[idx]

		# font names are lists → take primary name
		names: list[str] = font_dict.get("name", [])
		font_name: str = names[0] if names else "unknown-font"
		version: str = font_dict.get("version", "unknown")

		font_key: Path = Path(f"{INSTALLED_FONTS_DIR}/{font_name}-v{version}".lower().replace(" ", "_"))

		artifacts: list[str] = font_dict.get("artifacts", [])
		# ---- COUNT ACTUAL FONT FILES ----
		font_files: int = len(artifacts)
		url: str = font_dict.get("url", "")

		# ---- DOWNLOAD FONT ARCHIVE ----
		FONTIFY_DOWNLOAD_CACHE_DIR_FILE_NAME: Path = (FONTIFY_DOWNLOAD_CACHE / indx.get("url_info", {}).get("file_name", ""))
		logging.info("Downloading font [%s-v%s]", font_name, version)
		logging.info("From url: %s", url)
		result = run([
			"wget",
			"--show-progress",
			"-qc",
			"-O",
			str(FONTIFY_DOWNLOAD_CACHE_DIR_FILE_NAME),
			url,
		])

		if result.returncode != 0:
			logging.error("Failed to download: %s", font_dict.get("url"))
			exit(result.returncode)
		else:
			logging.info("Download successfully: %s", font_dict.get("url"))

		font_key.mkdir(mode=0o755, parents=True, exist_ok=True)

		if font_files == 1:
			# ---- SINGLE FONT FILE ----
			logging.info("Installing single font file to: %s", str(font_key))
			result = run(
				[
					"mv",
					"-v",
					str(FONTIFY_DOWNLOAD_CACHE_DIR_FILE_NAME),
					str(font_key / FONTIFY_DOWNLOAD_CACHE_DIR_FILE_NAME.name)
				]
			)

			if result.returncode != 0:
				logging.error("Failed to move font file to: %s", str(font_key))
				run(
					[
						"rmdir",
						"-v",
						str(font_key)
					]
				)
				exit(result.returncode)

		# check the file type for multiple font files
		else:
			# ---- PREPARE DIRECTORIES ----
			font_key.mkdir(mode=0o755, parents=True, exist_ok=True)

			# ---- Extracting the FONT ARCHIVE ----
			result = run(
				[
					"bsdtar",
					"-vxf",
					str(FONTIFY_DOWNLOAD_CACHE_DIR_FILE_NAME),
					"-C",
					str(font_key),
					"*.ttf"
					# Todo: READ man bsdtar for more file type support
					# or use globe pattern like *.otf, *.ttf

					# Fix: till now this program is not working with otf files [READ man bsdtar]
				]
			)

			if result.returncode != 0:
				logging.error("Failed to move font file to: %s", str(font_key))
				run(
					[
						"rmdir",
						"-v",
						str(font_key)
					]
				)
				exit(result.returncode)

			logging.info(
				'Installed font "%s" (%d font files)',
				str(font_key),
				font_files,
			)

		# ---- UPDATE INSTALL DATABASE ----
		install_font_db[str(font_key)] = {
			"path_name": str(font_key),
			"name": names,
			"sha256": font_dict.get("sha256"),
			"version": version,
			"styles": font_files,
			"size": indx.get("url_info", {}).get("content_length", 0),
			"size_mb": f"{indx.get('url_info', {}).get('content_length', 0) / (1024 * 1024):.2f} MB",
			"full_token": font_dict.get("full_token"),
			"url": font_dict.get("url"),
		}

	# ---- write database ----
	with INSTALLED_FONTS_DATA_BASE.open("w", encoding="utf-8") as f:
		f.write(dumps(install_font_db, indent=2))

	return True


def init() -> list[dict]:
	CACHE_DIRECTORY.mkdir(mode=0o744, parents=True, exist_ok=True)

	if not getRawApiFile():
		exit(1)

	# parse fonts
	return getFontsFromRawApi()


def update(fonts: list[int]) -> bool:
	getRawApiFile(force=True)
	getFontsFromRawApi(force=True)

	# TODO: add logic to not update if the checksum(SHA256) for the font is same [allredy done on line no 327]
	# Todo: Add logic to updating some specific[index] / --all fonts
	if len(fonts) == 1 and fonts[0] == -1:
		pass
	else:
		pass

	return True


def fzf() -> list[int]:
	if not HOME_BREW_FONT_FZF_FILE_INDEX.exists():
		getFontsFromRawApi()

	result = run(
		# https://github.com/skim-rs/skim
		# Note: Use can also use fzf here
		f"sk -m --prompt '<Tab> for multiple selection: ' < '{str(HOME_BREW_FONT_FZF_FILE_INDEX)}'",
		shell=True,
		text=True,
		capture_output=True
	)

	if result.returncode == 1:
		logging.info("Not selected any font")
		exit(1)
	elif result.returncode == 130:
		logging.info(("Not selected any font"))
		exit(130)
	elif result.returncode != 0:
		raise RuntimeError("fzf have a problem")

	fonts_to_install: list[str] = result.stdout.strip().splitlines()
	fonts_to_install_index: list[int] = list()

	for i in fonts_to_install:
		fonts_to_install_index.append(int(i.split("|")[0]))

	return fonts_to_install_index


def getIndex(fonts: list[str]) -> list[int]:
	new_fonts_index: list[int] = []
	matched = False

	for font in fonts:
		# --- case 1: numeric index ---
		if isinstance(font, str) and font.isdigit():
			idx = int(font)
			if 0 <= idx < len(FONTS_APT_DATA):
				new_fonts_index.append(idx)
				matched = True
				logging.info(f"Matched font index: [%d] => \"{FONTS_APT_DATA[idx].get('name', [])[0]}\"", idx)
			continue

		# --- case 2: font name ---
		for i, data in enumerate(FONTS_APT_DATA):
			names = data.get("name", [])
			if font in names:
				new_fonts_index.append(i)
				matched = True
				break

		if not matched:
			logging.error(f"No '{font}' font found in the API database")
			matched = False

	return sorted(set(new_fonts_index))


def printInfoPage(fonts_indexs: list[int]) -> None:
	for idx in fonts_indexs:
		font_dict: dict = FONTS_APT_DATA[idx]
		info = (
			f"Index - ID    : {idx}\n"
			f"Name          : {', '.join(font_dict['name'])}\n"
			f"Token         : {font_dict.get('full_token', 'N/A')}\n"
			f"Homepage      : {font_dict.get('homepage', 'N/A') or 'N/A'}\n"
			f"Font files    : {len(font_dict.get('artifacts', []))}\n"
			f"Version       : {font_dict.get('version', 'N/A')}\n"
			f"GET URL       : {font_dict.get('url', 'N/A')}\n"
		)

		print(info)


def search(fonts: str) -> int:
	print(" ID     Font name")

	# Note: Grep will only work with unix like System for windows use some thing else
	# USER rg with
	result = run(
		[
			"grep",
			"-i",
			"--color=auto",
			"-E",
			fonts,
			str(HOME_BREW_FONT_FZF_FILE_INDEX),
		]
	)

	return_code = result.returncode
	if return_code == 1:
		logging.error(f'Font: "{fonts}" not found in API')

	return return_code


def backUp(program_name: str = "fontify") -> None:
	# load existing database
	if not INSTALLED_FONTS_DATA_BASE.exists():
		logging.error(f"There is no file for {INSTALLED_FONTS_DATA_BASE}")
		return

	with INSTALLED_FONTS_DATA_BASE.open(encoding="utf-8") as f:
		install_font_data: dict = load(f)

	if not install_font_data:
		logging.error("No fonts installed yet!!")
		return

	for _, font in install_font_data.items():
		names = font.get("name", [])

		if not names:
			continue

		# print restore command
		print(f'{program_name} install "{names[0]}"')


def uninstallInstalledFont(fonts: list[str]) -> bool:
	# Todo: convert this function to as only (string not list[str])

	# ---- VALIDATE DATABASE ----
	if not INSTALLED_FONTS_DATA_BASE.exists():
		logging.error("Installed fonts database not found")
		return False

	# ---- LOAD DATABASE ----
	try:
		with INSTALLED_FONTS_DATA_BASE.open("r", encoding="utf-8") as f:
			db: dict[str, dict] = load(f)
	except JSONDecodeError as e:
		logging.error(f"Corrupted JSON database: {e}")
		return False

	if not db:
		logging.info("No installed fonts to uninstall")
		return False

	db_keys: list[str] = list(db.keys())

	# ---- RESOLVE FONT SELECTORS → DB INDICES ----
	def get_index_of_installed_font(_fonts: list[str]) -> list[int]:
		indices: list[int] = []

		# ---- generate index of installed fonts ----
		for font in _fonts:
			# case 1: numeric index (1-based)
			if font.isdigit():
				idx = int(font)
				if 1 <= idx <= len(db_keys):
					indices.append(idx - 1)
				else:
					logging.error(f"Font index out of range: {font}")
				continue

			# case 2: exact path
			if font in db:
				# Todo: $fontify rm "IMB" is should be the full name match not partial
				indices.append(db_keys.index(font))
				continue

			# case 3: token or name match
			for i, (_, meta) in enumerate(db.items()):
				token = meta.get("full_token", "")
				names = meta.get("name", [])

				if font == token or any(font.lower() in n.lower() for n in names):
					# Todo: $fontify rm "IMB" is should be the full name match not partial
					indices.append(i)
					break
			else:
				logging.error(f"Font not found: {font}")

		# remove duplicates, preserve order
		return list(dict.fromkeys(indices))

	# ---- RESOLVE TARGETS ----
	installed_font_index: list[int] = get_index_of_installed_font(fonts)

	remove_entries_from_json: list[int] = []
	# ---- UNINSTALL LOOP ----
	for i in installed_font_index:
		font_dir_path: Path = Path(db_keys[i])
		meta: dict = db[db_keys[i]]
		font_name: str = ", ".join(meta.get("name", []))

		try:
			if font_dir_path.exists():
				run(
					[
						"rm",
						"-vr",
						str(font_dir_path)
					]
				)
			else:
				logging.error(f"Font directory already missing: {font_dir_path}")
		except Exception as e:
			logging.error(f"Failed to uninstall {font_name}: {e}")
			return False
		else:
			remove_entries_from_json.append(i)


	# ---- UPDATE DATABASE ----
	# Why I hvae use this way becuase if we remove item from dict while iterating it will cause issue
	# so first we collect all the index we want to remove and then we remove them in another loop
	# this way we can avoid the issue
	for i in remove_entries_from_json:
		font_name: str = db[db_keys[i]].get("name", ["N/A"])
		db.pop(db_keys[i], None)
		logging.info(f"Uninstalled font: {font_name}")

	# ---- WRITE UPDATED DATABASE ----
	with INSTALLED_FONTS_DATA_BASE.open("w", encoding="utf-8") as f:
		dump(db, f, indent=2)

	return True


def list_all_installed_fonts() -> None:
	# ---- validate database ----
	if not INSTALLED_FONTS_DATA_BASE.exists():
		logging.error(f"No installed fonts database found: {INSTALLED_FONTS_DATA_BASE}")
		return

	# ---- load database ----
	try:
		with INSTALLED_FONTS_DATA_BASE.open("r", encoding="utf-8") as f:
			db: dict[str, dict] = load(f)
	except JSONDecodeError as e:
		logging.error(f"Corrupted JSON database: {e}")
		return

	if not db:
		logging.error("No fonts installed yet!!.")
		return

	# ---- display fonts ----
	for idx, (path, meta) in enumerate(db.items(), start=1):
		name = ", ".join(meta.get("name", []))
		version = meta.get("version", "unknown")
		styles = meta.get("styles", 0)
		token = meta.get("full_token", "N/A")

		print(f"[{idx}] \"{name}\"")
		print(f"    Version : {version}")
		print(f"    Styles  : {styles}")
		print(f"    Token   : {token}")
		print(f"    Size    : {meta.get('size_mb', 'N/A')}")
		print(f"    Path    : {path}\n")


def about() -> None:
	config_string: str = f"""
	Fontify\n-------

	Version:
	  VERSION            : {VERSION}
	  VERSION_MAJOR      : {VERSION_MAJOR}
	  VERSION_MINOR      : {VERSION_MINOR}

	Directories:
	  CACHE_DIRECTORY        : {CACHE_DIRECTORY}
	  INSTALLED_FONTS_DIR    : {INSTALLED_FONTS_DIR}

	Cache / Data Files:
	  INSTALLED_FONTS_DB                    : {INSTALLED_FONTS_DATA_BASE}
	  HOMEBREW_RAW_API_FILE                 : {HOME_BREW_FONT_RAW_API_FILE}
	  HOMEBREW_API_FILE                     : {HOME_BREW_FONT_API_FILE}
	  HOMEBREW_FZF_INDEX                    : {HOME_BREW_FONT_FZF_FILE_INDEX}
	  HOME_BREW_FONT_API_FILE_INDEX_CACHE   : {HOME_BREW_FONT_API_FILE_INDEX_CACHE}

	API:
	  API_URL            : {API_URL}

	Runtime:
	  FONTS_APT_DATA_LEN : {len(FONTS_APT_DATA)}
	  ARGS               : {ARGS}
	"""
	print(config_string.strip())


def chedk_for_out_dateed_fonts():
	pass


def puruge() -> None:
	if FONTIFY_DOWNLOAD_CACHE.exists():
		logging.info("Purgeing download cache: %s", FONTIFY_DOWNLOAD_CACHE)
		result = run(
			[
				"rm",
				"-rvf",
				str(FONTIFY_DOWNLOAD_CACHE)
			]
		)

		if result.returncode == 0:
			logging.info("Purged Downloaded cache: %s", FONTIFY_DOWNLOAD_CACHE)

# ---------------- run ----------------
if __name__ == "__main__":
	ARGS = argparseInit()

	# ---- NO COMMAND → show usage ----
	# if ARGS.command is None:
	# todo: add small help page
	# ARGS.parser().print_usage()
	# exit(0)

	if ARGS.backup:
		backUp()
		exit(0)
	elif ARGS.about:
		about()
		exit(0)
	elif ARGS.purge:
		puruge()
		exit(0)
	elif ARGS.list_installed:
		list_all_installed_fonts()
		exit(0)
	elif ARGS.command in ("search", "S", "s"):
		exit(search(" ".join(ARGS.query)))
	elif ARGS.command in ("uninstall", "rm"):
		exit(uninstallInstalledFont(list(ARGS.fonts)))

	# ---- command dispatch ----
	FONTS_APT_DATA = init()
	logging.info("Loaded %d fonts form brew cask API", len(FONTS_APT_DATA))

	if ARGS.command == "fzf":
		fzf_index: list[int] = fzf()

		if ARGS.info:
			printInfoPage(fzf_index)
		elif ARGS.install:
			install(fzf_index)
	elif ARGS.command == "install":
		font_identifiers = getIndex(list(ARGS.fonts))
		exit(install(font_identifiers))
	elif ARGS.command in ("info", "I"):
		font_identifiers = getIndex(list(ARGS.fonts))
		printInfoPage(font_identifiers)
	elif ARGS.command in ("update", "U"):
		if ARGS.fonts:
			font_identifiers = getIndex(list(ARGS.fonts))
			update(font_identifiers)
		else:
			update([-1])
