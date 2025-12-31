#!/bin/zsh

[ -e "$HOME/.hushlogin" ] || touch "$HOME/.hushlogin"

# Note: definitely I am using ./config/.zsh  folder to store the configuration of ZSH but behind the scene, it is important to
# PUT sim link to ~

if [ ! -f "$HOME/.zshenv" ]; then
	echo "[ -f "\$HOME/.config/zsh/zshenv-footer.zsh" ] && source "\$HOME/.config/zsh/zshenv-footer.zsh"" >> ~/.zshenv
	source "$HOME/.zshenv"
fi

echo -e "\n"
ln -svf  "$DOT_FILE/config/zsh/zshrc.zsh"     "$HOME/.zshrc"    && source "$HOME/.zshrc"
ln -svf  "$DOT_FILE/config/zsh/zprofile.zsh"  "$HOME/.zprofile" && source "$HOME/.zprofile"

echo -e "\n"
ln -svf  "$DOT_FILE/config/git/gitconfig"     "$HOME/.gitconfig"
if [[ -n $CARGO_HOME && -d $CARGO_HOME ]]; then
	ln -svf  "$DOT_FILE/etc/cargo_config.toml"    "$CARGO_HOME"
else
	echo "⚠️  Install rust 🦀 \a"
fi

# Instal all dot file with python code
echo -e "\n"
python hooks/install_link_dot_file.py

# add link for tldr

echo -e "\n"
hooks/install_github_scrpits.sh

echo -e "\n"
hooks/dotmason/dotmason.py restore


echo -e "\n"
bin_scripts/updateNNN.sh

echo -e "\n"
config/nnn/nnn_install_plugins.sh

echo -e "\n"
echo "Install them manually \a"
echo "  etc/myProfile.terminal"
echo "  etc/sudo"
echo "  etc/sudo_su-bashrc.sh"
