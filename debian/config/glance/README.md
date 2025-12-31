# glance Download Manager Integration

Directly replaces Firefox's download prompt and sends links to aria2c. Supports auto-intercept for files/torrents.
**Auto-forward downloads**
- Custom aria2c config
- Headers (referrer, cookies) support
- Torrent integration

[addons.mozilla.org/en-US/firefox/addon/glance-integration/](https://addons.mozilla.org/en-US/firefox/addon/glance-integration/)

[github.com/RossWang/glance-Integration](https://github.com/RossWang/glance-Integration)

[Mobile application – Aria2App](https://github.com/devgianlu/Aria2App)

## For setuping the background demon
``` sh
mkdir -p ~/Library/LaunchAgents/
ln -fs $(readlink ~/.config/glance)/com.user.glance.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.wireproxy.plist
```

## For restarting
``` sh
alias glance-reload="launchctl unload ~/Library/LaunchAgents/com.user.glance.plist &&
				    launchctl load ~/Library/LaunchAgents/com.user.glance.plist"

```

## Bones after starting the server with launchctl
To Download file using aria2c launchctl demon I have tried this command, but not work till 2025-Nov-21:

- [Problem page - Github](https://github.com/glance/glance/issues/1163)
- [Issues page - Github](https://github.com/glance/glance/issues?q=tasks%20to%20aria2%20rpc%20server)
- [A new thing like glance - Github](https://github.com/nzbget/nzbget)

``` sh
aria2c --rpc-secret="$ARIA2C_SESSION_TOKEN" "https://example.com/file.zip"
```

---
---

# Automatically update BT tracker files every day 3AM

``` sh
crontab -e
# m h  dom mon dow   command
0 3 * * * bash ~/.config/glance/script/update_bt_tracker.sh
```
