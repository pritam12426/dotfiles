OPT  ?= -pedantic -Wall -std=c++20
# OPT  += -include bits/stdc++.hpp
PDIR ?= $(HOME)/Developer/leedcode/cxx
TIME  = /usr/bin/time -h

PROGRAM_FILE = ${PDIR}/main.cpp
BIN          = ${shell echo ${PROGRAM_FILE} | tr '.' '-'}.out
LINE         = @printf '%*s\n' $(shell tput cols) ' ' | tr ' ' '-' >&2
OUTPUT_FILE  = ${PDIR}/output.txt
INPUT_FILE   = ${PDIR}/input.txt

.PHONY: all debug clean build d r run c

all: build r

debug: d
clean: c

build: ${PROGRAM_FILE}
	$(TIME) $(CXX) $(OPT) -O3 $(PROGRAM_FILE) -o $(BIN)
	${LINE}

d: ${PROGRAM_FILE}
	$(CXX) $(OPT) -g3 $(PROGRAM_FILE) -o $(BIN)
	${LINE}
	lldb -o "command alias rr process launch --stdin $(INPUT_FILE) --stdout $(OUTPUT_FILE)" -o "b main" -o "rr" $(BIN)

r:
	$(TIME) $(BIN) < $(INPUT_FILE)

run:
	$(TIME) $(BIN) < $(INPUT_FILE) > $(OUTPUT_FILE)

c:
	$(RM) -r *.out *.dSYM

.DEFAULT:
	$(TIME) $(BIN)
