#!/usr/bin/env python3

# from pathlib import Path
# import sys
from shutil import copyfile
import json

# List of flags to REMOVE for clangd (AVR-specific or problematic)
REMOVE_FLAGS = [
	"-mmcu=atmega328p",
	# "-DF_CPU=16000000L",
	# "-DARDUINO=10607",
	# "-DARDUINO_AVR_UNO",
	# "-DARDUINO_ARCH_AVR",
	# "-MMD"
	# "-flto",
	# "-fno-fat-lto-objects",
	# "-Wno-error=narrowing",
	# "-fpermissive",
	# "-fno-exceptions",
	# "-ffunction-sections",
	# "-fdata-sections",
	# "-fno-threadsafe-statics",

	# Remove any -I that points to system clang headers
	# lambda x: x.startswith("-I/Applications/Xcode") or
	            # x.startswith("-I/Library/Developer") or
	            # x.startswith("-I/usr/local") or
	            # "clang" in x and "include" in x
]


def filter_command(cmd):
	return [
		arg for arg in cmd if arg not in REMOVE_FLAGS and not arg.startswith("-mmcu=")
	]


input_path = "build-uno/compile_commands.json"
output_path = "build-uno/compile_commands_clangd.json"

with open(input_path) as f:
	data = json.load(f)

for entry in data:
	if "arguments" in entry:
		entry["arguments"] = filter_command(entry["arguments"])
	elif "command" in entry:
		# If it's a single command string
		cmd = entry["command"].split()
		entry["command"] = " ".join(filter_command(cmd))

with open(output_path, "w") as f:
	json.dump(data, f, indent=1)

copyfile(output_path, input_path)

print(f"Filtered compile_commands saved to {input_path}")
