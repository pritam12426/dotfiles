#!/usr/bin/env python3

import argparse
from pathlib import Path

import bencodepy as bt  # pip install bencode.py

parser = argparse.ArgumentParser(
	prog="abouttorrent",
	description="Inspect .torrent files and display contained files with sizes",
)

parser.add_argument(
	"file",
	nargs="+",
	type=Path,
	help="Path to one or more torrent files",
)

args = parser.parse_args()


def human_size(size: int) -> str:
	units = ["B", "KB", "MB", "GB", "TB"]
	s = float(size)
	i = 0

	while s >= 1024 and i < len(units) - 1:
		s /= 1024
		i += 1

	return f"{s:.2f} {units[i]}"


def process_torrent(file: Path) -> dict:
	with file.open("rb") as f:
		return bt.decode(f.read())


def print_torrent_info(data: dict) -> None:
    info = data[b"info"]
    torrent_name = info[b"name"].decode("utf-8", errors="replace")

    print(f"Torrent Name: {torrent_name}\n")

    rows = []
    total_size = 0

    # Multi-file torrent
    if b"files" in info:
        for i, file_entry in enumerate(info[b"files"], start=1):
            file_size = file_entry[b"length"]
            total_size += file_size

            file_path = "/".join(
                part.decode("utf-8", errors="replace")
                for part in file_entry[b"path"]
            )

            rows.append([str(i), file_path, human_size(file_size)])

    # Single-file torrent
    else:
        file_size = info[b"length"]
        total_size = file_size
        rows.append(["1", torrent_name, human_size(file_size)])

    # Column headers
    headers = ["IDX", "FILE", "SIZE"]

    # Determine column widths
    col_widths = [
        max(len(headers[0]), max(len(row[0]) for row in rows)),
        max(len(headers[1]), max(len(row[1]) for row in rows)),
        max(len(headers[2]), max(len(row[2]) for row in rows)),
    ]

    def make_border(left: str, middle: str, right: str) -> str:
        return (
            left
            + "─" * (col_widths[0] + 2)
            + middle
            + "─" * (col_widths[1] + 2)
            + middle
            + "─" * (col_widths[2] + 2)
            + right
        )

    # Top border
    print(make_border("┌", "┬", "┐"))

    # Header row
    print(
        f"│ {headers[0]:<{col_widths[0]}} "
        f"│ {headers[1]:<{col_widths[1]}} "
        f"│ {headers[2]:<{col_widths[2]}} │"
    )

    # Separator
    print(make_border("├", "┼", "┤"))

    # Data rows
    for row in rows:
        print(
            f"│ {row[0]:<{col_widths[0]}} "
            f"│ {row[1]:<{col_widths[1]}} "
            f"│ {row[2]:<{col_widths[2]}} │"
        )

    # Bottom border
    print(make_border("└", "┴", "┘"))

    print(f"\nTotal Size: {human_size(total_size)}")

    # Tracker info
    announce = data.get(b"announce")
    if announce:
        tracker = announce.decode("utf-8", errors="replace")
        print(f"Tracker: {tracker}")

for file in args.file:
	if not file.exists():
		print(f"\nError: File not found -> {file}")
		continue

	try:
		torrent_data = process_torrent(file)
		print_torrent_info(torrent_data)

	except Exception as e:
		print(f"\nFailed to process {file}: {e}")
