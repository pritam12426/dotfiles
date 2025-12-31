#!/usr/bin/env bash

NNN_GIT_RIPO="$HOME/Developer/git_repository/online/nnn"
PATCHS_DIR="$DOT_FILE/config/nnn/patchs"

if [[ -d "$NNN_GIT_RIPO" ]]; then
	git clone "git@github.com:jarun/nnn.git"
	sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"
fi

function git_apply_patch() {
	command ...
}


git_apply_patch "$PATCHS_DIR/"
