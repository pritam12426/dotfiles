#!/bin/sh

cd "$DOT_FILE" || exit

hooks/packageDataBackup.py

printf "\n"
# mackup backup -f

printf "\n\n"
git --no-pager diff --stat
