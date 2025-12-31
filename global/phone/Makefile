# --turn-screen-off --lock-video-orientation
# To turn the device screen off when closing
# --power-off-on-close
# By default, on start, the device is powered on.
# --no-power-on              scrcpy --show-touches
# --stay-awake   do not go to sleep

export SCRCPY     = scrcpy --legacy-paste --print-fps
export ADB        = adb
export OPT        = --no-control --max-fps=60
# export CAM_OPT    = --video-source=camera --no-audio-playback --capture-orientation 270
export CAM_OPT    =  --video-source=camera --no-audio-playback

export MODEL     := $(shell adb shell getprop ro.product.model | tr ' ' '_')
export SIZE       = $(shell adb shell dumpsys battery | grep 'level' | awk '{print $$2}')
export BATTERY    = $(shell adb shell wm size | awk '{print $$3}')
export ANDROID_V := $(shell adb shell getprop ro.build.version.release)
export IPV4      := $(shell adb shell ip route | awk ' NF >= 9 { print $$9 } ' | tail -n 1)

DIR        = ${HOME}/Movies/phone_screen/${MODEL}
# export DIR        = ./${MODEL}
export FILE      := $(shell date +"%Y-%b-%d %I.%M.%S %p")
export FILE_PATH  = ${DIR}/${MODEL}_android-v${ANDROID_V}–${FILE}
export PORT       = 5555

# List files less than 1MB
export DELETE_FILES = find ${DIR}/* -type f -size -1M -name "*.mp4"
export DELETE       = $(DELETE_FILES); $(DELETE_FILES) -delete
export LINE         = @printf '%*s\n' $(shell tput cols) ' ' | tr ' ' '-' >&2


# 1 System - audio with screen
# 2 only audio
# 3 back cam
# 4 frount cam

# point to be noted that: there is high changes that the duration of the video
# and audios of four of them are not relevant to each other for the size.
# You can make it, but for the video duration it is not possible.
# You have to consider this point also.

all: t

# adb shell ip route | awk '{print $9}'

# Record screen {with no system sould - mic} with at phone --- withperview
cr:
	mkdir -p ${DIR}
	@printf "Battery Level    %s\n" "${BATTERY}"
	@printf "Screen Size      %s\n" "${SIZE}"
	${LINE}
	${SCRCPY} ${OPT} -r "${FILE_PATH}.mp4"


# Record screen {with system sould} with no-play-sound at phone   ---   without perview
r:
	mkdir -p ${DIR}
	@printf "Battery Level    %s\n" "${BATTERY}"
	@printf "Screen Size      %s\n" "${SIZE}"
	${LINE}
	${SCRCPY} ${OPT} --no-window -r "${FILE_PATH}.mp4"

# Test
t:
	@printf "Battery Level    %s\n" "${BATTERY}"
	@printf "Screen Size      %s\n" "${SIZE}"
	${LINE}
	${SCRCPY}

# Use phone with phone screen off
use:
	${SCRCPY} --turn-screen-off --disable-screensaver --power-off-on-close -r "${FILE_PATH}_checking.mp4"


# Take screenshot
ss:
	@printf "Battery Level    %s\n" "${BATTERY}"
	@printf "Screen Size      %s\n" "${SIZE}"
	${LINE}
	${ADB} exec-out screencap -p > "${FILE_PATH}_screenshot.png"
	qlmanage -p "${FILE_PATH}_screenshot.png"

# connect to phone with wifi
config:
	@echo "Phone's IPV4 ${IPV4}"
	${ADB} tcpip ${PORT}
	${ADB} connect ${IPV4}:${PORT}

clean:
	${DELETE}

# Record fount cam --- with perview
fcam:
	${SCRCPY} $(CAM_OPT) --camera-facing=front -r "${FILE_PATH}_front-cam.mp4"

# Record back cam and --- with perview
bcam:
	${SCRCPY} $(CAM_OPT)  --capture-orientation 90 --camera-facing=back -r "${FILE_PATH}_back-cam.mp4"

# Kill adb server
kill:
	${ADB} kill-server

# Record Screen with mic --- with perview
cc:
	${SCRCPY} --audio-source=mic -r "${FILE_PATH}.mp4" --no-audio-playback

# Record Screen with mic --- without perview
ccn:
	${SCRCPY} --no-window  --audio-source=mic -r "${FILE_PATH}.mp4" --no-audio-playback

# Record only audio --- without perview
ci:
	${SCRCPY} --audio-source=mic --no-video --no-playback --no-window --no-control --record="${FILE_PATH}_audio.opus"

# Fetch phone info: https://help.famoco.com/developers/dev-env/adb-commands/
ii:
	@./phone

# compile:
# 	ffmpeg -i /Users/pritam/temp/vdo1.mp4 -i /Users/pritam/temp/vdo1.mp4 -filter_complex "[0:v][1:v]hstack=inputs=2[v]" -map "[v]" -an -f matroska new.mp4
