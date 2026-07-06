#!/usr/bin/env python3
"""
pkg-config-static.py
====================
A small wrapper around ``pkg-config --libs`` (and optionally ``--cflags``)
for macOS that selectively forces static linking of third-party libraries.

This script rewrites ``-l<name>`` flags into explicit static-archive loads
when a matching ``.a`` file exists in the provided ``-L`` search paths.

Why?
----
macOS does not support fully static binaries like Linux (``-static`` does
not work for system libraries).  This tool allows selective static linking
of third-party libraries while keeping macOS system libraries dynamic.

Features
--------
* Preserves original link order.
* Falls back to dynamic linking if no static archive is found.
* Pre-indexes all ``-L`` directories in a single pass for O(1) lookups.
* Automatically forwards unknown / meta flags to the real ``pkg-config``.
* Respects the ``PKG_CONFIG_REAL`` environment variable for the backing
  binary (use this instead of PKG_CONFIG to avoid infinite recursion).
* Can be forced to run on non-macOS hosts via ``FORCE_RUN=1``.
* Per-library allow / deny lists via env vars or CLI flags.
* Configurable linker strategy: ``force_load`` (default), ``search_path``,
  or ``weak`` (see STATIC_LINK_STRATEGY below).
* Static-aware ``--cflags``: merges include paths from both static and
  dynamic prefixes when they differ.

Linker Strategies
-----------------
force_load (default)
    ``-Wl,-force_load,<path>/libfoo.a``
    Loads every symbol from the archive — safest for Objective-C categories
    and other symbol-visibility-sensitive code, but inflates binary size.

search_path
    Prepends the archive's parent directory to the linker search path and
    emits a plain ``-lfoo``.  The linker picks ``.a`` over ``.dylib`` when
    the ``.a`` appears first in the search path.  Smaller binaries; dead-
    strip removes unused symbols.

weak
    ``-Wl,-weak-l<name>`` — dynamic weak link.  Useful for optional system
    frameworks that may not be present on older OS versions.  Does NOT
    perform static linking; included here for completeness.

Allow / Deny Lists
------------------
Environment variables (colon-separated library names, no ``lib`` prefix):

    STATIC_ALLOW=foo:bar   # only statically link these two
    STATIC_DENY=baz:qux    # dynamically link these, static-link everything else

CLI equivalents (take precedence over env vars):

    --static-allow=foo:bar
    --static-deny=baz:qux

Environment Variables
---------------------
PKG_CONFIG_REAL   Path to the real pkg-config binary (default: pkgconf).
                  Use this instead of PKG_CONFIG to avoid infinite
                  recursion when this script is set as PKG_CONFIG itself.

PKG_CONFIG        Set by build systems to point at this wrapper.
                  Do NOT set this to the real pkg-config when using this
                  script — use PKG_CONFIG_REAL instead.

Usage
-----
    # Recommended setup:
    export PKG_CONFIG_REAL="pkg-config"      # real binary
    export PKG_CONFIG="pkg-config-static"    # this wrapper

    python3 pkg-config-static.py --libs libfoo libbar
    python3 pkg-config-static.py --libs --cflags libfoo
    python3 pkg-config-static.py --libs --static-allow=foo:bar libfoo libbar
    STATIC_DENY=baz:qux python3 pkg-config-static.py --libs libfoo libbar
    FORCE_RUN=1 python3 pkg-config-static.py --libs libfoo
"""

from __future__ import annotations

import os
import shlex
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------


# Use PKG_CONFIG_REAL for the backing binary to avoid infinite recursion
# when this script itself is set as $PKG_CONFIG by build systems.
# Falls back to PKG_CONFIG only if PKG_CONFIG_REAL is not set and the
# value doesn't point back at this script.
def _resolve_real_pkg_config() -> str:
	real = os.environ.get("PKG_CONFIG_REAL")
	if real:
		return real
	# Fallback: if PKG_CONFIG is set but doesn't look like this script, use it.
	pkg = os.environ.get("PKG_CONFIG", "pkgconf")
	script_name = Path(sys.argv[0]).name
	if Path(pkg).name != script_name:
		return pkg
	# Last resort: standard names
	return "pkgconf"


