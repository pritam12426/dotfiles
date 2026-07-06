#!/usr/bin/env python3

from __future__ import annotations

from argparse import ArgumentParser
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict


def detect_font_dir() -> Path:
	linux_dir = Path("/usr/share/fonts")
	macos_dir = Path("~/Library/Fonts").expanduser()

	if linux_dir.exists():
		return linux_dir

	if macos_dir.exists():
		return macos_dir

	raise FileNotFoundError("Unsupported operating system")


def group_fonts(font_dir: Path) -> dict[str, list[Path]]:
	families: DefaultDict[str, list[Path]] = defaultdict(list)

	for font in font_dir.rglob("*"):
		if not font.is_file():
			continue

		if font.suffix.lower() not in {".ttf", ".otf"}:
			continue

		name = font.stem

		# Split only on last "-"
		if "-" in name:
			family, _style = name.rsplit("-", 1)
		else:
			family = name

		families[family].append(font)

	return dict(sorted(families.items()))


def print_info(groups: dict[str, list[Path]], show_info: bool = False) -> None:
	for family in sorted(groups):
		fonts = sorted(groups[family])

		print(f"\n{family}")
		print("-" * len(family))

		if show_info:
			print(f"Total fonts: {len(fonts)}")
			print()

		for font in fonts:
			print(f"  {font.name}")


def generate_report(groups: dict[str, list[Path]]) -> None:
	total_families = len(groups)
	total_fonts = sum(len(v) for v in groups.values())

	print("\nReport")
	print("======")
	print(f"Total font families : {total_families}")
	print(f"Total font files    : {total_fonts}")

	largest_family = max(groups.items(), key=lambda x: len(x[1]), default=None)

	if largest_family:
		family_name, family_fonts = largest_family

		print(f"Largest family      : {family_name}")
		print(f"Fonts in family     : {len(family_fonts)}")


def organize_fonts(font_dir: Path, dry_run: bool = False) -> None:
	moved = 0

	for font in font_dir.iterdir():
		if not font.is_file():
			continue

		if font.suffix.lower() not in {".ttf", ".otf"}:
			continue

		name = font.stem

		# Determine family name
		if "-" in name:
			family, _style = name.rsplit("-", 1)
		else:
			family = name

		target_dir = font_dir / family
		target_file = target_dir / font.name

		# Already organized
		if font.parent == target_dir:
			continue

		print(f"{font.relative_to(font_dir)} -> {target_file.relative_to(font_dir)}")

		if not dry_run:
			target_dir.mkdir(parents=True, exist_ok=True)
			font.rename(target_file)

		moved += 1

	print(f"\nMoved fonts: {moved}")


parser = ArgumentParser(
	prog="fontmap",
	description="Group system fonts by family names",
)

parser.add_argument(
	"--report",
	"-R",
	action="store_true",
	default=True,
	help="Generate report (default: true)",
)

parser.add_argument(
	"--dry-run",
	"-n",
	action="store_true",
	default=False,
	help="Dry run mode",
)

parser.add_argument(
	"--group",
	"-G",
	action="store_true",
	default=False,
	help="Print grouped fonts",
)

parser.add_argument(
	"--info",
	"-I",
	action="store_true",
	default=False,
	help="Show extra information for each family",
)

args = parser.parse_args()

font_dir = detect_font_dir()

if args.dry_run:
	print("[DRY RUN]")
	print(f"Font directory: {font_dir}")

groups = group_fonts(font_dir)

if args.group:
	organize_fonts(font_dir, dry_run=args.dry_run)
	exit(0)

if args.info:
	print_info(groups, show_info=True)

if args.report:
	generate_report(groups)
