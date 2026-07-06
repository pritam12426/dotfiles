# [Wireproxy](https://github.com/octeep/wireproxy)

`wireproxy` is a lightweight Go binary that converts any WireGuard configuration into a SOCKS5/HTTP proxy. It requires no root access and avoids routing your entire system through the VPN.

This is the cleanest, fastest, and most reliable way to set up a proxy on macOS in 2025. It requires no kernel extensions, no system-wide routing changes, and works seamlessly with any WireGuard configuration.

#### Step 1: Install wireproxy

```bash
bin install https://github.com/octeep/wireproxy
```

#### Step 2: Create a wireproxy configuration from your WireGuard config file

Example `~/.config/wireproxy/wireproxy.conf`:

```ini
WGConfig = /Users/pritam/Downloads/2025-Nov-21.conf
# Replace <username> with your macOS username

[Socks5]
	BindAddress = 127.0.0.1:1080

[http]
	BindAddress = 127.0.0.1:8080
```

Alternatively, you can launch it directly without creating a config file.

#### Step 3: Obtain a WireGuard server configuration file
You can get a server configuration file from your VPN provider or generate one yourself. For free options, check out [vpnjantit](https://www.vpnjantit.com).

<img src="2025-Nov-20_at_11.40.54.png" width="600">

### Step 4: Verify the setup
```bash
wireproxy -c ~/.config/wireproxy/wireproxy.conf
```

This command reads your WireGuard `.conf` file and starts a SOCKS5 proxy on port 1080.

#### Step 5: Use the proxy with command-line tools

```bash
# yt-dlp
yt-dlp --proxy socks5://127.0.0.1:1080 "https://youtube.com/..."

# wget
wget --proxy=socks5://127.0.0.1:1080 https://example.com/file

# aria2c
aria2c --async-dns=false --proxy=socks5://127.0.0.1:1080 "https://example.com/bigfile"

# curl
curl --socks5 127.0.0.1:1080 https://ifconfig.me   # should show your VPN IP

# For HTTP proxy instead (some tools prefer it)
curl -x http://127.0.0.1:8080 https://ifconfig.me
```

## By this function you can manually start or stop the wireproxy demon
``` sh
wireproxy-start () {
	if pgrep -x wireproxy > /dev/null
	then
		echo "wireproxy is already running (PID: $(pgrep wireproxy))."
		printf 'Kill it and restart? (y/n): '
		read -k 1 -r choice
		echo
		case "$choice" in
			([nN]) echo "Proxy environment variables are now override for this session."
				eval "export http_proxy="http://127.0.0.1:8080""
				eval "export https_proxy="http://127.0.0.1:8080""
				eval "export all_proxy="socks5://127.0.0.1:1080""
				eval "export WIREPROXY_HTTP="http://127.0.0.1:8080""
				eval "export WIREPROXY_SOCKET="socks5://127.0.0.1:1080""
				return 0 ;;
			([yY]) echo "Killing wireproxy (PID: $(pgrep wireproxy))."
				echo "Unseting variables"
				unset http_proxy https_proxy all_proxy WIREPROXY_HTTP WIREPROXY_SOCKET
				pkill wireproxy
				return $? ;;
		esac
	fi
	wireproxy -d -c ~/.config/wireproxy/wireproxy.conf -i "127.0.0.1:9080"
	if [[ $? -eq 0 ]]
	then
		echo "wireproxy started successfully: $(pgrep wireproxy)"
		echo "Ports: HTTP → 8080    SOCKS5 → 1080"
		echo "To stop later: pkill wireproxy"
		eval "export http_proxy="http://127.0.0.1:8080""
		eval "export https_proxy="http://127.0.0.1:8080""
		eval "export all_proxy="socks5://127.0.0.1:1080""
		eval "export WIREPROXY_HTTP="http://127.0.0.1:8080""
		eval "export WIREPROXY_SOCKET="socks5://127.0.0.1:1080""
		echo "Proxy environment variables are now set for this session."
	fi
}
```

### Summary – Quick Start (recommended)

```bash
bin install wireproxy
wireproxy -c ~/.config/wireproxy/wireproxy.conf
yt-dlp --proxy socks5://127.0.0.1:1080 "https://www.youtube.com/watch?v=..."
aria2c --proxy=socks5://127.0.0.1:1080 "https://big.file.example/download"
```

### [Youtube](https://www.youtube.com/watch?v=ESr0xid-kl4&t=500s)


---
---

## Dackground demon with launchctl

```bash
mkdir -p ~/Library/LaunchAgents/
ln -s $(readlink ~/.config/wireproxy)/com.user.wireproxy.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/com.user.wireproxy.plist
# launchctl load ~/Library/LaunchAgents/com.user.wireproxy.plist
```
