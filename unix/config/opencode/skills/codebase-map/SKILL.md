---
name: codebase-map
description: Builds an accurate high-level architecture map of an open-source repository including modules, entry points, data flow, and ownership. Use when a user asks for a codebase overview, architecture map, module map, or wants to understand how a repository is structured.
---

# Codebase Map

Produce a single accurate `./CODEBASE_MAP.md` that describes the current repository. Do not invent structure, modules, or relationships.

## Mandatory First Steps

1. Walk the entire repository (source, build, config, tests, scripts).
2. Identify the primary language(s) and package manager(s).
3. Locate all entry points (main binaries, server start, CLI roots, library public roots).
4. Identify major directories and the responsibility of each.
5. Trace the primary data and control flows from entry points outward.
6. Note ownership boundaries only when they are clear from code or existing docs.

If the project is a Git repository, optionally note the last major structural change, but never document removed code as if it still exists.

## Output File

Write or update `./CODEBASE_MAP.md`.

## Required Sections

### 1. Project Snapshot
- One-paragraph purpose derived only from code and existing top-level docs.
- Primary language(s) and runtime.
- How the project is meant to be run or consumed (binary, library, service, monorepo package, etc.).

### 2. Entry Points
List every real entry point found in the code:
- File path
- What starts there (CLI, HTTP server, library export, worker, etc.)
- How a user or process reaches it

### 3. Major Modules / Packages
For each major directory or package:
- Path
- Responsibility (one or two sentences grounded in the code)
- Key public types or functions (only those clearly exported or used across boundaries)
- Dependencies on other internal modules

Do not list every file. Group by logical ownership.

### 4. Architecture Diagram
Include at least one Mermaid diagram showing:
- Major modules
- Direction of primary dependencies or data flow
- External boundaries (databases, APIs, file system, etc.) only when the code clearly uses them

### 5. Data Flow
Describe the main paths data takes through the system, from input to storage or output. Only document flows that exist in the code.

### 6. Build & Runtime Shape
- How the project is built (high level)
- How it is started in development and production (if distinguishable from scripts or docs)
- Important generated artifacts

### 7. Open Questions
Explicitly list anything that could not be determined from the repository. Never guess.

## Rules

- Every statement must be traceable to files that currently exist.
- Prefer cross-references to `README.md`, `./docs/DEV.md`, or `./docs/DEV_IN_DEPTH.md` instead of duplicating long explanations.
- If the repository already contains an architecture document, update it in place rather than creating a conflicting second document, unless the user explicitly requests a new file.
- Keep the map high-level. Deep implementation details belong in `./docs/DEV_IN_DEPTH.md` or a follow-up skill.
- Use consistent module and package names exactly as they appear in the code.
