---
name: doc-refactor
description: Reorganizes, refactors, and updates project documentation into README.md, DEV.md, and DEV_IN_DEPTH.md without duplication or speculation. Supports initial generation and incremental Git-aware updates.
---

# Documentation Refactoring Task

Your task is to reorganize, generate, and maintain the project's documentation into three distinct files with **zero unnecessary duplication**.

The documentation hierarchy consists of:

* `./README.md`
* `./DEV.md`
* `./DEV_IN_DEPTH.md`

These files must always represent the **current implementation** of the repository.

Your goal is to make each file serve a different audience and purpose.

---

# Initial Repository Inspection

Before doing anything else, perform the following steps **in order**.

## Step 1 — Verify Documentation Files

Check whether the following files exist:

* `./README.md`
* `./DEV.md`
* `./DEV_IN_DEPTH.md`

If any of them do not exist:

1. Crawl the entire repository.
2. Build a complete understanding of the project.
3. Generate the missing documentation file(s) according to the rules defined in this document.
4. Do **not** generate placeholder content.
5. Every statement must be derived from the existing source code.

## Step 2 — Detect Git Repository

Determine whether the current project is inside a Git repository.

* If the project is **not** a Git repository: generate or update the documentation solely from the current repository contents.
* If the project **is** a Git repository, continue with Step 3.

## Step 3 — Find Previous Documentation Revision

For every documentation file that already exists (`README.md`, `DEV.md`, `DEV_IN_DEPTH.md`):

1. Find the most recent Git commit that modified that file.
2. Record that commit hash.
3. Compare that historical revision against the current `HEAD`.
4. Analyse every code change that has occurred since that documentation was last updated.

This comparison must include:

* newly added files
* removed files
* renamed files
* modified source files
* API changes
* behaviour changes
* build changes
* configuration changes
* dependency changes
* execution flow changes
* architectural changes

The purpose is to determine what documentation is now outdated.

## Step 4 — Incremental Documentation Rewrite

Using both:

* the current repository state, and
* the Git diff from the last documentation update (when available),

rewrite the documentation so that it accurately reflects the current implementation.

Do **not** blindly regenerate everything. Instead:

* preserve sections that are still correct
* update only what has changed
* remove obsolete documentation
* document newly introduced behaviour
* keep terminology consistent throughout all three files

---

# General Rules

1. Read the entire repository before writing any documentation.
2. Think carefully before drawing conclusions from the codebase.
3. Do **not** invent features, APIs, architecture, future plans, or behaviour.
4. Every statement must describe **only what exists in the current HEAD**.
5. If Git history is available, use it only to determine what documentation requires updating — not to document removed behaviour unless it still exists.
6. Remove unnecessary duplication across documents.
7. Prefer cross-references instead of copying large sections.
8. Maintain consistent terminology throughout the documentation.
9. Use Markdown.
10. Prefer Mermaid diagrams where they improve understanding.
11. Every statement must be traceable to the repository.
12. If something cannot be determined from the code, explicitly state that it is unclear instead of guessing.

---

# 1. README.md

**Audience:**

* First-time visitors
* Users
* People evaluating the project
* Developers who simply want to install and use it

**This document should answer:**

* What is this project?
* Why does it exist?
* What problem does it solve?
* Main features
* Installation
* Quick start
* Basic usage
* Common commands
* Configuration overview
* Platform support
* Build instructions (high level)
* Example workflow
* Screenshots/examples if available
* License
* Contributing (brief, with links)

**Avoid:**

* Internal architecture
* Implementation details
* Source tree explanations
* Internal protocols
* Deep API documentation
* Design rationale

*If deeper information is required, link to `DEV.md`.*

---

# 2. DEV.md

**Audience:**

* Developers working on the project
* API consumers
* Contributors implementing features

This should provide a high-level engineering understanding without becoming an implementation walkthrough.

### Architecture Overview

* Major components
* Responsibilities
* Data flow
* Request lifecycle
* High-level module interactions

### Build System

* Build process
* Development workflow
* Important scripts
* Generated files

### Server Documentation

Document every server endpoint. For each endpoint include:

* Method
* Path
* Purpose
* Request format
* Response format
* Status codes
* Authentication (if any)
* Side effects

### Client Behavior

Describe:

* Expected request flow
* Retry behavior (if implemented)
* Error handling
* Timeouts
* Streaming behavior (if applicable)

### Concurrency

Explain what happens when:

* Many clients connect
* Rapid-fire requests occur
* Duplicate requests occur
* Long-running requests happen

*Only document actual implemented behavior. If rate limiting, queuing, locking, worker pools, or throttling exist, describe them. If they do not exist, explicitly state that they are not implemented.*

### Repository Layout

High-level directory overview. Explain what each major directory is responsible for. Do not describe every file.

### Development Guidelines

* Coding conventions already used
* Logging
* Error handling
* Testing
* Debugging

*Link to `DEV_IN_DEPTH.md` for implementation details.*

---

# 3. DEV_IN_DEPTH.md

**Audience:**

* New contributors
* Engineers making architectural changes
* AI coding agents
* Anyone needing an accurate mental model of the repository

**Goal:** A reader should obtain a complete, accurate understanding of the current codebase in a single read. This document should describe **what exists**, not what should exist.

### Core Structure

1. **Project Overview:** Overall purpose.
2. **Complete Architecture:** Explain every major subsystem, ownership, responsibilities, and interactions.
3. **Execution Flow:** Describe execution from startup until shutdown (initialization, config loading, runtime behavior, cleanup).
4. **Control Flow:** Describe how control moves through the application.
5. **Source Tree Walkthrough:** Walk through every important directory. For major files, explain why they exist, who uses them, and how they interact (do not merely list filenames).
6. **Module Documentation:** For every important module: responsibility, exported interfaces, dependencies, incoming callers, outgoing calls.
7. **Data Flow:** Explain where data originates, how it moves, where it is transformed, where it is stored, and where it exits.
8. **Internal APIs:** Document important internal interfaces.
9. **Configuration:** Describe every configuration mechanism currently implemented.
10. **Build Pipeline:** Explain exactly how the project is built.
11. **Runtime Model:** Explain threads, processes, event loops, async model, IPC, and networking (only if implemented).
12. **Error Handling:** Describe actual error propagation.
13. **Logging:** Describe logging architecture.
14. **Memory Ownership:** If applicable, explain ownership and lifetime of important objects.
15. **External Dependencies:** Describe why each dependency exists.
16. **Known Limitations:** Only limitations observable from the current implementation. No speculation.

---

# Duplication Policy

The three documents should complement each other instead of repeating one another.

Use this rule:

* **`README.md`** → "How do I use this?"
* **`DEV.md`** → "How does this system behave from a developer's perspective?"
* **`DEV_IN_DEPTH.md`** → "How is this repository actually built internally?"

If a section belongs in one document, summarize it elsewhere in one or two sentences and link the reader to the appropriate document instead of duplicating the content.

---

# Deliverables

Update all three files so that:

* Each has a clearly defined audience.
* There is minimal unnecessary duplication.
* Cross-references are used instead of repeated explanations.
* Every statement is grounded in the current repository.
* The documentation forms a coherent hierarchy from beginner to expert:

```
README.md
   ↓
DEV.md
   ↓
DEV_IN_DEPTH.md
```

* A new user should be able to stop after `README.md`.
* A contributor should be comfortable after reading `README.md` + `DEV.md`.
* A contributor or AI agent should have a complete and accurate mental model after reading all three documents.
