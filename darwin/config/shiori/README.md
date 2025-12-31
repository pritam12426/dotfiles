# Shiori Bookmark manager

### Alternative (optoons)
https://alternativeto.net/software/shiori-bookmark-manager/

[addons.mozilla.org/en-US/firefox/addon/shiori_ext/](https://addons.mozilla.org/en-US/firefox/addon/shiori_ext/)

[shiori - Github.com](https://github.com/go-shiori/shiori)

## For setuping the background demon
``` sh
mkdir -p ~/Library/LaunchAgents/
ln -fs $(readlink ~/.config/shiori)/local.app.shiori.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/local.app.shiori.plist
```

## For restarting
``` sh
alias reload-shiori="launchctl unload ~/Library/LaunchAgents/local.app.shiori.plist &&
				    launchctl load ~/Library/LaunchAgents/local.app.shiori.plist"

```
