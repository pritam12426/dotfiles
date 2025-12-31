# ==============================================
# Arduino Makefile using arduino-cli
# ==============================================

# Tools & Config
ARDUINO_CLI := arduino-cli -v
BUILD_DIR   ?= build-uno
BOARD_TYPE  := arduino:avr:uno
SKETCH      := $(shell basename $$(pwd)).ino
PYTHON      := python3
FILTER_SCRIPT := .zed/filter-compile-commands.py

# Auto-detect port (macOS)
ifeq ($(BOARD_PORT),)
	BOARD_PORT := $(shell ls /dev/cu.usb* 2>/dev/null | head -1)
endif

# Default target
.PHONY: all init compile upload clean verify monitor

# ------------------------------------------------
# 1. Default: generate compile_commands.json + filter
# ------------------------------------------------
all: init

# ------------------------------------------------
# 2. Generate compile_commands.json
# ------------------------------------------------
init:
	@echo "=== Generating compile_commands.json ==="
	$(ARDUINO_CLI) compile \
		--only-compilation-database \
		--build-path $(BUILD_DIR) \
		-b $(BOARD_TYPE) \
		-v

# ------------------------------------------------
# 3. Filter for clangd (runs your Python script)
# ------------------------------------------------
m: init
	@echo "=== Filtering compile_commands.json for clangd ==="
	$(PYTHON) $(FILTER_SCRIPT)
	@echo "Filtered: $(BUILD_DIR)/compile_commands_clangd.json"
	@echo "Symlink created → $(BUILD_DIR)/compile_commands.json"
	@ln -sf compile_commands_clangd.json $(BUILD_DIR)/compile_commands.json || true

# ------------------------------------------------
# 4. Full compile (binary + size)
# ------------------------------------------------
compile: init
	@echo "=== Compiling sketch ==="
	$(ARDUINO_CLI) compile \
		--build-path $(BUILD_DIR) \
		-b $(BOARD_TYPE) \
		--build-cache-path $(BUILD_DIR)/cache \
		-v

# ------------------------------------------------
# 5. Upload to board
# ------------------------------------------------
upload: compile
	@echo "=== Uploading to board ==="
	@if [ "$(BOARD_PORT)" = "" ]; then \
		echo "Error: BOARD_PORT not set. Use make upload BOARD_PORT=/dev/ttyACM0"; \
		exit 1; \
	fi
	$(ARDUINO_CLI) upload \
		-p $(BOARD_PORT) \
		-b $(BOARD_TYPE) \
		--input-dir $(BUILD_DIR) \
		-v

# ------------------------------------------------
# 6. Verify (compile only, no upload)
# ------------------------------------------------
verify: compile
	@echo "Build successful!"

# ------------------------------------------------
# 7. Clean build directory
# ------------------------------------------------
clean:
	@echo "=== Cleaning build directory ==="
	rm -rf $(BUILD_DIR)

# ------------------------------------------------
# 8. Monitor serial output
# ------------------------------------------------
monitor:
	@echo "=== Opening serial monitor (Ctrl+A, K to quit) ==="
	$(ARDUINO_CLI) monitor -p $(BOARD_PORT) -c baudrate=115200

# ------------------------------------------------
# 9. Help
# ------------------------------------------------
help:
	@echo "Available targets:"
	@echo "  make          → generate + filter compile_commands.json"
	@echo "  make m        → same as 'make' (your alias)"
	@echo "  make compile  → build .hex"
	@echo "  make upload BOARD_PORT=/dev/ttyXXX"
	@echo "  make clean"
	@echo "  make monitor BOARD_PORT=/dev/ttyXXX"
