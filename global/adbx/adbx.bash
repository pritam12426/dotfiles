#!/usr/bin/env -S bash
set -euo pipefail


# TODO:
# 	check how to recored call recording with persons mic on if not possible then install spyware

# ---------------- Config ----------------
ADB=(adb)
SCRCPY_BASE=(scrcpy --legacy-paste --print-fps)
OPT=(--no-control --max-fps=24)
CAM_OPT=(--video-source=camera --no-audio-playback)

PORT=5555

# ---------------- Runtime Info values ----------------
MODEL="$("${ADB[@]}" shell getprop ro.product.model | tr ' ' '_')"
BATTERY="$("${ADB[@]}" shell dumpsys battery | grep 'level' | awk '{print $2}')"
SIZE="$("${ADB[@]}" shell wm size | awk '{print $3}')"
ANDROID_V="$("${ADB[@]}" shell getprop ro.build.version.release)"
IPV4="$("${ADB[@]}" shell ip route | awk 'NF>=9{print $9}' | tail -n1)"

DIR="${HOME}/Movies/phone_screen/${MODEL}"
FILE="$(date +"%Y-%b-%d_%I.%M.%S_%p")"
FILE_PATH="${DIR}/${MODEL}_android-v${ANDROID_V}-${FILE}"

LINE() {
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '='
}

print_info() {
	printf "Battery Level    %s\n" "$BATTERY"
	printf "Screen Size      %s\n" "$SIZE"
	LINE
}

mkdir -vp "$DIR"

# ---------------- Commands ----------------

case "${1:-}" in
cr)
	print_info
	cmd=("${SCRCPY_BASE[@]}" "${OPT[@]}")
	cmd+=(-r "${FILE_PATH}.mp4")
	"${cmd[@]}"
	;;
r | record )
	print_info
	cmd=("${SCRCPY_BASE[@]}" "${OPT[@]}")
	cmd+=(--no-window -r "${FILE_PATH}.mp4")
	"${cmd[@]}"
	;;
t | test)
	print_info
	"${SCRCPY_BASE[@]}"
	;;
use)
	cmd=("${SCRCPY_BASE[@]}")
	cmd+=(--turn-screen-off --disable-screensaver --power-off-on-close)
	cmd+=(-r "${FILE_PATH}_checking.mp4")
	"${cmd[@]}"
	;;
ss | screensort)
	# print_info
	"${ADB[@]}" exec-out screencap -p > "${FILE_PATH}_screenshot.png"
	qlmanage -p "${FILE_PATH}_screenshot.png"
	;;
mount | config)
	echo "Phone IPV4: $IPV4"
	"${ADB[@]}" tcpip "$PORT"
	"${ADB[@]}" connect "${IPV4}:${PORT}"
	;;
clean)
	find "$DIR" -type f -size -1M -name "*.mp4" -delete
	;;
fcam | frountCam)
	cmd=("${SCRCPY_BASE[@]}" "${CAM_OPT[@]}")
	cmd+=(--camera-facing=front)
	cmd+=(-r "${FILE_PATH}_front-cam.mp4")
	"${cmd[@]}"
	;;
bcam | backCam)
	cmd=("${SCRCPY_BASE[@]}" "${CAM_OPT[@]}")
	cmd+=(--capture-orientation=90 --camera-facing=back)
	cmd+=(-r "${FILE_PATH}_back-cam.mp4")
	"${cmd[@]}"
	;;
kill)
	"${ADB[@]}" kill-server
	;;
cc)
	cmd=("${SCRCPY_BASE[@]}")
	cmd+=(--audio-source=mic --no-audio-playback)
	cmd+=(-r "${FILE_PATH}.mp4")
	"${cmd[@]}"
	;;
ccn)
	cmd=("${SCRCPY_BASE[@]}")
	cmd+=(--no-window --audio-source=mic --no-audio-playback)
	cmd+=(-r "${FILE_PATH}.mp4")
	"${cmd[@]}"
	;;
ci)
	cmd=("${SCRCPY_BASE[@]}")
	cmd+=(--audio-source=mic --no-video --no-playback --no-window --no-control)
	cmd+=(--record="${FILE_PATH}_audio.opus")
	"${cmd[@]}"
	;;
info)
	exec "$DOT_FILE/../global/adbx/phone"
	;;
*)
	echo "Usage: adbx [ cr | r | t | use | ss | config | clean | fcam | bcam | cc | ccn | ci | kill | ii ]"
	exit 1
	;;
esac
