#!/usr/bin/env python3

from pathlib import Path
from subprocess import run

TEMP_DIR: Path = Path("/tmp/nerd-fonts-install")
FONT_DIR: Path = Path.home() / "Library" / "Fonts"
TEMP_DIR.mkdir(parents=True, exist_ok=True)

NF_VERSION: str = "v3.4.0"
# BASE_URL: str = f"https://github.com/ryanoasis/nerd-fonts/releases/tag/{NF_VERSION}"
BASE_URL: str = "https://github.com/ryanoasis/nerd-fonts/releases/latest"
ARCHIVE: str = ".tar.xz"


def installFont(font_name: str) -> None:
	print("=" * 120)
	print(f"🔤 Installing Nerd Font: {font_name} ...")

	font_file_name: str        = f"{font_name}-NerdFont-{NF_VERSION}"
	download_url: str          = f"{BASE_URL}/download/{font_name}{ARCHIVE}"
	archive_path: Path         = TEMP_DIR / font_file_name
	archive_extract_dir: Path  = TEMP_DIR / f"{font_file_name}-extracted"
	font_install_dir: Path     = FONT_DIR / font_file_name

	if font_install_dir.exists():
		print(f"\n❎ Font {font_name} already installed at {font_install_dir}, skipping...")
		return

	print("☁️  Downloading font archive url %s" % download_url)
	print(f" -> {archive_path}")
	run(
		[
			"wget",
			"--show-progress",
			"-qLc",
			"-O",
			str(archive_path),
			download_url
		],
		check=True)

	print(f"✅ Downloaded font archive successful to {archive_path}")
	# Extract the archive

	print(f"📤 Extracting font archive {archive_path.name} to {archive_extract_dir.name}")

	archive_extract_dir.mkdir(parents=True, exist_ok=True)
	run(
		[
			"tar",
			"-xf",
			str(archive_path),
			"-C",
			str(archive_extract_dir)
		]
	)

	# Move the font files to the Fonts directory
	# for font_file in archive_extract_dir.glob("**/*.ttf"): #fix select **/.otf also
	font_install_dir.mkdir(exist_ok=True)
	print(f"\n📥 Installing {font_file_name} to {font_install_dir} ...")
	for font_file in (archive_extract_dir.rglob("*.[to]tf")):
		run(
			[
				"mv",
				str(font_file),
				str(font_install_dir) + "/"
			]
		)
		print(f"   * {font_file.name}")
		# print(" ".join(h))

	# Clean up
	print("\n🗑️ Cleaning up temporary files...")
	run(
		[
			"rm",
			"-rfv",
			str(archive_extract_dir)
		]
	)
	return


neard_fonts: list[str] = [
	"CascadiaCode",
	"CascadiaMono",
	"FiraCode",
	"Hack",
	"Inconsolata",
	"JetBrainsMono",
	"Meslo",
	"Mononoki",
	"RobotoMono",
	"Monaspace"
	"SourceCodePro",
	"UbuntuMono"
]

for font in neard_fonts:
	installFont(font)
