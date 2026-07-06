# This make file is use to download youtuve vidoes with the help of yt-dlp for studing

YT_DLP_PATH = ~/.local/bin/yt-dlp

# make p=1
OUTPUT_OPTIONS = -o "Media/%(title)s.%(ext)s"
ifdef p
	OUTPUT_OPTIONS = -o "Media/%(playlist)s-%(uploader)s/%(playlist_index)s-%(title)s.%(ext)s"

	# make p=1 vno=n
	ifdef vno
		OUTPUT_OPTIONS += --playlist-start ${vno}
	endif
endif


OUTPUT_OPTIONS += -f \
   "bestvideo*[height=480] [ext=mp4][fps<=30]+bestaudio*[ext=m4a]/\
	bestvideo*[height=480] [ext=mp4][fps<=60]+bestaudio*[ext=m4a]/\
	bestvideo*[height<=480][ext=mp4]+bestaudio*[ext=m4a]/\
\
	bestvideo*[height=720] [ext=mp4][fps<=30]+bestaudio*[ext=m4a]/\
	bestvideo*[height=720] [ext=mp4][fps<=60]+bestaudio*[ext=m4a]/\
	bestvideo*[height<=720][ext=mp4]+bestaudio*[ext=m4a]/\
\
	bestvideo*[height=1080][ext=mp4][fps<=30]+bestaudio*[ext=m4a]/\
	bestvideo*[height=1080][ext=mp4][fps<=60]+bestaudio*[ext=m4a]/\
	bestvideo*[height<=1080][ext=mp4]+bestaudio*[ext=m4a]/\
\
	bestvideo*[height<=1080]+bestaudio*/\
	bestvideo*+bestaudio*"


OUTPUT_OPTIONS += --no-write-subs --no-write-auto-subs --compat-options no-live-chat

LINK_FILE = links_study.txt

.PHONY: vdo dow wait clean add list move sleep off

vdo:
	@echo "yt-dlp -a $(LINK_FILE)"
	@$(YT_DLP_PATH) $(OUTPUT_OPTIONS) -a $(LINK_FILE)

dow:
	@echo "yt-dlp $(shell pbpaste)"
	@$(YT_DLP_PATH) $(OUTPUT_OPTIONS) "$(shell pbpaste)"

sleep:
	caffeinate -dw ${shell pgrep make} && sleep 3 && pmset displaysleepnow

wait:
	caffeinate -dw ${shell pgrep make}

clean:
	cat /dev/null > $(LINK_FILE)

edit:
	$(EDITOR) $(LINK_FILE)

add:
	echo "$(shell pbpaste)" >> $(LINK_FILE)

off:
	pmset displaysleepnow

list:
	$(PAGER) $(LESS) $(LINK_FILE)
