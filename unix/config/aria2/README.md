# Aria2 Download Manager Integration

Directly replaces Firefox's download prompt and sends links to aria2c. Supports auto-intercept for files/torrents.
**Auto-forward downloads**
- Custom aria2c config
- Headers (referrer, cookies) support
- Torrent integration

[addons.mozilla.org/en-US/firefox/addon/aria2-integration/](https://addons.mozilla.org/en-US/firefox/addon/aria2-integration/)

[github.com/RossWang/Aria2-Integration](https://github.com/RossWang/Aria2-Integration)

[Mobile application – Aria2App](https://github.com/devgianlu/Aria2App)

## For setuping the background demon
``` sh
mkdir -p ~/Library/LaunchAgents/
ln -fs $(readlink ~/.config/aria2)/com.user.aria2.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.aria2.plist
```

## For restarting
``` sh
alias aria2-reload="launchctl unload ~/Library/LaunchAgents/com.user.aria2.plist &&
				    launchctl load ~/Library/LaunchAgents/com.user.aria2.plist"
```

## Bones after starting the server with launchctl
To Download file using aria2c launchctl demon I have tried this command, but not work till 2025-Nov-21:

- [Problem page - Github](https://github.com/aria2/aria2/issues/1163)
- [Issues page - Github](https://github.com/aria2/aria2/issues?q=tasks%20to%20aria2%20rpc%20server)
- [A new thing like aria2 - Github](https://github.com/nzbget/nzbget)

``` sh
./script/aria2c_add_to_rpc_downloder.sh
```

---
---

# Automatically update BT tracker files every day 3AM

``` sh
crontab -e
# m h  dom mon dow   command
0 3 * * * bash ~/.config/aria2/script/update_bt_tracker.sh
```
