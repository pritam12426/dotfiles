#!/usr/bin/env python3
import os
import shlex
import subprocess
import sys

"""
pkg-config-static.py
macOS static-link translator for pkg-config.

Translates -L<dir> -l<name> to -Wl,-force_load,<dir>/lib<name>.a
when the static library (.a) exists, for use with clang/ld on macOS.
Removes replaced -l<name> and unnecessary -L<dir> if possible.
"""


def run_pkg_config(args):
	try:
		return subprocess.check_output(["pkg-config"] + args, text=True).strip()
	except subprocess.CalledProcessError as e:
		# pkg-config errors should propagate the output and exit code
		sys.stderr.write(e.output)
		sys.exit(e.returncode)
	except FileNotFoundError:
		sys.stderr.write("pkg-config not found in PATH\n")
		sys.exit(127)
	except Exception as e:
		sys.stderr.write(f"Unexpected error running pkg-config: {e}\n")
		sys.exit(1)


# Get arguments after the script name
args = sys.argv[1:]

# If --libs is not requested, just passthrough to real pkg-config
if ("--libs" not in args):  # Optional: also handle --cflags if needed
	os.execvp("pkg-config", ["pkg-config"] + args)

# Run pkg-config to get the raw flags
raw = run_pkg_config(args)

if not raw:
	print("")
	sys.exit(0)

tokens = shlex.split(raw)

# Collect -L dirs and -l libs
lib_dirs = [t[2:] for t in tokens if t.startswith("-L")]
libs = [t[2:] for t in tokens if t.startswith("-l")]

# Start building output: keep everything initially
out_tokens = list(tokens)

# Track which -L dirs are still needed
used_dirs = set()

for lib in libs:
	found_static = False
	for dir_path in lib_dirs:
		static_path = os.path.join(dir_path, f"lib{lib}.a")
		if os.path.isfile(static_path):
			# Replace all occurrences of -l<lib> with the force_load
			out_tokens = [t for t in out_tokens if t != f"-l{lib}"]
			out_tokens.append(f"-Wl,-force_load,{static_path}")
			used_dirs.add(dir_path)
			found_static = True
			break  # Only replace with the first found static lib

	if not found_static:
		# Keep dynamic if no static found
		used_dirs.update(lib_dirs)  # Conservative: keep all if any dynamic

# Optional: Remove -L dirs that are no longer needed (if all libs in them were static)
# But to be safe, we keep all -L that were originally provided
# If you want to prune unused -L, uncomment below:
# out_tokens = [t for t in out_tokens if not (t.startswith("-L") and t[2:] not in used_dirs)]

# Output the modified flags
print(" ".join(out_tokens))
