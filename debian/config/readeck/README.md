# Shiori Bookmark manager

### Alternative (optoons)
https://alternativeto.net/software/shiori-bookmark-manager/

[addons.mozilla.org/en-US/firefox/addon/shiori_ext/](https://addons.mozilla.org/en-US/firefox/addon/shiori_ext/)

[shiori - Github.com](https://github.com/go-shiori/shiori)

## For setuping the background demon
``` sh
mkdir -p ~/Library/LaunchAgents/
ln -fs $(readlink ~/.config/readeck)/local.app.readeck.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/local.app.readeck.plist
```

## For restarting
``` sh
alias reload-readeck="launchctl unload ~/Library/LaunchAgents/local.app.readeck.plist &&
					  launchctl load ~/Library/LaunchAgents/local.app.readeck.plist"

```