_PKG_CONFIG: str = _resolve_real_pkg_config()

# Linker strategy: "force_load" | "search_path" | "weak"
_STRATEGY: str = os.environ.get("STATIC_LINK_STRATEGY", "force_load")

# Flags that should be passed straight through without any transformation.
_PASSTHROUGH_FLAGS: frozenset[str] = frozenset(
	[
		"--version",
		"--help",
		"--modversion",
		"--exists",
		"--print-errors",
		"--silence-errors",
		"--errors-to-stdout",
		"--print-provides",
		"--print-requires",
		"--print-requires-private",
		"--list-all",
		"--debug",
		"--validate",
		# version comparison flags used by autoconf/configure scripts
		"--atleast-pkgconfig-version",
		"--atleast-version",
		"--exact-version",
		"--max-version",
		# uninstalled flag
		"--uninstalled",
	]
)

# Our own flags that we consume before forwarding to pkg-config.
_OWN_FLAG_PREFIXES: tuple[str, ...] = ("--static-allow=", "--static-deny=")


# ---------------------------------------------------------------------------
# pkg-config runner
# ---------------------------------------------------------------------------


def run_pkg_config(args: list[str]) -> str:
	"""Invoke the real pkg-config and return its stdout as a stripped string."""
	try:
		result = subprocess.run(
			[_PKG_CONFIG, *args],
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			text=True,
			check=True,
		)
		if result.stderr:
			sys.stderr.write(result.stderr)
		return result.stdout.strip()
	except subprocess.CalledProcessError as exc:
		if exc.stdout:
			sys.stderr.write(exc.stdout)
		if exc.stderr:
			sys.stderr.write(exc.stderr)
		sys.exit(exc.returncode)
	except FileNotFoundError:
		sys.stderr.write(f"pkg-config-static: '{_PKG_CONFIG}' not found in PATH.\nInstall pkg-config or set the PKG_CONFIG_REAL environment variable.\n")
		sys.exit(127)


# ---------------------------------------------------------------------------
# Allow / deny list helpers
# ---------------------------------------------------------------------------


def parse_list(value: str) -> frozenset[str]:
	"""Parse a colon-separated library name list into a frozenset."""
	return frozenset(name.strip() for name in value.split(":") if name.strip())


def should_static_link(libname: str, allow: frozenset[str], deny: frozenset[str]) -> bool:
	"""Return True if *libname* should be statically linked.

	Rules (in priority order):
	  1. If an allow-list is set, only names on it are eligible.
	  2. If a deny-list is set, names on it are excluded.
	  3. Otherwise, static-link anything that has a matching ``.a``.
	"""
	if allow:
		return libname in allow
	if deny:
		return libname not in deny
	return True  # default: static-link if a .a exists


# ---------------------------------------------------------------------------
# Static-archive index helpers
# ---------------------------------------------------------------------------


def collect_lib_dirs(tokens: list[str]) -> list[Path]:
	"""Return unique ``-L<dir>`` paths in original link order."""
	seen: set[Path] = set()
	dirs: list[Path] = []
	for token in tokens:
		if token.startswith("-L") and len(token) > 2:
			path = Path(token[2:])
			if path not in seen:
				seen.add(path)
				dirs.append(path)
	return dirs


def build_static_index(search_dirs: list[Path]) -> dict[str, Path]:
	"""Scan each ``-L`` directory once and build a ``libname → .a path`` map.

	First occurrence wins, preserving link order.
	"""
	index: dict[str, Path] = {}
	for directory in search_dirs:
		if not directory.is_dir():
			continue
		try:
			for archive in directory.glob("lib*.a"):
				stem = archive.name
				if stem.startswith("lib") and stem.endswith(".a"):
					libname = stem[3:-2]
					if libname not in index:
						index[libname] = archive.resolve()
		except PermissionError:
			continue
	return index


