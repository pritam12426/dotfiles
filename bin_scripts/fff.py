#!/usr/bin/env -S python3 -u
# -*- coding: utf-8 -*-

from getpass import getpass

if getpass("*") != "name*":
    exit(1)

import os
import json
import ffmpeg  # pip install ffmpeg-python
import datetime
from subprocess import run
from random import shuffle, choice


def is_int(x: str) -> bool:
    try:
        int(x)
    except ValueError:
        return False
    else:
        return True


def float_to_time(time: float) -> str | int:
    if time != 0:
        time_delta = datetime.timedelta(seconds=time)
        base_time = datetime.datetime(1, 1, 1) + time_delta
        return base_time.strftime("%H:%M:%S")
    else:
        return 0


def convert_size(x: float) -> int | float:
    if x != 0:
        x = x / 1024
        return round((x / 1024), 2)
    else:
        return 0


def get_filename(raw_name: str, length: int) -> str:
    if len(raw_name) >= length:
        raw_name = raw_name[: length - 3] + "..."
    return raw_name


def read_metadata(directory: str, file_name: str) -> dict:
    new_data: dict = {}
    try:
        meta_date: dict = ffmpeg.probe(directory + file_name)
    except ffmpeg.Error:
        new_data.update({"title": file_name.rsplit(".")[0], "size": 0, "duration": 0})
        return new_data
    else:
        new_data.update(
            {"size": convert_size(float(meta_date.get("format").get("size", 0)))}
        )
        new_data.update(
            {
                "duration": float_to_time(
                    float(meta_date.get("format").get("duration", 0))
                )
            }
        )
        new_data.update(
            {
                "title": meta_date.get("format")
                .get("tags")
                .get("title", file_name.rsplit(".")[0])
            }
        )
        new_data.update(
            {"height": meta_date.get("streams")[0].get("coded_height", "-")}
        )
        new_data.update({"width": meta_date.get("streams")[0].get("coded_width", "-")})
        return new_data


def write_title(path: str, directory_content: list[str]) -> None:
    from tqdm import tqdm

    new_title: dict = {}
    for i in tqdm(sorted(directory_content), desc="Updating JSON "):
        new_title.update({i: read_metadata(path, i)})

    with open(f"{path}.title_name.json", "w") as json_date:
        json.dump(new_title, json_date, indent="\t", sort_keys=True)


def give_name(extension: str, length: int, path: str) -> str:
    from string import digits, ascii_lowercase

    list_dir: list[str] = os.listdir(path)

    all_word: list[str] = list(digits + ascii_lowercase)
    word: list[str] = list(ascii_lowercase)
    while True:
        shuffle(all_word)
        shuffle(word)
        new_name: str = word[0].lower() + "".join(all_word)[:length]

        if f"{new_name}.{extension}" not in list_dir:
            return new_name


def read_json_file(path: str) -> dict:
    if os.path.exists(f"{path}.title_name.json"):
        with open(f"{path}.title_name.json") as json_date:
            old_json: dict = json.load(json_date)
    return old_json


def copy_video(input_path: str) -> None:
    from shutil import copy

    directory_content: list[str] = sorted(
        [i for i in os.listdir(".") if i.endswith((".mp4", ".mkv"))]
    )

    for i in directory_content:
        extension: str = i.rsplit(".")[-1]
        copy(i, input_path + give_name(extension, 14, input_path) + "." + extension)
        print(f" ● COPED: {i}")
    exit(f"Done copying {len(directory_content)}")


def move_video(input_path: str) -> None:
    directory_content: list[str] = sorted(
        [i for i in os.listdir(".") if i.endswith((".mp4", ".mkv", ".webm"))]
    )

    for i in directory_content:
        extension: str = i.rsplit(".")[-1]
        os.rename(
            i, input_path + give_name(extension, 14, input_path) + "." + extension
        )
        print(f" ● MOVED: {i}")
    exit(f"Done moving {len(directory_content)}")


def list_directory(path: str, length: int) -> None:
    json_data: dict = read_json_file(path)
    os.system("clear")
    print(f"[{'NO'}]{'NAME':^{length}}[{'SIZE':^9}][{'DURATION':^8}][{'PX':^9}]")
    print("-" * (length + 37))

    for index, i in enumerate(json_data.keys()):
        resolution: str = (
            f"{json_data.get(i).get('width')}x{json_data.get(i).get('height')}"
        )
        print(
            f"|{index:>3}|{get_filename(json_data.get(i).get('title'), length):<{length}}|"
            f"{json_data.get(i).get('size'):0<6} MB||{json_data.get(i).get('duration'):<8}||{resolution:->9}|"
        )
    print("-" * (length + 37))


