#!/usr/bin/env python3
"""
Pretty GitHub Repo Info Viewer
Minimal + clean + emoji style output
"""

import argparse
import sys
from datetime import datetime
from urllib.parse import urlparse

import requests
from os import environ

# ──────────────────────────────────────────────────────────────────────────────
# Simple ANSI colors (safe for most terminals)
class c:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    DIM = '\033[2m'
    GRAY = '\033[90m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'


BASE_URL = "https://api.github.com/repos/"
TOKEN = environ.get("GITHUB_AUTH_TOKEN")
HEADERS = {"Authorization": f"token {TOKEN}"} if TOKEN else {}


def human(n: int) -> str:
    """1234567 → 1.23M   9876 → 9.9k"""
    if n >= 1_000_000:
        return f"{n / 1_000_000:.2f}M".rstrip("0").rstrip(".") + "M"
    if n >= 10_000:
        return f"{n / 1_000:.1f}k".rstrip("0").rstrip(".") + "k"
    if n >= 1_000:
        return f"{n / 1_000:.1f}k"
    return str(n)


def nice_date(iso: str | None) -> str:
    if not iso:
        return "—"
    try:
        dt = datetime.strptime(iso, "%Y-%m-%dT%H:%M:%SZ")
        return dt.strftime("%d %b %Y")
    except:
        return iso[:10] or "—"


class RepoInfo:
    def __init__(self, owner: str, repo: str):
        url = f"{BASE_URL}{owner}/{repo}"
        r = requests.get(url, headers=HEADERS, timeout=12)

        if r.status_code == 404:
            raise ValueError("Repository not found")
        if r.status_code != 200:
            msg = r.json().get("message", "Unknown error")
            raise ValueError(f"GitHub API error {r.status_code} — {msg}")

        d = r.json()

        self.full_name = d.get("full_name", "?/?")
        self.description = d.get("description") or ""
        self.language = d.get("language") or "—"
        self.default_branch = d.get("default_branch", "—")
        self.created = nice_date(d.get("created_at"))
        self.updated = nice_date(d.get("updated_at"))
        self.pushed = nice_date(d.get("pushed_at"))
        self.stars = d.get("stargazers_count", 0)
        self.forks = d.get("forks_count", 0)
        self.issues = d.get("open_issues_count", 0)
        self.homepage = d.get("homepage") or "—"
        self.html_url = d.get("html_url", "—")
        self.private = d.get("private", False)
        self.archived = d.get("archived", False)
        self.license = d.get("license", {}).get("spdx_id", "—") if d.get("license") else "—"


    def print_nice(self):
        lock = "🔒 " if self.private else ""
        arch = " 🏛️ ARCHIVED" if self.archived else ""

        print()
        print(f"{c.BOLD}{lock}{self.full_name}{arch}{c.RESET}")
        print(f"{c.GRAY}{'─' * (len(self.full_name) + len(lock) + len(arch) + 2)}{c.RESET}")

        if self.description:
            print(f"  {self.description.strip()}")
            print()

        # Stats line
        print(
            f"  {c.YELLOW}★ {human(self.stars)}{c.RESET}   "
            f"{c.GREEN}🍴 {human(self.forks)}{c.RESET}   "
            f"{c.RED}⚠ {human(self.issues)}{c.RESET}"
        )
        print()

        # Info grid
        print(f"  {c.DIM}Language      {c.RESET}{self.language}")
        print(f"  {c.DIM}Branch        {c.RESET}{self.default_branch}")
        print(f"  {c.DIM}License       {c.RESET}{self.license}")
        print()
        print(f"  {c.DIM}Created       {c.RESET}{self.created}")
        print(f"  {c.DIM}Last update   {c.RESET}{self.updated}")
        print(f"  {c.DIM}Last push     {c.RESET}{self.pushed}")
        print()

        if self.homepage != "—":
            print(f"  {c.CYAN}🌐 {self.homepage}{c.RESET}")

        print(f"  {c.BLUE}→ {self.html_url}{c.RESET}")
        print()


def parse_repo_arg(s: str) -> tuple[str, str]:
    s = s.strip()

    if s.startswith(("http://", "https://")):
        p = urlparse(s)
        if "github.com" not in p.netloc.lower():
            raise ValueError("Only github.com URLs are supported")
        path = p.path.strip("/").removesuffix(".git")
        parts = path.split("/")
        if len(parts) < 2:
            raise ValueError("Invalid GitHub URL")
        return parts[0], parts[1]

    if "/" not in s:
        raise ValueError("Use format: owner/repo   or   full URL")

    owner, repo = s.split("/", 1)
    repo = repo.removesuffix(".git").strip()
    return owner.strip(), repo.strip()


def main():
    parser = argparse.ArgumentParser(
        description="Clean & modern GitHub repository info viewer",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("repo", help="owner/repo  or  https://github.com/owner/repo")
    parser.add_argument("--raw", action="store_true", help="plain text output (script friendly)")

    args = parser.parse_args()

    try:
        owner, repo_name = parse_repo_arg(args.repo)
    except ValueError as e:
        print(f"{c.RED}Error:{c.RESET} {e}")
        return 1

    try:
        info = RepoInfo(owner, repo_name)

        if args.raw:
            print(f"{info.full_name}")
            print(f"Description : {info.description or '—'}")
            print(f"Language    : {info.language}")
            print(f"Stars       : {info.stars}")
            print(f"Forks       : {info.forks}")
            print(f"Issues      : {info.issues}")
            print(f"Updated     : {info.updated}")
            print(f"URL         : {info.html_url}")
        else:
            info.print_nice()

    except requests.RequestException as e:
        print(f"{c.RED}Network error:{c.RESET} {e}")
        return 1
    except ValueError as e:
        print(f"{c.RED}Error:{c.RESET} {e}")
        return 1
    except Exception as e:
        print(f"{c.RED}Unexpected:{c.RESET} {type(e).__name__}: {e}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())

# sed -i 's/	/\t/g'
