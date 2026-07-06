#!/usr/bin/env bash

set -euo pipefail

TODO_FILE="${TODO_FILE:-$HOME/.todo.md}"

show_help() {
	cat <<EOF
Todo — simple CLI task manager

Usage:
  todo [command] [args]

Commands:
  add,   A <msg>     Add a new task
  edit,  E           Edit the todo file
  clean, C           Clear all todos
  find,  F [path]    Search TODO tags in a project
  --help, -H         Show this help

Examples:
  todo add Fix login bug
  todo edit
  todo find .

Todo file:
  $TODO_FILE
EOF
}

case "${1:-}" in
-H|--help)
	show_help
	;;

add|A)
	shift
	echo "$*" >> "$TODO_FILE"
	echo "✔ Added: $*"
	;;

edit|E)
	"${EDITOR:-vi}" "$TODO_FILE"
	;;

clean|C)
	: > "$TODO_FILE"
	echo "✔ Todo list cleared"
	;;

find|F)
	shift
	# rg --no-heading --line-number -Li "(TODO:|FIX:|FIXME:|HACK:|NOTE:|XXX:|BUG:|OPTIMIZE:)" "${@:-.}"
	grep --exclude-dir={.git,venv,node_modules,build} --color=auto -iIrnE "(TODO:|FIX:|FIXME:|HACK:|NOTE:|XXX:|BUG:|OPTIMIZE:)" "${@:-.}"
	;;

"")
	touch "$TODO_FILE"
	# bat --theme gruvbox-dark --style=plain --paging=always "$todo_file"
	less "$TODO_FILE"
	;;

*)
	echo "Unknown command: $1" >&2
	echo "Try 'todo --help'" >&2
	exit 1
	;;
esac
