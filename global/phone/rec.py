#!/usr/bin/python3

import argparse
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

HOME = Path.home()
PORT = 5555
NOW = datetime.now().strftime("%Y-%b-%d_at_%I.%M.%S-%p")
COMMAND = ["scrcpy"]


def run(cmd, capture=False):
	if capture:
		return subprocess.check_output(cmd, shell=True, text=True).strip()
	subprocess.run(cmd, shell=True)


def get_device_info():
	model = run("adb shell getprop ro.product.model | tr ' ' '_'", capture=True)
	size = run(
		"adb shell dumpsys battery | grep 'level' | awk '{print $2}'", capture=True
	)
	battery = run("adb shell wm size | awk '{print $3}'", capture=True)
	android_v = run("adb shell getprop ro.build.version.release", capture=True)
	ipv4 = run(
		"adb shell ip route | awk 'NF >= 9 { print $9 }' | tail -n 1", capture=True
	)
	return model, size, battery, android_v, ipv4


def line():
	print("-" * shutil.get_terminal_size().columns)


def print_info(size, battery):
	print(f"Battery Level    {battery}")
	print(f"Screen Size      {size}")
	line()


def prompt_yes_no(question, default="yes"):
	valid = {"yes": True, "y": True, "no": False, "n": False}
	if default is None:
		prompt = " [y/n] "
	elif default == "yes":
		prompt = " [Y/n] "
	elif default == "no":
		prompt = " [y/N] "
	else:
		raise ValueError("invalid default answer: '%s'" % default)

	while True:
		print(question + prompt, end="")
		choice = input().lower()
		if default is not None and choice == "":
			return valid[default]
		elif choice in valid:
			return valid[choice]
		else:
			print("Please respond with 'yes' or 'no' (or 'y' or 'n').")


def get_recording_source():
	while True:
		print("\nWhat do you want to record?")
		print("1. Screen (s)")
		print("2. Camera (c)")
		choice = input("Enter your choice [s/c]: ").lower()
		if choice in ["s", "screen"]:
			return "screen"
		elif choice in ["c", "camera"]:
			return "camera"
		print("Invalid choice. Please try again.")


def get_camera_side():
	while True:
		print("\nWhich camera do you want to record?")
		print("1. Back camera (b)")
		print("2. Front camera (f)")
		choice = input("Enter your choice [b/f]: ").lower()
		if choice in ["b", "back"]:
			return "back"
		elif choice in ["f", "front"]:
			return "front"
		print("Invalid choice. Please try again.")


def get_audio_source():
	while True:
		print("\nSelect audio source:")
		print("1. Microphone (m)")
		print("2. System audio (s)")
		print("3. No audio (n)")
		choice = input("Enter your choice [m/s/n]: ").lower()
		if choice in ["m", "mic"]:
			return "mic"
		elif choice in ["s", "system"]:
			return "internal"
		elif choice in ["n", "none"]:
			return None
		print("Invalid choice. Please try again.")


def main():
	parser = argparse.ArgumentParser(description="Phone Screen Tool with scrcpy + adb")

	# Primary mode selection
	parser.add_argument(
		"-r",
		"--record",
		action="store_true",
		help="Record screen or camera (interactive mode)",
	)

	# Direct recording options (for non-interactive use)
	parser.add_argument(
		"-s",
		"--screen",
		action="store_true",
		help="Record screen directly (non-interactive)",
	)
	parser.add_argument(
		"-c",
		"--camera",
		choices=["back", "front"],
		help="Record camera directly (non-interactive)",
	)

	# Additional options
	parser.add_argument(
		"-nd", "--no-display", action="store_true", help="No display (headless)"
	)
	parser.add_argument(
		"-a",
		"--audio",
		choices=["mic", "system", "none"],
		help="Audio source (mic/system/none)",
	)

	args = parser.parse_args()

	# Get device info
	model, size, battery, android_v, ipv4 = get_device_info()
	dir_path = HOME / "Movies" / "phone_screen" / model
	dir_path.mkdir(parents=True, exist_ok=True)
	file_path = dir_path / f"{model}_android-{android_v}_{NOW}"

	print_info(size, battery)

	# Interactive mode for recording
	if args.record:
		source = get_recording_source()

		if source == "screen":
			COMMAND.extend(["-r", f"{file_path}_screen.mp4"])
			audio = get_audio_source()
			if audio:
				COMMAND.extend([f"--audio-source={audio}", "--no-audio-playback"])

		elif source == "camera":
			camera_side = get_camera_side()
			if camera_side == "back":
				COMMAND.extend(
					[
						"--video-source=camera",
						"--camera-facing=back",
						"-r",
						f"{file_path}_back-cam.mp4",
					]
				)
			else:
				COMMAND.extend(
					[
						"--video-source=camera",
						"--camera-facing=front",
						"-r",
						f"{file_path}_front-cam.mp4",
					]
				)

	# Non-interactive mode
	else:
		if args.screen:
			COMMAND.extend(["-r", f"{file_path}_screen.mp4"])
		elif args.camera:
			if args.camera == "back":
				COMMAND.extend(
					[
						"--video-source=camera",
						"--camera-facing=back",
						"-r",
						f"{file_path}_back-cam.mp4",
					]
				)
			else:
				COMMAND.extend(
					[
						"--video-source=camera",
						"--camera-facing=front",
						"-r",
						f"{file_path}_front-cam.mp4",
					]
				)

	# Handle audio in non-interactive mode
	if args.audio and args.audio != "none":
		COMMAND.extend([f"--audio-source={args.audio}", "--no-audio-playback"])

	# Handle no-display option
	if args.no_display or prompt_yes_no("Run in headless mode (no display)?"):
		COMMAND.append("--no-window")

	print(f"\nRunning: {' '.join(COMMAND)}")
	subprocess.run(COMMAND)


if __name__ == "__main__":
	main()
