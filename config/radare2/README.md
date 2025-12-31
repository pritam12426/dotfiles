# Iaito Official radare2 GUI
	- https://github.com/radareorg/iaito

After installing the CLI version of radare2 in "/usr/local/big_library/radare2-6.0.4", you need to link the plugin to the GUI using the following commands:

Go and install the most common plugins for r2 with uing:

``` sh
r2pm -U       # this will update the plugins repo
r2pm -i       # will install the plugins inside   "$HOME/.local/share/radare2"
```

``` sh
ln -sf "$HOME/.local/share/radare2"         "$HOME/Library/Application Support/radareorg/iaito"
ln -sf "$HOME/.local/share/radare2/plugins" "$HOME/Library/Application Support/radareorg/iaito"
```

### Some imp links
	- https://www.youtube.com/watch?v=yPbGK1IPV3s
	- https://www.youtube.com/@DouglasHabian-tq5ck/videos
	- https://book.rada.re/
	- https://github.com/DouglasFreshHabian/FreshPdfLibrary
