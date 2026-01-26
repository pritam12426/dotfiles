CC =  /usr/bin/clang++ -std=c++20

LDFLAGS  := -arch arm64
CFLAGS   := -MMD -MP

LIB  = libcjson
PKG_CONFIG_CFLAGS = $(shell pkg-config --cflags ${LIB})
PKG_CONFIG_LIBS   = $(shell pkg-config --libs ${LIB})

CFLAGS   += $(PKG_CONFIG_CFLAGS)
LDFLAGS  += $(PKG_CONFIG_LIBS) -Wl,-rpath,/usr/local/big_library/cJSON-1.7.18/lib

PROJDIRS := .
OBJDIR   := $(PROJDIRS)/obj
TIME     := /usr/bin/time -h

SRCFILES    := $(wildcard ${PROJDIRS}/src/*.cpp)
HEADERFILES := $(wildcard ${PROJDIRS}/src/*.hpp)
OBJFILES    := $(patsubst ${PROJDIRS}/src/%.cpp, ${OBJDIR}/%.o, $(SRCFILES))
DEPFILES    := $(patsubst ${PROJDIRS}/src/%.cpp, ${OBJDIR}/%.d, $(SRCFILES))

PROJNAME     := MyProject
BIN          := ${PROJDIRS}/main.out
LINE         := @printf '%*s\n' $(shell tput cols) ' ' | tr ' ' '-' >&2
OUTPUT_FILE  := ${PROJDIRS}/output.txt
INPUT_FILE   := ${PROJDIRS}/input.txt

ifdef d
	CFLAGS += -g3 -O0
else
	CFLAGS += -O3
endif

all: build run

debug:
debug: build

build: ${BIN}

.PHONY: all debug build clean run

$(BIN): $(OBJFILES)
	@printf "\e[1;32m 🗜️  %s \e[0m \e[41m%s\e[0m\n\n" "Building the project..." "$(OBJFILES)"
	$(TIME) $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $(BIN)
	@strip $(BIN)
	$(LINE)

${OBJDIR}:
	@mkdir -p $@

${OBJDIR}/%.o: ${PROJDIRS}/src/%.cpp | ${OBJDIR}
	@printf "\e[1;34m 🛠️  %s \e[0m \e[45m%s\e[0m\n\n" "Compiling" "$<"
	$(TIME) $(CC) $(CFLAGS) -c $< -o $@
	${LINE}

# Debug build
d: dd
	lldb -o "command alias rr process launch --stdin $(INPUT_FILE) --stdout $(OUTPUT_FILE)" -o "b main" -o "rr" $(BIN)

dd: ${OBJFILES}
	@printf "\e[1;33m 🐞  %s \e[0m \e[44m%s\e[0m\n\n" "Debugging" "$<"
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $(BIN)
	${LINE}

clean:
	$(RM) -r ${PROJDIRS}/*.out ${PROJDIRS}/*.dSYM ${OBJDIR}

r:
	$(TIME) $(BIN) < $(INPUT_FILE) > $(OUTPUT_FILE)

run:
	$(TIME) $(BIN)

-include ${DEPFILES}
