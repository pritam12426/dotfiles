#!/usr/bin/env -S python3 -u
# -*- coding: utf-8 -*-

# Command line media player by using ffplay lib.

import os
from subprocess import run
from random import choice
from sys import platform


def get_title(raw_name: str) -> str:
    _name = raw_name.rsplit(".", maxsplit=1)[0].replace("_", " ")
    return f"~ {_name.upper()} ~"


def find_type_system() -> tuple:
    if platform == "win32":
        return "cls", "\\"

    elif platform == "linux" or platform == "darwin":  # Darwin is for mac os
        return "clear", "/"

    else:
        print("Unsupported system")
        exit(1)


os.chdir(os.getcwd())
all_file: list[str] = sorted(
    [i for i in os.listdir() if i.endswith((".mp4", ".mkv", ".mp3", ".m4a"))]
)

if len(all_file) == 0:
    print(f"There is not media file in '{os.getcwd()}'")
    exit(1)

element_len: int = len(str(len(all_file)))
while True:
    user_input: str = input(
        f"Enter 'so/no' in between '1 to {len(all_file)}' >> "
    ).lower()
    number_of_equal: int = os.get_terminal_size().columns

    if user_input == "exit" or user_input == "q":
        exit(0)

    elif user_input == "clear":
        os.system(find_type_system()[0])
        continue

    elif user_input == "":
        continue

    elif user_input.startswith("/"):
        os.system(find_type_system()[0])
        element: str = user_input.removeprefix("/")

        element_content: str = f" Search log for >> '{element}' ".center(
            number_of_equal, "="
        )
        print(element_content)

        for i in all_file:
            name: str = i.rsplit(".")[0].replace("_", " ")
            extension: str = i.rsplit(".")[1]
            if element.casefold() in name.replace("_", " ").casefold():
                print(
                    f" ● {(all_file.index(i) + 1):{element_len}} | {all_file[all_file.index(i)]}"
                )
        print("=" * number_of_equal)
        continue

    elif user_input == "ls":
        os.system(find_type_system()[0])

        element_len: int = len(str(len(all_file)))
        print(" directory contents ".center(number_of_equal, "="))

        for index, i in enumerate(all_file, start=1):
            print(f"{index:{element_len}} | {i}")

        print("=" * number_of_equal)
        continue

    elif user_input == "r":
        command: str = choice(all_file)
        element: str = f"● SO/no:  '{(all_file.index(command) + 1)}' > '{command}'"
        print(element)
        if len(element) > number_of_equal:
            print("=" * number_of_equal)
        else:
            print("=" * len(element))

    elif user_input.isdigit():
        user_input: int = int(user_input)
        if user_input > len(all_file):
            print(f"'{user_input}' out of ranger.")
            continue

        else:
            command: str = all_file[(user_input - 1)]

    else:
        print("Invalid input.")
        continue

    run(
        ["ffplay", "-window_title", get_title(command), "-loop", "-1", command],
        capture_output=True,
    )
