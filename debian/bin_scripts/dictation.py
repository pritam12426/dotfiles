#!/usr/bin/python3
import random
import os
import time

# ANSI Colors
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"

SAY: str = "say -v 'Daniel' "
# SAY: str = "say"

warning: str = "Avoid making mistakes while writing. Consistent accuracy improves over time."
print(f"{RED}{warning}{RESET}")
os.system(f"{SAY} \"{warning}\"")
time.sleep(0.2)

# FILE: str = ".today.txt"
FILE: str = ".vocabularh"

# Load words
try:
    with open(FILE) as f:
        data = [line.strip() for line in f if line.strip()]
except FileNotFoundError:
    print(f"{RED}❌ Error: '.vocabularh' file not found.{RESET}")
    exit(1)

# Shuffle once to avoid repeats
random.shuffle(data)

print(f"\n{GREEN}📚 Dictation Practice Started!{RESET}")
print(f"{YELLOW}✍️  Write the word on paper, then press Enter to reveal the answer.{RESET}")
print(f"{BLUE}🔁 Type '-1' and press Enter at any time to exit.\n{RESET}")

# Loop through each word once
for i, word_choice in enumerate(data, 1):
    if " -> " not in word_choice:
        print(f"{RED}⚠️ Skipping invalid entry: {word_choice}{RESET}")
        continue

    word, meaning = word_choice.split(" -> ", 1)
    print(f"{BLUE}📝 Word {i}/{len(data)} 🔤 #$*%##$%#$%{RESET}")
    os.system(f"{SAY} '{word}'")
    time.sleep(0.3)
    print(f"{GREEN}Meaning 🗣️  {meaning}{RESET}")
    os.system(f"{SAY} '{meaning}'")

    user = input(f"{YELLOW}🔎 Press Enter to reveal spelling (or -1 to exit): {RESET}").strip()
    if user == "-1":
        break

    spelled = ' '.join(word.upper())
    print(f"{GREEN}✅ Word: {word.upper()} → {RESET}{RED}{spelled}{RESET}")
    os.system(f"{SAY} '{spelled}'")
    print()
    time.sleep(0.3)

print(f"{BLUE}👋 Goodbye! Keep practicing.{RESET}")
