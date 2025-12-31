# Embedded Dev - ENV ======================================

# Pico ===============================================================================================
PICO_SDK_PATH="$HOME/.local/dev-tools/pico/pico-sdk"                      # Path to the PICO SDK directory
TOOLCHAIN_PATH="$HOME/.local/dev-tools/arm-gnu-toolchain-14.3/bin"        # Path to the ARM GNU Toolchain binaries
FREERTOS_KERNEL_PATH="$HOME/.local/dev-tools/pico/FreeRTOS-KernelV11.2.0" # Path to the FreeRTOS Kernel directory
PICO_TOOL="/usr/local/big_library/picotool-2.1.1/bin"                     # Path to the PicoTool binaries

# Check if the PICO SDK path exists
if [[ -d $PICO_SDK_PATH ]]; then
	echo "PICO SDK path found at: $PICO_SDK_PATH"
	export PICO_SDK_PATH # Export the PICO SDK path as an environment variable

	# Check if the PicoTool binary exists and is executable
	if [[ -x "$PICO_TOOL/picotool" ]]; then
		echo "PicoTool path set to: $PICO_TOOL"
		export PATH="$PICO_TOOL:$PATH" # Add PicoTool to the system PATH
	else
		echo "Warning: PicoTool not found or not executable at: $PICO_TOOL"
	fi

	# Check if the ARM GNU Toolchain path exists
	if [[ -d $TOOLCHAIN_PATH ]]; then
		echo "ARM GNU Toolchain found at: $TOOLCHAIN_PATH"
		export PATH="$TOOLCHAIN_PATH:$PATH" # Add ARM GNU Toolchain to the system PATH

		unset CC
		echo "Unset CC environment variable"

		unset CXX
		echo "Unset CXX environment variable"
	else
		echo "Warning: ARM GNU Toolchain not found at: $TOOLCHAIN_PATH"
	fi

	# Check if the FreeRTOS Kernel path exists
	if [[ -d $FREERTOS_KERNEL_PATH ]]; then
		echo "FreeRTOS Kernel path set to: $FREERTOS_KERNEL_PATH"
	else
		echo "Warning: FreeRTOS Kernel not found at: $FREERTOS_KERNEL_PATH"
	fi
else
	# Exit with an error if the PICO SDK path is not found
	echo "Error: PICO SDK path not found at: $PICO_SDK_PATH"
fi

# ===============================================================================================


# Arduino =======================================================================================
ARDUINO_HOME="$HOME/Library/Arduino15"

if ! command -v arduino-ci &> /dev/null; then
	echo "INFO: arduino-cli is not installed. Please install it from    bin install 'https://github.com/arduino/arduino-cli'"
fi

# Find all "bin" directories under the ARDUINO_HOME path
if [[ -d $ARDUINO_HOME ]]; then
	find "$ARDUINO_HOME" -type d -name "bin" | while read -r bin_dir; do
		echo "Adding Arduino bin directory to PATH: $bin_dir"
		export PATH="$bin_dir:$PATH"
	done
else
	echo "Warning: ARDUINO_HOME directory does not exist, skipping bin directory search."
fi
# ===============================================================================================
