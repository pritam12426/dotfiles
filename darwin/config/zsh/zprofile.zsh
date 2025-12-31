# printf "Importing \t %s \n" "$HOME/.zprofile"

# Auto-start Zellij only in Apple Terminal (not VSCode, Zed, SSH, etc)
# if [[ -o login \
# 	&& -z "$ZELLIJ" \
# 	&& "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
# 		exec ~/.local/github-releases-binary/zellij
# fi

# ---------------------- Rust ------------------------
if [[ -n $CARGO_HOME && -d $CARGO_HOME ]]; then
	# . "/Users/pritam/.local/lib/cargo/env"
	__PATH_ADD "/Users/pritam/.local/lib/cargo/bin"

	# __PATH_ADD "$RUST_HOME/bin"
	# __PATH_ADD "$RUST_HOME/lib/rustlib/aarch64-apple-darwin/bin"

	# export CARGO_HOME="$HOME/.local/lib/cargo"
	# __PATH_ADD "$CARGO_HOME/bin"

	# __MANPATH_ADD "$RUST_HOME/share/man"
fi

# ---------------------- VCPKG ------------------------
if [[ -n $VCPKG_ROOT && -d $VCPKG_ROOT ]]; then
	export CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
	export VCPKG_DOWNLOADS="$HOME/.cache/vcpkg-downloads"
	export VCPKG_TARGET_ARCHITECTURE="arm64"
	export VCPKG_TARGET_TRIPLET="arm64-osx"

	# Optional dynamic pkg-config path
	# VCPKG_TRIPLET="${VCPKG_TARGET_TRIPLET:-arm64-osx}"
	# PKG_CONFIG_PATH="$VCPKG_ROOT/installed/$VCPKG_TRIPLET/share/pkgconfig:$PKG_CONFIG_PATH"
fi

# ---------------------- Java ------------------------
if [[ -d $JAVA_HOME ]]; then
	__PATH_ADD     "$JAVA_HOME/bin"
	__MANPATH_ADD  "$JAVA_HOME/man"
fi

# ---------------------- Node / PNPM ------------------------
if [[ -n $NPM_CONFIG_USERCONFIG && -f $NPM_CONFIG_USERCONFIG ]]; then
	export PNPM_HOME="$HOME/Library/pnpm"
	__PATH_ADD "$PNPM_HOME"

	__PATH_ADD "$HOME/.local/lib/node_modules-global/bin"
fi

# ---------------------- Go ------------------------
if [[ -n $GOPATH && -d $GOPATH ]]; then
	__PATH_ADD "$GOPATH/bin"
fi

# ---------------------- DOT_NET ------------------------
if [[ -n $DOTNET_ROOT && -d $DOTNET_ROOT ]]; then
	__PATH_ADD "$DOTNET_ROOT"
fi

# ---------------------- Android SDK ------------------------
if [[ -n $ANDROID_HOME && -d $ANDROID_HOME ]]; then
	export ANDROID_AVD_HOME="$HOME/Library/Application Support/android_AVD"
	export ANDROID_SDK_ROOT="$ANDROID_HOME"
	export CHROME_EXECUTABLE="/Applications/Chromium.app/Contents/MacOS/Chromium"

	__PATH_ADD "$ANDROID_SDK_ROOT/platform-tools"
	__PATH_ADD "$ANDROID_SDK_ROOT/emulator"
	__PATH_ADD "$ANDROID_SDK_ROOT/cmdline-tools/19.0/bin"
	__PATH_ADD "$ANDROID_SDK_ROOT/flutter/bin"

	# NOTE: aliases below should be moved to ~/.zshrc
	alias apktool="java -jar \"$ANDROID_HOME/reverse-engineering/dex-tools-v2.4/bin/apktool_2.12.1.jar\""
	alias dex-tools="\"$ANDROID_HOME/reverse-engineering/dex-tools-v2.4/bin/dex-tools\""
fi

if [ -d "/opt/homebrew" ]; then
	source "$HOME/.config/homebrew/__brew_envs__"
	# /opt/homebrew/bin/brew shellenv > $HOME/.config/homebrew/__brew_envs__
	export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_AUTH_TOKEN"
	export HOMEBREW_GITHUB_PACKAGES_TOKEN="$GITHUB_AUTH_TOKEN"
	export HOMEBREW_BUNDLE_FILE_GLOBAL="${XDG_CONFIG_HOME}/homebrew/Brewfile"

	export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
	export CMAKE_PREFIX_PATH="$HOMEBREW_PREFIX/lib/cmake:$CMAKE_PREFIX_PATH"
	export DYLD_LIBRARY_PATH="$HOMEBREW_PREFIX/lib:$DYLD_LIBRARY_PATH"
else
	if [[ $- = *i* ]]; then
		if hash brew; then
			echo "Install the brew shell env... \a"
			echo "/opt/homebrew/bin/brew shellenv > \$HOME/.config/homebrew/__brew_envs__"
		fi
	fi
fi