# ---------------------------------------------------------------------------
# Linker strategy: emit the right flags for a given static archive
# ---------------------------------------------------------------------------


def static_flags(libname: str, archive: Path, strategy: str, extra_search_dirs: set[Path]) -> list[str]:
	"""Return the linker flags to statically link *archive*.

	Side-effect for ``search_path`` strategy: adds archive's parent to
	*extra_search_dirs* so callers can emit ``-L`` flags once, up front.
	"""
	if strategy == "force_load":
		return [f"-Wl,-force_load,{archive}"]
	elif strategy == "search_path":
		extra_search_dirs.add(archive.parent)
		return [f"-l{libname}"]
	elif strategy == "weak":
		return [f"-Wl,-weak-l{libname}"]
	else:
		sys.stderr.write(f"pkg-config-static: unknown STATIC_LINK_STRATEGY '{strategy}'.\nValid values: force_load, search_path, weak\n")
		sys.exit(1)


# ---------------------------------------------------------------------------
# Token transformation  (--libs)
# ---------------------------------------------------------------------------


def transform_lib_tokens(tokens: list[str], allow: frozenset[str], deny: frozenset[str], strategy: str) -> list[str]:
	"""Rewrite ``-l<name>`` tokens according to the chosen strategy."""
	lib_dirs = collect_lib_dirs(tokens)
	static_index = build_static_index(lib_dirs)

	# Directories added by the search_path strategy (emitted before -l flags).
	extra_search_dirs: set[Path] = set()

	output: list[str] = []
	for token in tokens:
		if token.startswith("-l") and len(token) > 2:
			libname = token[2:]
			archive = static_index.get(libname)
			if archive and should_static_link(libname, allow, deny):
				output.extend(static_flags(libname, archive, strategy, extra_search_dirs))
			else:
				output.append(token)
		else:
			output.append(token)

	# Prepend any new -L dirs needed by the search_path strategy.
	# Existing -L dirs are already in the token stream; only add new ones.
	existing_dirs = {d.resolve() for d in lib_dirs}
	prefix = [f"-L{d}" for d in extra_search_dirs if d not in existing_dirs]
	return prefix + output


# ---------------------------------------------------------------------------
# Token transformation  (--cflags)
# ---------------------------------------------------------------------------


def transform_cflags_tokens(tokens: list[str], static_index: dict[str, Path]) -> list[str]:
	"""Augment ``--cflags`` output with include paths from static prefixes.

	When a static archive lives in ``<prefix>/lib/libfoo.a``, its headers
	are expected at ``<prefix>/include``.  If that path differs from paths
	already in the token stream, we add ``-I<prefix>/include``.

	This handles the common case where a static build was installed into a
	separate prefix (e.g. ``/opt/static``) while the dynamic build lives in
	``/usr/local``.
	"""
	existing_includes: set[Path] = set()
	for token in tokens:
		if token.startswith("-I") and len(token) > 2:
			existing_includes.add(Path(token[2:]).resolve())

	extra: list[str] = []
	for archive in static_index.values():
		# Heuristic: lib/ → ../include  (covers lib, lib64, lib/x86_64-…)
		candidate = (archive.parent.parent / "include").resolve()
		if candidate.is_dir() and candidate not in existing_includes:
			extra.append(f"-I{candidate}")
			existing_includes.add(candidate)

	return tokens + extra


# ---------------------------------------------------------------------------
# CLI argument parsing  (our own flags only)
# ---------------------------------------------------------------------------


