---
name: dead-code-hunt
description: Finds unused exports, unreachable modules, and orphaned code in a repository by analyzing the real import and call graph. Use when a user asks to find dead code, unused symbols, unreachable files, or to clean up a codebase.
---

# Dead Code Hunt

Identify code that appears unreachable or unused based on the current repository contents. Report only what the static structure supports. Do not delete anything unless the user explicitly requests removal.

## Mandatory First Steps

1. Walk the entire repository and identify language(s), build system, and package boundaries.
2. Build a picture of the reachable set starting from:
   - Documented or conventional entry points
   - Test files (tests may intentionally reference otherwise-unused helpers)
   - Build scripts, code generation, and CI configuration
   - Exported public API of libraries
3. Treat reflection, dynamic imports, plugin loading, and string-based dispatch as potential reachability edges. When they exist, mark related symbols as “possibly reachable” rather than dead.
4. Respect language and tooling conventions (e.g. `main`, `init`, exported symbols in Go, `__all__` in Python, public class members in Java/Kotlin, etc.).

## Output File

Write or update `./DEAD_CODE_REPORT.md`.

## Required Sections

### 1. Method & Scope
- Languages and packages examined
- Entry points used as roots
- Known dynamic or reflective mechanisms that limit certainty
- What was excluded (generated code, vendored third-party, etc.)

### 2. Unreachable Modules / Files
List source files or packages that have no inbound references from the reachable set.
- Path
- Evidence (no imports, no build inclusion, etc.)
- Confidence (high / medium / low) with reason

### 3. Unused Exports / Symbols
List public or package-visible symbols that are never referenced inside the repository (and are not part of a documented public API surface).
- Symbol and location
- Why it appears unused
- Confidence

### 4. Possibly Dead but Uncertain
Symbols or files that look unused but sit behind dynamic dispatch, plugins, stringly-typed registries, or external consumers. Do not label these as safe to delete.

### 5. Test-Only Code
Note helpers that are only referenced from tests. These are not dead; they are test support.

### 6. Recommended Next Actions
- High-confidence removal candidates
- Items that need a quick human check (especially anything that might be part of a public API)
- Suggested verification steps (build, test, grep for string references)

## Rules

- Never mark a symbol dead if it is part of the public API surface of a library unless the user has confirmed it is internal.
- Prefer false negatives (missing some dead code) over false positives (recommending deletion of live code).
- Cite concrete evidence for every item (lack of imports, lack of references, exclusion from build).
- Do not perform deletions in this skill. Only report.
- If `API.md` or `CODEBASE_MAP.md` exists, use them to avoid flagging intentional public surface.
- Generated code and vendor directories are out of scope unless the user explicitly includes them.
