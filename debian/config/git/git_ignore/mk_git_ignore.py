#!/usr/bin/env python3

from os import getcwd, listdir

list_cwd: list[str] = listdir(".")

if ".git" not in list_cwd:
	print("fatal: not a git repository (or any of the parent directories): .git")
	exit(1)

from json import load
from sys import path

from pyfzf import FzfPrompt  # pip install pyfzf
from requests import exceptions, get


def get_existing_list(
	_dir_content: list[str], _supported_list: list[str], _fzf_data: FzfPrompt
) -> list[str]:
	if ".gitignore" not in _dir_content:
		return []

	with open(".gitignore", "r") as _f:
		_old_gitignore_file_list: list = _f.readlines(1)

	if len(_old_gitignore_file_list) == 0:
		return []
	else:
		_old_gitignore_file_list = _old_gitignore_file_list[0][33:-1].split(", ")

	_old_gitignore_data: list[str] = list()

	for _i in _old_gitignore_file_list:
		if _i in _supported_list:
			_old_gitignore_data.append(_i)

	if len(_old_gitignore_data) == 0:
		return []

	_old_gitignore_data.append("None")

	old_fzf_data: list[str] = _fzf_data.prompt(
		"\n".join(_old_gitignore_data).title(),
		fzf_options="-m",
		delimiter="",
	)

	[_i.lower() for _i in old_fzf_data]

	if len(old_fzf_data) == 0:
		_old_gitignore_data.remove("None")
		return _old_gitignore_data
	elif "None" in old_fzf_data:
		return []
	else:
		return old_fzf_data


def get_actual_link(
	_old_gitignore_data: list[str], _supported_list: list[str], _fzf_data: FzfPrompt
) -> list[str]:
	running_list: list[str] = list(
		set(_supported_list).difference(set(_old_gitignore_data))
	)
	running_list.sort()

	x: list[str] = _fzf_data.prompt(
		"\n".join(running_list).title(), fzf_options="-m ", delimiter=""
	)
	x.extend(_old_gitignore_data)

	[_i.lower() for _i in x]
	return sorted(x)


fzf: FzfPrompt = FzfPrompt(
	"/Users/pritam/.local/github-releases-bin/sk"
)  # Enter your path of 'fzf' or 'skim'

with open(path[0] + "/supported_templates.json") as f:
	supported_list: list[str] = load(f)["support_template"]

old_ignore_data: list[str] = get_existing_list(list_cwd, supported_list, fzf)
new_upcoming_data: list[str] = get_actual_link(old_ignore_data, supported_list, fzf)


if "None" in new_upcoming_data or len(new_upcoming_data) == 0:
	exit(1)

link: str = f"https://www.toptal.com/developers/gitignore/api/{','.join(new_upcoming_data).lower()}"
print(link)

try:
	web_data: str = get(link).text
except exceptions.ConnectionError:
	print("Check your network :) \a")
	exit(1)

old_gitignore_data: str = ""
old_gitignore_data += "### INCLUDED <|ignore|> TEMPLATE "
old_gitignore_data += ", ".join(new_upcoming_data)
old_gitignore_data += "\n\n\n"

for i in web_data.split("\n")[3:-2]:
	old_gitignore_data += i + "\n"

with open(".gitignore", "w") as write_file:
	write_file.write(old_gitignore_data)

print(f"Add '.gitignore' in '{getcwd()}'")
