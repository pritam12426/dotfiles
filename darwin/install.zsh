#!/bin/zsh

line() {
	printf '%*s\n' "$(tput cols)" '' | tr ' ' '─'
}
[ -e "$HOME/.hushlogin" ] || touch "$HOME/.hushlogin"

# Note: definitely I am using ./config/.zsh  folder to store the configuration of ZSH but behind the scene, it is important to
# PUT sim link to ~

if [ ! -f "$HOME/.zshenv" ]; then
	echo "[ -f "\$HOME/.config/zsh/zshenv-footer.zsh" ] && source "\$HOME/.config/zsh/zshenv-footer.zsh"" >> ~/.zshenv
	source "$HOME/.zshenv"
fi

echo "🦀 Configuring the ZSH"
ln -svf  "$DOT_FILE/config/zsh/zshrc.zsh"     "$HOME/.zshrc"    && source "$HOME/.zshrc"
ln -svf  "$DOT_FILE/config/zsh/zprofile.zsh"  "$HOME/.zprofile" && source "$HOME/.zprofile"
line


: "${DOT_FILE:?DOT_FILE is not set}"
cd "$DOT_FILE" || echo "\$DOT_FILE == NULL"; exit 1


echo "🦀 Configuring the cargo and git .... "
ln -svf  "$DOT_FILE/config/git/gitconfig"     "$HOME/.gitconfig"
if [[ -n $CARGO_HOME && -d $CARGO_HOME ]]; then
	ln -svf  "$DOT_FILE/etc/cargo_config.toml"    "$CARGO_HOME"
else
	echo "⚠️  Install rust 🦀 \a"
fi
line

# Instal all dot file with python code
echo "Making symbolic links for your system configuration ...."
python hooks/install_link_dot_file.py
cp -vp ~/.config/btop/btop.conf-bak     ~/.config/btop/btop.conf
cp -vp ~/.config/htop/htoprc.bk         ~/.config/htop/htoprc
ln -svf ~/.config/tealdeer/config.toml  ~/Library/Application\ Support/tealdeer/config.toml
ln -svf "$DOT_FILE/hooks/install_link_dot_file.py"  ~/.local/bin/install_link_dot_file
ln -svf "$DOT_FILE/hooks/updateFfmpeg.py"  ~/.local/bin/updateFfmpeg
ln -svf ~/.config/pandoc/defaults ~/.local/share/pandoc/defaults
line

echo "Installing some stand alone scripts from github .... "
hooks/install_github_scrpits.sh
line

echo "Restoring the static config files .... "
python3 hooks/dotmason/dotmason.py restore
line


echo "Installing the NNN file manager .... "
bin_scripts/re_build_NNN.bash
config/nnn/nnn_install_plugins.sh
line

echo "Install them manually ...."
echo "  \$DOT_FILES/etc/myProfile.terminal"
echo "  \$DOT_FILES/etc/sudo"
echo "  \$DOT_FILES/etc/sudo_su-bashrc.sh"
echo "   install brew"
echo "   install brew bundle ~/.config/homebrew/brewfile_minimum"
echo "   rClone config form you google drive rclone folder"
echo "   And opeGPG & ssh from you Google drive rclone folder"
