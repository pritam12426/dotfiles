# Makefile — pushfile build system
#
# Targets:
#   all     — release build (-O3)
#   debug   — debug build (-g3 -DDEBUG)
#   strip   — strip debug symbols
#   install — install to PREFIX
#   uninstall
#   clean
#
# Options (set via environment or on the command line):
#   make debug -B O_DEBUG=1  — debug build
#
# macOS prerequisite: brew install argp-standalone

UNAME_S := $(shell uname -s)

PREFIX ?= /usr/local

STRIP ?= strip
PKG_CONFIG ?= pkg-config
INSTALL ?= install

CFLAGS_OPTIMIZATION ?= -O3

BUILD     = build
BIN       = pushfile

HEADERS   = $(wildcard src/*.h)
SRC       = $(wildcard src/*.c)

CFLAGS += -Isrc -std=c17 -DCOMPILED_TIME_PREFIX='"$(PREFIX)"'
# Compiler warnings
CFLAGS +=  -Wall -Wextra -Wpedantic \
           -Wstrict-prototypes -Wmissing-prototypes \
           -Wshadow -Wconversion \
           -Wno-missing-field-initializers

# Common flags
CFLAGS += -Isrc -std=c17
LDLIBS += -lpthread

# Convert targets to flags for backwards compatibility
O_DEBUG := 0  # Debug binary (0 = release, 1 = debug)

ifneq ($(filter debug,$(MAKECMDGOALS)),)
	O_DEBUG := 1
endif

ifeq ($(strip $(O_DEBUG)),1)
	CFLAGS += -g3 -DDEBUG -DLOG_SHOW_SOURCE_LOCATION

	LDFLAGS += -fsanitize=address -fsanitize=undefined
	CFLAGS += -fstack-usage \
	          -fsanitize=address \
	          -fsanitize=undefined

    ifneq (,$(findstring clang,$(CC)))
		CFLAGS += -ffreestanding
    endif
else
	CFLAGS += $(CFLAGS_OPTIMIZATION)
endif

# Platform-specific settings
ifeq ($(UNAME_S),Darwin)
	# macOS: need argp from Homebrew (brew install argp-standalone)
	LDLIBS += -largp
else
	# Linux: _GNU_SOURCE for strptime, etc.
	CFLAGS += -D_GNU_SOURCE
endif

OUT += $(SRC:%.c=$(BUILD)/%.o)

all: $(BIN)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%-20s\033[0m %s\n", $$1, $$2}'

$(BUILD): ## Create build directories automatically
	mkdir -p $(BUILD)

$(BUILD)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN): $(OUT) ## Build the pushfile binary
	$(CC) $(LDFLAGS) -o $@ $(OUT) $(LDLIBS)

debug: $(BIN) ## Build the debug binary run `make debug -B O_DEBUG=1`

install: all ## Install the pushfile binary
	$(INSTALL) -m 0755 -d $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -m 0755 $(BIN) $(DESTDIR)$(PREFIX)/bin

clean: ## Clean up build artifacts
	$(RM) -rf $(OUT) $(BIN)

uninstall: ## Uninstall the pushfile binary
	$(RM) $(DESTDIR)$(PREFIX)/bin/$(BIN)

strip: $(BIN) ## Strip the pushfile binary
	$(STRIP) $^

.PHONY: all install uninstall strip clean debug
