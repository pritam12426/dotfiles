#!/usr/bin/env python3

from argparse import ArgumentParser
from pathlib import Path

RAW       = "raw"
FORMATTED = "formatted"
INVALID   = "invalid"

MAX_PIPES = 3   # title | url | description | tags  →  3 pipes, 4 columns


def get_column_widths(rows: list[list[str]]) -> list[int]:
	widths: list[int] = []

	for row in rows:
		for index, column in enumerate(row):
			if index >= len(widths):
				widths.append(len(column))
			else:
				widths[index] = max(widths[index], len(column))

	return widths


def format_row(row: list[str], widths: list[int]) -> str:
	parts = []

	for index, column in enumerate(row):
		# Only pad non-final columns — last column needs no trailing spaces
		if index < len(row) - 1:
			parts.append(column.ljust(widths[index]))
		else:
			parts.append(column)

	return " | ".join(parts)


def parse_file(
	file: Path,
) -> tuple[list[tuple[str, list[str] | str]], list[list[str]], list[tuple[int, str]]]:
	"""
	Returns:
	  parsed_lines  — list of (kind, content) for every line
	  valid_rows    — only the rows that will be formatted
	  violations    — list of (line_number, raw_line) that exceed MAX_PIPES
	"""
	lines      = file.read_text(encoding="utf-8").splitlines()
	parsed     : list[tuple[str, list[str] | str]] = []
	valid_rows : list[list[str]] = []
	violations : list[tuple[int, str]] = []

	for lineno, line in enumerate(lines, start=1):
		# Shebang lines and comments — keep as-is
		if not line.strip() or "|" not in line:
			parsed.append((RAW, line))
			continue

		pipe_count = line.count("|")

		if pipe_count > MAX_PIPES:
			violations.append((lineno, line))
			parsed.append((INVALID, line))   # kept verbatim, reported to user
			continue

		# Skip rows that are all-empty columns (e.g. "| | |")
		row = [col.strip() for col in line.split("|")]
		if not any(row):
			parsed.append((RAW, line))
			continue

		parsed.append((FORMATTED, row))
		valid_rows.append(row)

	return parsed, valid_rows, violations


def format_file(file: Path, dry_run: bool = False, check: bool = False) -> bool:
	"""
	Format one file.
	Returns True if the file content would change (or did change).
	"""
	parsed, valid_rows, violations = parse_file(file)

	# Report violations immediately
	if violations:
		print(f"  ⚠  {len(violations)} line(s) exceed {MAX_PIPES} pipes and were skipped:")
		for lineno, raw in violations:
			print(f"     line {lineno}: {raw.rstrip()}")

	if not valid_rows:
		print(f"  (nothing to format in {file.name})")
		return False

	widths = get_column_widths(valid_rows)

	final_lines: list[str] = []

	for kind, content in parsed:
		if kind == FORMATTED:
			final_lines.append(format_row(content, widths))  # type: ignore[arg-type]
		else:
			# RAW and INVALID are kept verbatim
			final_lines.append(content)  # type: ignore[arg-type]

	new_text    = "\n".join(final_lines) + "\n"
	orig_text   = file.read_text(encoding="utf-8")
	would_change = new_text != orig_text

	status_parts = [f"{len(valid_rows)} line(s) formatted"]
	if violations:
		status_parts.append(f"{len(violations)} skipped")

	if dry_run:
		flag = "would change" if would_change else "already clean"
		print(f"  dry-run  {file}  [{flag}]  —  {', '.join(status_parts)}")
	elif check:
		flag = "needs formatting" if would_change else "ok"
		print(f"  check    {file}  [{flag}]  —  {', '.join(status_parts)}")
	else:
		if would_change:
			file.write_text(new_text, encoding="utf-8")
		flag = "written" if would_change else "already clean"
		print(f"  {flag:13s} {file}  —  {', '.join(status_parts)}")

	return would_change


parser = ArgumentParser( prog="bookmarkfmt", description="Format pipe-separated bookmark .txt files")
parser.add_argument( "file", nargs="+", type=Path, help="Path to one or more .txt files")
parser.add_argument( "--dry-run", action="store_true", help="Preview changes without writing to disk")
parser.add_argument( "--check", action="store_true", help="Exit with code 1 if any file would be changed (useful for CI / git hooks)")
args = parser.parse_args()

any_changed = False

for file in args.file:
	if not file.exists():
		print(f"  error    {file}: file does not exist")
		continue

	if not file.is_file():
		print(f"  error    {file}: not a file")
		continue

	changed = format_file(file, dry_run=args.dry_run, check=args.check)
	if changed:
		any_changed = True

if args.check and any_changed:
	raise SystemExit(1)