def extract_own_flags(argv: list[str]) -> tuple[list[str], frozenset[str], frozenset[str]]:
	"""Strip ``--static-allow`` / ``--static-deny`` from *argv*.

	Returns ``(cleaned_argv, allow_set, deny_set)``.  CLI values take
	precedence over environment variables.
	"""
	cleaned: list[str] = []
	allow: frozenset[str] | None = None
	deny: frozenset[str] | None = None

	for arg in argv:
		if arg.startswith("--static-allow="):
			allow = parse_list(arg[len("--static-allow=") :])
		elif arg.startswith("--static-deny="):
			deny = parse_list(arg[len("--static-deny=") :])
		else:
			cleaned.append(arg)

	# Fall back to env vars if CLI flags were not given.
	if allow is None:
		allow = parse_list(os.environ.get("STATIC_ALLOW", ""))
	if deny is None:
		deny = parse_list(os.environ.get("STATIC_DENY", ""))

	return cleaned, allow, deny


# ---------------------------------------------------------------------------
# Passthrough flag check (handles both --flag and --flag=value forms)
# ---------------------------------------------------------------------------


def is_passthrough(argv: list[str]) -> bool:
	"""Return True if any flag in argv should be passed straight through."""
	for flag in argv:
		# exact match
		if flag in _PASSTHROUGH_FLAGS:
			return True
		# --flag=value form (e.g. --atleast-pkgconfig-version=0.9.0)
		base = flag.split("=")[0]
		if base in _PASSTHROUGH_FLAGS:
			return True
	return False


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main(argv: list[str] = sys.argv[1:]) -> None:
	# Platform guard.
	if sys.platform != "darwin" and not os.environ.get("FORCE_RUN"):
		sys.stderr.write("pkg-config-static: this tool targets macOS.\nSet FORCE_RUN=1 to run anyway (e.g. in a cross-compile env).\n")
		sys.exit(1)

	# No arguments: mimic pkg-config's own behaviour.
	if not argv:
		os.execvp(_PKG_CONFIG, [_PKG_CONFIG])

	# Strip our own flags before forwarding anything to pkg-config.
	argv, allow, deny = extract_own_flags(argv)

	# Meta / informational flags: forward directly without transformation.
	# This also prevents infinite recursion for flags like
	# --atleast-pkgconfig-version used by autoconf configure scripts.
	if is_passthrough(argv):
		os.execvp(_PKG_CONFIG, [_PKG_CONFIG, *argv])

	# Not a link-flags or cflags query: forward as-is.
	wants_libs = "--libs" in argv
	wants_cflags = "--cflags" in argv
	if not wants_libs and not wants_cflags:
		os.execvp(_PKG_CONFIG, [_PKG_CONFIG, *argv])

	# Uncomment to always pass --static to pkg-config (includes private deps):
	# if "--static" not in argv:
	#     argv = ["--static", *argv]

	# ------------------------------------------------------------------
	# --libs transformation
	# ------------------------------------------------------------------
	raw_libs = ""
	if wants_libs:
		libs_argv = [a for a in argv if a != "--cflags"]
		raw_libs = run_pkg_config(libs_argv)
		if raw_libs:
			lib_tokens = shlex.split(raw_libs)
			transformed_libs = transform_lib_tokens(lib_tokens, allow, deny, _STRATEGY)
			print(" ".join(transformed_libs), end="")
		else:
			print(end="")

	# ------------------------------------------------------------------
	# --cflags transformation (static-prefix-aware)
	# ------------------------------------------------------------------
	if wants_cflags:
		cflags_argv = [a for a in argv if a != "--libs"]
		raw_cflags = run_pkg_config(cflags_argv)
		cflags_tokens = shlex.split(raw_cflags) if raw_cflags else []

		# Build static index from any -L flags we saw in --libs output
		# so we can derive matching include paths.
		if wants_libs and raw_libs:
			lib_dirs = collect_lib_dirs(shlex.split(raw_libs))
		else:
			lib_dirs = []
		static_index = build_static_index(lib_dirs)
		transformed_cflags = transform_cflags_tokens(cflags_tokens, static_index)

		sep = " " if wants_libs else ""
		print(sep + " ".join(transformed_cflags), end="")

	print()  # final newline
	sys.exit(0)


if __name__ == "__main__":
	main()
