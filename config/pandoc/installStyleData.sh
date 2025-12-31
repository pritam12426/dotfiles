#!/bin/bash

OUTPUT_DIR="$HOME/.config/pandoc/"
cd "$OUTPUT_DIR" || exit 1

download_and_log() {
	local cmd="$1"
	local message="$2"

	echo -e "\033[1;36m==> \033[1;33m$message\033[1;36m <==\033[0m"
	if ! eval "$cmd"; then
		echo -e "\033[1;31mFailed: $cmd\033[0m"
		return 1
	fi
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
}

# Use an indexed array with pairs: command, message, command, message...
downloads=(
	"Making dir partials/markdown"         "mkdir -p partials/markdown"

	"Pulling: partials/markdown/github-markdown-light.css"    "wget -q --show-progress -c 'https://raw.githubusercontent.com/sindresorhus/github-markdown-css/refs/heads/main/github-markdown-light.css'  -O partials/markdown/github-markdown-light.css"
	"Pulling: partials/markdown/github-markdown-dark.css"     "wget -q --show-progress -c 'https://raw.githubusercontent.com/sindresorhus/github-markdown-css/refs/heads/main/github-markdown-dark.css'   -O partials/markdown/github-markdown-dark.css"
	"Pulling: partials/markdown/github-markdown.css"          "wget -q --show-progress -c 'https://raw.githubusercontent.com/sindresorhus/github-markdown-css/refs/heads/main/github-markdown.css'        -O partials/markdown/github-markdown.css"

	"Pulling: partials/markdown/mdTohtml-footer.html"     "wget -q --show-progress -c 'https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/footer.html'                          -O partials/markdown/mdTohtml-footer.html"
	"Pulling: partials/markdown/mdTohtml-header.html"     "wget -q --show-progress -c 'https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/header.html'                          -O partials/markdown/mdTohtml-header.html"
	"Pulling: partials/markdown/mdTohtml-navbar.html"     "wget -q --show-progress -c 'https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/navbar.html'                          -O partials/markdown/mdTohtml-navbar.html"
	"Pulling: partials/markdown/mdTohtml-styles.css"      "wget -q --show-progress -c 'https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/styles.css'                           -O partials/markdown/mdTohtml-styles.css"

	"Making dir templates/markdown"        "mkdir -p templates/markdown"
	"Pulling: templates/markdown/mdTohtmltemplate.html"   "wget -q --show-progress -c 'https://raw.githubusercontent.com/ashki23/pandoc-bootstrap/refs/heads/master/template.html'                        -O templates/markdown/readmeToHTML-template.html"

	"Pulling: templates/markdown/markdown-latex-eisvogel-added.latex"          "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel-added.latex' -O templates/markdown/markdown-latex-eisvogel-added.latex"

	"Pulling: templates/after-header-includes.latex"   "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/after-header-includes.latex' -O ~/.local/share/pandoc/templates/after-header-includes.latex"
	"Pulling: templates/common.latex"                  "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/common.latex' -O ~/.local/share/pandoc/templates/common.latex"
	"Pulling: templates/eisvogel-title-page.latex"     "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel-title-page.latex' -O ~/.local/share/pandoc/templates/eisvogel-title-page.latex"
	"Pulling: templates/eisvogel.beamer"               "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel.beamer' -O ~/.local/share/pandoc/templates/eisvogel.beamer"
	"Pulling: templates/eisvogel.latex"                "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel.latex' -O ~/.local/share/pandoc/templates/eisvogel.latex"
	"Pulling: templates/font-settings.latex"           "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/font-settings.latex' -O ~/.local/share/pandoc/templates/font-settings.latex"
	"Pulling: templates/fonts.latex"                   "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/fonts.latex' -O ~/.local/share/pandoc/templates/fonts.latex"
	"Pulling: templates/hypersetup.latex"              "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/hypersetup.latex' -O ~/.local/share/pandoc/templates/hypersetup.latex"
	"Pulling: templates/passoptions.latex"             "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/passoptions.latex' -O ~/.local/share/pandoc/templates/passoptions.latex"
	"Pulling: templates/eisvogel-added.latex"          "wget -q --show-progress -c 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/refs/heads/master/template-multi-file/eisvogel-added.latex' -O ~/.local/share/pandoc/templates/eisvogel-added.latex"

)

# Loop through array in pairs
for ((i = 0; i < ${#downloads[@]}; i += 2)); do
	download_and_log "${downloads[i + 1]}" "${downloads[i]}" || exit 1
done
