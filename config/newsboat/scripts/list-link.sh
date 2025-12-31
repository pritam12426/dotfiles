#!/bin/sh

# Pipe the article's rendered text (with numbered links) to extract URLs
# Newsboat pipes the text to stdin when using pipe-to

# show full context line but only when it contains a URL
grep -E 'https?://' |

fzf --prompt="Select link: " --height=20 |
# Extract URLs safely
grep -o 'https\?://\S\+' |
xargs -r open -a "Firefox"
