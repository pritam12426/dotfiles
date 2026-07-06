#!/bin/sh

cd "$DOT_FILE" || exit

python3 hooks/packageDataBackup.py

printf "\n"
# mackup backup -f

printf "\n\n"
git --no-pager diff --stat
