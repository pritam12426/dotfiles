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

