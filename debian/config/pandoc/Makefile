OUTPUT_DIR="${HOME}/.config/pandoc/"
LINK_TARGET="${HOME}/.local/share/pandoc"
WGET = wget -q --show-progress --progress=bar:force:noscroll -c -O

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%-20s\033[0m %s\n", $$1, $$2}'

partials/markdown: ## Create partials/markdown directory
	@mkdir -p $@

templates/markdown: ## Create templates/markdown directory
	mkdir -p $@

partials/markdown/github-markdown-light.css: partials/markdown ## Download GitHub Markdown light CSS
	$(WGET) $@ https://raw.githubusercontent.com/sindresorhus/github-markdown-css/refs/heads/main/github-markdown-light.css

partials/markdown/github-markdown-dark.css: partials/markdown ## Download GitHub Markdown dark CSS
	$(WGET) $@ https://raw.githubusercontent.com/sindresorhus/github-markdown-css/refs/heads/main/github-markdown-dark.css

partials/markdown/github-markdown.css: partials/markdown ## Download GitHub Markdown CSS
	$(WGET) $@ https://raw.githubusercontent.com/sindresorhus/github-markdown-css/refs/heads/main/github-markdown.css

partials/markdown/mdTohtml-footer.html: partials/markdown ## Download mdTohtml footer
	$(WGET) $@ https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/footer.html

partials/markdown/mdTohtml-header.html: partials/markdown ## Download mdTohtml header
	$(WGET) $@ https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/header.html

partials/markdown/mdTohtml-navbar.html: partials/markdown ## Download mdTohtml navbar
	$(WGET) $@ https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/navbar.html

partials/markdown/mdTohtml-styles.css: partials/markdown ## Download mdTohtml styles CSS
	$(WGET) $@ https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/styles.css

templates/markdown/readmeToHTML-template.html: templates/markdown ## Download mdTohtml template
	$(WGET) $@ https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/template.html

templates/markdown/markdown-latex-eisvogel-added.latex: templates/markdown ## Download markdown-latex-eisvogel-added template
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel-added.latex

$(LINK_TARGET)/templates: ## Create pandoc share templates directory
	mkdir -p $@

$(LINK_TARGET)/templates/after-header-includes.latex: $(LINK_TARGET)/templates ## Download after-header-includes.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/after-header-includes.latex

$(LINK_TARGET)/templates/common.latex: $(LINK_TARGET)/templates ## Download common.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/common.latex

$(LINK_TARGET)/templates/eisvogel-title-page.latex: $(LINK_TARGET)/templates ## Download eisvogel-title-page.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel-title-page.latex

$(LINK_TARGET)/templates/eisvogel.beamer: $(LINK_TARGET)/templates ## Download eisvogel.beamer
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel.beamer

$(LINK_TARGET)/templates/eisvogel.latex: $(LINK_TARGET)/templates ## Download eisvogel.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel.latex

$(LINK_TARGET)/templates/font-settings.latex: $(LINK_TARGET)/templates ## Download font-settings.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/font-settings.latex

$(LINK_TARGET)/templates/fonts.latex: $(LINK_TARGET)/templates ## Download fonts.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/fonts.latex

$(LINK_TARGET)/templates/hypersetup.latex: $(LINK_TARGET)/templates ## Download hypersetup.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/hypersetup.latex

$(LINK_TARGET)/templates/passoptions.latex: $(LINK_TARGET)/templates ## Download passoptions.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/passoptions.latex

$(LINK_TARGET)/templates/eisvogel-added.latex: $(LINK_TARGET)/templates ## Download eisvogel-added.latex
	$(WGET) $@ https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel-added.latex

all: partials/markdown templates/markdown $(LINK_TARGET)/templates \
     partials/markdown/github-markdown-light.css \
     partials/markdown/github-markdown-dark.css \
     partials/markdown/github-markdown.css \
     partials/markdown/mdTohtml-footer.html \
     partials/markdown/mdTohtml-header.html \
     partials/markdown/mdTohtml-navbar.html \
     partials/markdown/mdTohtml-styles.css \
     templates/markdown/readmeToHTML-template.html \
     templates/markdown/markdown-latex-eisvogel-added.latex ## Download all Pandoc styles and templates

.PHONY: help all
