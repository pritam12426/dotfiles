#!/bin/sh

# ===========================================================================
# wireproxy <https://github.com/whyvl/wireproxy>
# To work with script add this line to zshrc

# ---- Add these like to the ~/.zprofile
# VPN_ENV_FILE="${TMPDIR:-/tmp}/wire_proxy_env_file.sh"
# alias vpn_export='$DOT_FILE/bin_scripts/wireproxy_start.sh && [ -f "$VPN_ENV_FILE" ] && source "$VPN_ENV_FILE"'
# if [[ -f "$VPN_ENV_FILE" ]]; then
#	echo "🛜  You have VPN in this terminal instance"
#	source "$VPN_ENV_FILE"
# fi
# ----

# ===========================================================================


WIREPROXY_CONF="$HOME/.config/wireproxy/wireproxy.conf"
WIREGUARD_CONF="$HOME/Downloads/wg.conf"
PROXY_ENV_FILE="${TMPDIR:-/tmp}/wire_proxy_env_file.sh"

if [ ! -f "$WIREGUARD_CONF" ]; then
	echo "❌ Failed to start wireproxy."
	echo "  file   '$WIREGUARD_CONF'   not found ... "
	exit 1
fi

HTTP_ADDR="127.0.0.1:8080"
SOCKS_ADDR="127.0.0.1:1080"
INTERFACE_ADDR="127.0.0.1:9080"

set_proxy() {
	(
		echo "export http_proxy='http://$HTTP_ADDR'"
		echo "export https_proxy='http://$HTTP_ADDR'"
		echo "export all_proxy='socks5://$SOCKS_ADDR'"
		echo "export WIREPROXY_HTTP='http://$HTTP_ADDR'"
		echo "export WIREPROXY_SOCKET='socks5://$SOCKS_ADDR'"
	) > "$PROXY_ENV_FILE"
}

is_running() {
	pgrep -x wireproxy >/dev/null 2>&1
}

if is_running; then
	PID="$(pgrep -x wireproxy)"
	echo "✅ Wireproxy already running (PID: $PID)"
	printf "Kill it? (y/n): "

	read -r choice
	echo

	case "$choice" in
		[nN]*)
			echo "Keeping existing wireproxy."
			set_proxy
			echo "✅ Proxy variables applied."
			exit 0
			;;
		[yY]*)
			echo "😵 Killing wireproxy..."
			pkill -x wireproxy
			unset http_proxy https_proxy all_proxy WIREPROXY_HTTP WIREPROXY_SOCKET
			echo "🗑️  Deleting   '$PROXY_ENV_FILE'   file..."
			# : > "$PROXY_ENV_FILE"
			rm -f "$PROXY_ENV_FILE"
			exit 0
			;;
		*)
			echo "❌ Invalid choice."
			exit 1
			;;
	esac
fi

echo "Starting wireproxy..."
wireproxy --daemon --config "$WIREPROXY_CONF" --info "$INTERFACE_ADDR"

if [ $? -eq 0 ]; then
	sleep 1
	PID="$(pgrep -x wireproxy)"

	echo "✅ Wireproxy started (PID: $PID)"
	echo "   HTTP   → $HTTP_ADDR"
	echo "   SOCKS5 → $SOCKS_ADDR"
	echo "   Stop   → pkill wireproxy"

	set_proxy
	echo "✅ Proxy environment variables set for this session."
else
	echo "❌ Failed to start Wireproxy."
	exit 1
fi
