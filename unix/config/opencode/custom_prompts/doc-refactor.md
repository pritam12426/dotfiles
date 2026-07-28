# Documentation Refactoring Task

Maintain three docs — `README.md`, `DEV.md`, `DEV_IN_DEPTH.md` — so they always reflect the **current HEAD** of the repo, with zero unnecessary duplication.

## Process (in order)

1. **Check existence.** If any file is missing: crawl the whole repo, build a full understanding, generate it. No placeholders — every statement must derive from actual source code.
2. **Check for Git.** Not a repo → document from current state only. Is a repo → continue.
3. **Find prior doc revision.** For each existing doc file, find the last commit that modified it, diff that commit against HEAD, and identify what's now outdated: added/removed/renamed files, API/behavior/build/config/dependency/execution-flow/architecture changes.
4. **Incremental rewrite.** Don't regenerate blindly — keep sections still correct, update only what changed, remove obsolete content, document new behavior, keep terminology consistent across all three files.

## Global Rules

- Read the entire repo before writing anything.
- Every statement must be traceable to current HEAD — no invented features, APIs, architecture, or future plans.
- Use Git history only to find what's stale, not to document removed behavior.
- Minimize cross-file duplication: if a topic belongs in one doc, give it 1–2 summary sentences elsewhere + a link, don't repeat it.
- Markdown; use Mermaid diagrams where they aid understanding.
- If something can't be determined from the code, say so explicitly — don't guess.

## README.md — for new users/evaluators ("How do I use this?")
Cover: what it is, why it exists, problem solved, main features, install, quickstart, basic usage, common commands, config overview, platform support, high-level build instructions, example workflow, screenshots if available, license, brief contributing (link out).
Avoid: architecture, implementation details, source tree, internal protocols, deep API docs, design rationale. Link to `DEV.md` for depth.

## DEV.md — for contributors/API consumers ("How does it behave as a developer?")
- **Architecture overview**: major components, responsibilities, data flow, request lifecycle, module interactions.
- **Build system**: process, dev workflow, key scripts, generated files.
- **Server docs**: every endpoint — method, path, purpose, request/response format, status codes, auth, side effects.
- **Client behavior**: request flow, retries, error handling, timeouts, streaming.
- **Concurrency**: behavior under many clients, rapid-fire/duplicate requests, long-running requests. Document only what's actually implemented (rate limiting, queuing, locking, worker pools) — explicitly state "not implemented" where absent.
- **Repo layout**: high-level directory purposes, not a file-by-file list.
- **Dev guidelines**: existing coding conventions, logging, error handling, testing, debugging.
Link to `DEV_IN_DEPTH.md` for implementation details.

## DEV_IN_DEPTH.md — for new contributors/architects/AI agents ("How is this actually built?")
Single-read source of complete, accurate mental model of what exists (not what should exist):
1. Project overview
2. Complete architecture (every subsystem, ownership, responsibilities, interactions)
3. Execution flow (startup → shutdown: init, config load, runtime, cleanup)
4. Control flow
5. Source tree walkthrough (major dirs/files — why they exist, who uses them, how they interact; not just a listing)
6. Module docs (responsibility, exported interfaces, dependencies, callers, outgoing calls) for every important module
7. Data flow (origin → transform → storage → exit)
8. Internal APIs
9. Configuration mechanisms
10. Build pipeline
11. Runtime model (threads/processes/event loop/async/IPC/networking — only if implemented)
12. Error propagation
13. Logging architecture
14. Memory ownership/object lifetimes (if applicable)
15. External dependencies (why each exists)
16. Known limitations (only what's observable in current code, no speculation)

## Duplication Policy
- `README.md` = how to use it
- `DEV.md` = how it behaves
- `DEV_IN_DEPTH.md` = how it's built internally

Summarize + link instead of repeating. A new user stops at README. A contributor is comfortable after README + DEV. A contributor/agent gets the full picture only after all three.
