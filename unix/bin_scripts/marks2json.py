#!/usr/bin/env python3

import argparse
from json import dump
from pathlib import Path
from urllib.parse import urlparse

URL_SCHEMES = (
	"http://",
	"https://",
	"file://",
	"ftp://",
	"ftps://",
	"sftp://",
	"ws://",
	"wss://",
	"ssh://",
	"git://",
	"mailto:",
	"tel:",
	"sms:",
	"geo:",
	"magnet:",
	"gemini://",
	"gopher://",
	"data:",
	"ipfs://",
	"ipns://",
	"webcal://",
	"spotify:",
	"steam://",
	"slack://",
	"zoommtg://",
	"discord://",
)

def format_category_name(filename: str) -> str:
	"""Format filename to nice category name"""
	name = Path(filename).stem
	name = name.replace("_", " ")
	name = " ".join(word.capitalize() for word in name.split())
	return name


def get_domain(url: str) -> str:
	"""Extract clean domain from URL"""
	try:
		parsed = urlparse(url)
		domain = parsed.hostname
		if domain and domain.startswith("www."):
			domain = domain[4:]
		return domain.lower()
	except Exception:
		return ""


def get_favicon_url(url: str) -> str:
	"""Generate Google favicon URL"""
	try:
		domain = urlparse(url).hostname
		return f"https://www.google.com/s2/favicons?sz=64&domain={domain}"
	except Exception:
		return ""


def parse_bookmark_line(line: str):
	"""Parse a single bookmark line"""
	if not line or line.strip().startswith("#"):
		return None

	parts = [x.strip() for x in line.strip().split("|") if x.strip()]

	title = ""
	url = ""
	description = ""
	tags = []

	for part in parts:
		if part.startswith(URL_SCHEMES):
			url = part
		elif part.startswith("#"):
			tags.extend(tag.replace("#", "").strip() for tag in part.split() if tag.startswith("#") and tag.replace("#", "").strip())
		elif not title:
			title = part
		elif not description:
			description = part

	if not url:
		return None

	return {
		"title": title,
		"url": url,
		"description": description,
		"tags": tags,
		"icon": get_favicon_url(url),
	}


parser = argparse.ArgumentParser(prog="dotmason", description="Convert bookmark .txt files to JSON database")
parser.add_argument("inputs", type=Path, nargs="+", help="Input .txt bookmark files (or directories of them)")
args = parser.parse_args()

txt_files = []

for path in args.inputs:
	if path.is_dir():
		txt_files.extend(sorted(path.glob("*.txt")))
	elif path.is_file() and path.suffix == ".txt":
		txt_files.append(path)
	else:
		parser.error(f"Input must be a .txt file or a directory of .txt files: {path}")

txt_files = sorted(set(txt_files))

# args.outputdir.mkdir(parents=True, exist_ok=True)

print("🚀 Starting Bookmark Generator...")
print(f"📂 Reading from: {', '.join(str(p) for p in args.inputs)}")

book_marks = []

for file_path in txt_files:
	category_name = format_category_name(file_path.name)

	with file_path.open("r", encoding="utf-8") as f:
		lines = f.readlines()

	bookmarks = []

	for line in lines:
		bookmark = parse_bookmark_line(line)
		if not bookmark:
			continue

		bookmarks.append(bookmark)

	if bookmarks:
		book_marks.append({"category": category_name, "bookmarks": bookmarks})
		print(f"   📄 Processing: {file_path.name} ({len(bookmarks)} bookmarks)")


output_file = args.outputdir / "bookmarks.json"

with output_file.open("w", encoding="utf-8") as f:
	dump(book_marks, f, indent=2, ensure_ascii=False)


print(f"\n📊 Total Categories: {len(book_marks)}")
print(f"📈 Total Bookmarks: {sum(len(cat['bookmarks']) for cat in book_marks)}")
print(f"💾 Saved to: {output_file}")