def find_video(
    directory_content: list[str], json_data: dict, length: int, user_input: str
) -> None:
    print(f"[{'NO'}]{'SEARCH-LOG':^{length}}[{'SIZE':^9}][{'DURATION':^8}][{'PX':^9}]")
    print("-" * os.get_terminal_size().columns)

    for i in json_data.keys():
        if user_input.lower() in json_data.get(i).get("title").lower():
            resolution: str = (
                f"{json_data.get(i).get('width')}x{json_data.get(i).get('height')}"
            )
            print(
                f"|{directory_content.index(i):>2}|{get_filename(json_data.get(i).get('title'), length):<{length}}|"
                f"{json_data.get(i).get('size'):0<6} MB||{json_data.get(i).get('duration'):<8}||{resolution:->9}|"
            )


def play_video(directory_content: list[str], user_input: int) -> str | None:
    if user_input <= (len(directory_content) - 1):
        return directory_content[user_input]
    else:
        print(f"'{user_input}' out of range.")
        return None


directory_path: str = os.getenv("FFFF")
# directory_path: str = os.getcwd() + "/"

all_file: list[str] = sorted(
    [i for i in os.listdir(directory_path) if i.endswith((".mp4", ".mkv", ".webm"))]
)

if len(all_file) == 0:
    exit("No media file.")

if not os.path.exists(directory_path + ".title_name.json"):
    write_title(directory_path, all_file)

json_info: dict = read_json_file(directory_path)

if list(json_info.keys()) != all_file:
    write_title(directory_path, all_file)

match input("Insert m, u, p >> "):
    case "p":
        os.system("clear")
        while True:
            user: str = input(
                f"Enter 'so/no' in between '0 to {len(all_file) - 1}' >> " or ""
            ).lower()
            if user == "" or user == "exit" or user == "q":
                os.system("clear")
                exit(0)
            elif user == "clear":
                os.system("clear")
                continue
            elif user == "open .":
                run(["open", directory_path])
                continue
            elif user == "ls":
                list_directory(directory_path, (os.get_terminal_size().columns - 37))
                continue
            elif user.startswith("/"):
                os.system("clear")
                user = user.removeprefix("/")
                find_video(
                    all_file, json_info, (os.get_terminal_size().columns - 37), user
                )
                print("-" * os.get_terminal_size().columns)
                continue
            elif user.startswith("?"):
                os.system("clear")
                user = user.removeprefix("?")
                for index, i in enumerate(all_file):
                    i: str = i.rsplit(".", 1)[0]
                    if user in i:
                        print(f"{index} > {i}")
                continue
            elif user.startswith("open ") or user.startswith("o"):
                user = user.removeprefix("open ")
                user = user.removeprefix("o")
                if is_int(user) and int(user) <= (len(all_file) - 1):
                    user: int = int(user)
                    run(["mpv", f"{directory_path + all_file[user]}"])
                    os.system("clear")
                elif user == "r":
                    command: str = choice(all_file)
                    element: str = f"● SO/no > '{all_file.index(command)}' > '{json_info.get(command).get('title')}'"
                    print(element)
                    print("=" * len(element))
                    run(["mpv", f"{directory_path + command}"])
                    os.system("clear")
                else:
                    print("Invalid input.")
                continue
            elif user.startswith("rm "):
                user = user.removeprefix("rm ")
                if is_int(user) and int(user) <= (len(all_file) - 1):
                    user: int = int(user)
                    print(f"● Deleted: {all_file[user]}")
                    os.remove(f"{directory_path + all_file[user]}")
                else:
                    print("Invalid input.")
                continue
            elif user == "r":
                command: str = choice(all_file)
                element: str = f"● SO/no > '{all_file.index(command)}' > '{json_info.get(command).get('title')}'"
                print(element)
                print("=" * len(element))
            elif is_int(user) and int(user) <= (len(all_file) - 1):
                if play_video(all_file, int(user)) is not None:
                    command: str = play_video(all_file, int(user))
                else:
                    continue
            else:
                print("Invalid input.")
                continue
            title: str = f"{all_file.index(command)} - {json_info.get(command).get('title')}, '{json_info.get(command).get('height')}p' * '{json_info.get(command).get('duration')}'"
            run(
                [
                    "ffplay",
                    "-window_title",
                    title,
                    "-loop",
                    "-1",
                    directory_path + command,
                ],
                capture_output=True,
            )
    case "u":
        write_title(directory_path, all_file)
        # TODO: Add go to keyword
    case "m":
        match input(f"{'Move:':8}'m'\n{'Copy':8}'c'\nInsert >> "):
            case "c":
                copy_video(directory_path)
            case "m":
                move_video(directory_path)
            case _:
                print("Invalid input.")
                exit(1)
    case _:
        print("Invalid input.")
        exit(1)
