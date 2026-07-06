# printf "Importing \t %s \n" "$HOME/.zprofile"

# Auto-start Zellij only in Apple Terminal (not VsCode, Zed, SSH, etc)
# if [[ -o login \
# 	&& -z "$ZELLIJ" \
# 	&& "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
# 		exec ~/.local/github-releases-binary/zellij
# fi

# Auto-start tmux only in Apple Terminal (not VsCode, Zed, SSH, etc)
# if [[ -o login \
# 	&& -z "$TMUX" \
# 	&& "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
# 		exec tmux
# fi

# Auto-start nnn file manger only in Apple Terminal (not VsCode, Zed, SSH, etc)
# if [[ -o login \
# 	&& "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
# 		~/.local/bin/nnn
# fi

# manpath+=("/usr/local/MacGPG2/share/man")

# if hash wireproxy 2>/dev/null && [[ -f "$HOME/Downloads/wg.conf" ]]; then
if (( $+commands[wireproxy] )) && [[ -f ~/Downloads/wg.conf ]]; then
	VPN_ENV_FILE="${TMPDIR:-/tmp}/wire_proxy_env_file.sh"
	alias vpn_export='$DOT_FILE/bin_scripts/wireproxy_start.sh && [ -f "$VPN_ENV_FILE" ] && source "$VPN_ENV_FILE"'
	if [[ -f "$VPN_ENV_FILE" ]]; then
		echo '🛜  You have VPN in this terminal instance'
		source "$VPN_ENV_FILE"
	fi
fi

# ---------------------- Rust ------------------------
if [[ -n $CARGO_HOME && -d $CARGO_HOME ]]; then
	# . "/Users/pritam/.local/lib/cargo/env"
	path+=("$HOME/.local/lib/cargo/bin")

	# path+=("$RUST_HOME/bin")
	# path+=("$RUST_HOME/lib/rustlib/aarch64-apple-darwin/bin")

	# export CARGO_HOME="$HOME/.local/lib/cargo"
	# path+=("$CARGO_HOME/bin")

	# manpath+=("$RUST_HOME/share/man")
fi

# ---------------------- VCPKG ------------------------
if [[ -n $VCPKG_ROOT && -d $VCPKG_ROOT ]]; then
	export CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
	export VCPKG_DOWNLOADS="$HOME/.cache/vcpkg-downloads"
	export VCPKG_TARGET_ARCHITECTURE='arm64'
	export VCPKG_TARGET_TRIPLET='arm64-osx'

	# Optional dynamic pkg-config path
	# VCPKG_TRIPLET="${VCPKG_TARGET_TRIPLET:-arm64-osx}"
	# pkg_config_path+=("$VCPKG_ROOT/installed/$VCPKG_TRIPLET/share/pkgconfig")
fi

# ---------------------- Java ------------------------
if [[ -d $JAVA_HOME ]]; then
	path+=("$JAVA_HOME/bin")
	manpath+=("$JAVA_HOME/man")
fi

# ---------------------- Typst ------------------------
# if hash typst > /dev/null; then
# 	see "$ typst info"
# 	export TYPST_FEATURES=""
# 	export TYPST_FEATURES="html"
# 	export TYPST_FONT_PATHS=""
# fi

# ---------------------- Node / PNPM ------------------------
if [[ -n $NPM_CONFIG_USERCONFIG && -f $NPM_CONFIG_USERCONFIG ]]; then
	export PNPM_HOME="$HOME/Library/pnpm"
	if [ -d "$PNPM_HOME" ] && path+=("$PNPM_HOME")

	path+=("$HOME/.local/lib/node_modules-global/bin")
fi

# ---------------------- Go ------------------------
if [[ -n $GOPATH && -d $GOPATH ]]; then
	path+=("$GOPATH/bin")
fi

# ---------------------- DOT_NET ------------------------
if [[ -n $DOTNET_ROOT && -d $DOTNET_ROOT ]]; then
	path+=("$DOTNET_ROOT")
fi

# ---------------------- Android SDK ------------------------
if [[ -n $ANDROID_HOME && -d $ANDROID_HOME ]]; then
	export ANDROID_AVD_HOME="$HOME/Library/Application Support/android_AVD"
	export ANDROID_SDK_ROOT="$ANDROID_HOME"
	export CHROME_EXECUTABLE="/Applications/Chromium.app/Contents/MacOS/Chromium"

	path+=("$ANDROID_SDK_ROOT/platform-tools")
	path+=("$ANDROID_SDK_ROOT/emulator")
	path+=("$ANDROID_SDK_ROOT/cmdline-tools/19.0/bin")
	path+=("$ANDROID_SDK_ROOT/flutter/bin")

	# NOTE: aliases below should be moved to ~/.zshrc
	alias apktool='java -jar "$ANDROID_HOME/reverse-engineering/dex-tools-v2.4/bin/apktool_2.12.1.jar"'
	alias dex-tools='"$ANDROID_HOME/reverse-engineering/dex-tools-v2.4/bin/dex-tools"'
fi

if [[ -d "$HOME/.config/homebrew" && -d "/opt/homebrew" ]]; then
	source "$HOME/.config/homebrew/__brew_envs__"
	# /opt/homebrew/bin/brew shellenv > $HOME/.config/homebrew/__brew_envs__
	export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_AUTH_TOKEN"
	export HOMEBREW_GITHUB_PACKAGES_TOKEN="$GITHUB_AUTH_TOKEN"
	export HOMEBREW_BUNDLE_FILE_GLOBAL="${XDG_CONFIG_HOME}/homebrew/Brewfile"

	cppflags+=("-I$HOMEBREW_PREFIX/include")
	cflags+=("-I$HOMEBREW_PREFIX/include")
	ldflags+=("-L$HOMEBREW_PREFIX/lib")
	# export CXXFLAGS="$CPPFLAGS $CXXFLAGS"

	# ldflags+=("-L/opt/homebrew/opt/ruby/lib")
	# cppflags+=("-I/opt/homebrew/opt/ruby/include")
	# pkg_config_path+=("/opt/homebrew/opt/ruby/lib/pkgconfig")
	# path+=("/opt/homebrew/opt/ruby/bin")

	pkg_config_path+=("$HOMEBREW_PREFIX/lib/pkgconfig")
	cmake_prefix_path+=("$HOMEBREW_PREFIX/lib/cmake")
	# dyld_library_path+=("$HOMEBREW_PREFIX/lib")  # this line causes and problem with (ffplay && mpv command line)
else
	if [[ $- = *i* ]]; then
		if hash brew; then
			echo "Install the brew shell env... \a"
			echo "/opt/homebrew/bin/brew shellenv > \$HOME/.config/homebrew/__brew_envs__"
		fi
	fi
fi

if (( $+commands[zig] )); then
	export C_INCLUDE_PATH="$CFLAGS"
	export CPLUS_INCLUDE_PATH="$CPPFLAGS"
fi

# Homebrew Ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
	path+=("/opt/homebrew/opt/ruby/bin")
	path+=("/opt/homebrew/lib/ruby/gems/4.0.0/bin")
fi
