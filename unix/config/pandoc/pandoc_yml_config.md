Pandoc defaults files accept essentially **every command-line option**, just as YAML keys instead of flags. Here's the full field reference, organized by category:

## General

```yaml
input-files: [a.md, b.md]      # equivalent to positional args
output-file: build/main.pdf    # -o
from: markdown                 # -f / --read
to: pdf                        # -t / --write
data-dir: ~/.config/pandoc
defaults: [other-defaults.yaml]  # chain/inherit other defaults files
verbosity: INFO                # ERROR | WARNING | INFO
fail-if-warnings: true
log-file: pandoc.log
sandbox: false                 # limit filesystem access
```

## Reader options

```yaml
shift-heading-level-by: 1
indented-code-classes: [python]
default-image-extension: .png
file-scope: true               # parse multiple inputs separately
citeproc: true                 # process citations
bibliography: [refs.bib]
csl: ${.}/../csl/apa.csl
citation-abbreviations: abbrevs.json
strip-comments: false
```

## General writer options

```yaml
standalone: true               # -s
template: ${.}/../templates/latex/eisvogel.latex
variables:
  key: value
metadata:
  title: My Doc
  author: Pritam
  lang: en
metadata-files: [${.}/../metadata/common.yaml]
metadata-file: ${.}/../metadata/common.yaml   # singular also allowed
eol: lf                        # lf | crlf | native
dpi: 300
wrap: auto                     # auto | none | preserve
columns: 72
table-of-contents: true        # or `toc`
toc-depth: 3
number-sections: true
number-offset: [0,0,0]
extract-media: build/assets
resource-path: [., ${.}/assets]
include-in-header: [header.tex]
include-before-body: [before.tex]
include-after-body: [after.tex]
no-highlight: false
highlight-style: pygments
syntax-highlighting: default   # default | none | idiomatic | STYLE | FILE
top-level-division: chapter    # section | chapter | part
strip-empty-paragraphs: true
list-tables: false
```

## HTML-specific

```yaml
self-contained: false          # (deprecated, use embed-resources)
embed-resources: true
html-q-tags: false
ascii: false
reference-links: false
reference-location: block      # block | section | document
css: [${.}/../css/site.css]
email-obfuscation: none        # none | javascript | references
id-prefix: sec-
title-prefix: "My Site"
section-divs: true
email-obfuscation: javascript
split-level: 1                 # chunked HTML
chunk-template: "%s-%h.html"
epub-subdirectory: EPUB
epub-cover-image: ${.}/../assets/logo.png
epub-title-page: true
epub-metadata: meta.xml
epub-fonts: [font.ttf]
epub-chapter-level: 1
```

## PDF / LaTeX-specific

```yaml
pdf-engine: xelatex            # pdflatex | xelatex | lualatex | wkhtmltopdf | weasyprint | etc
pdf-engine-opts: ["-shell-escape"]
latex-template-dir: ...
listings: true
top-level-division: chapter
natbib: false
biblatex: false
```

## Docx / ODT / PPTX-specific

```yaml
reference-doc: ${.}/../templates/docx/reference.docx
reference-odt: reference.odt
reference-location: block
```

## Slides

```yaml
slide-level: 2
incremental: false
```

## Math rendering

```yaml
html-math-method:
  method: mathjax              # mathjax | katex | webtex | mathml | gladtex | plain
  url: https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js
```

## Filters (order matters — run top to bottom)

```yaml
filters:
  - ${.}/../filters/meta.lua
  - type: lua
    path: ${.}/../filters/pagebreak.lua
  - type: json
    path: /path/to/python-filter.py
```

## Citation / bibliography extras

```yaml
cite-method: citeproc          # citeproc | natbib | biblatex
```

## Misc / advanced

```yaml
abbreviations: abbrevs.txt
trace: false
verbose: false
quiet: false
fail-if-warnings: true
request-headers:
  - ["User-Agent", "Mozilla/5.0"]
resource-path: [".", "images"]
```

---

## A few important notes

- **Fields omitted just fall back to pandoc's normal defaults** — you never need to specify everything.
- **CLI flags override defaults file settings** — so `pandoc -d file.yaml -t html` will use HTML even if the YAML says `to: pdf`.
- **You can chain defaults files** using the `defaults:` key inside a defaults file itself, letting you build a "base" file that others inherit from.
- Some fields are only meaningful for certain output formats (e.g. `epub-*` only matters for EPUB, `reference-doc` only for docx/ODT) — pandoc silently ignores irrelevant fields rather than erroring.

For the authoritative, always-current list (since pandoc adds new options periodically), the canonical source is the **Defaults files** section of the manual: https://pandoc.org/MANUAL.html#defaults-files — every CLI flag documented in the manual has a corresponding YAML key, generally the flag name with dashes kept as-is (e.g. `--number-sections` → `number-sections`).
