TYP_CMD  := typst
TYP_OPTS := compile

TYP_SRC := $(wildcard *.typ)
TYP_OUT := $(TYP_SRC:.typ=.pdf)

D2_CMD  := d2
D2_OPTS := -b --img-cache --layout elk --theme 1 --no-xml-tag --pad 10

D2_SRC := $(wildcard assets/d2/*.d2)
D2_OUT := $(D2_SRC:.d2=.svg)

DOT_CMD  := dot
DOT_OPTS := -Tsvg

DOT_SRC := $(wildcard assets/graphviz/*.dot)
DOT_OUT := $(DOT_SRC:.dot=.svg)

all: $(D2_OUT) $(DOT_OUT) $(TYP_OUT)

assets/d2/%.svg: assets/d2/%.d2
	$(D2_CMD) $(D2_OPTS) $< $@

assets/graphviz/%.svg: assets/graphviz/%.dot
	$(DOT_CMD) $(DOT_OPTS) $< -o $@

%.pdf: %.typ
	$(TYP_CMD) $(TYP_OPTS) $< $@

clean:
	$(RM) $(TYP_OUT) $(D2_OUT) $(DOT_OUT)

.PHONY: all clean
