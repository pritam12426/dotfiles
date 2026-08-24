---
name: api-surface
description: Extracts the real public API surface of a repository including HTTP endpoints, CLI commands, exported symbols, and library interfaces. Use when a user asks for API documentation, endpoint list, public interface, or CLI reference derived from code.
---

# API Surface

Produce an accurate inventory of every public interface the repository currently exposes. Do not invent endpoints, flags, or exports.

## Mandatory First Steps

1. Walk the entire repository.
2. Identify the project type (library, CLI, HTTP service, hybrid, monorepo, etc.).
3. Locate all public boundaries:
   - HTTP/RPC route registrations
   - CLI command and flag definitions
   - Exported symbols (language-specific public/exported items)
   - Plugin or extension points if they exist
4. Read the actual registration and export sites. Do not rely on comments alone.
5. Note authentication, versioning, and content-type constraints only when they appear in code.

## Output File

Write or update `./docs/API.md` (or a path the user specifies).

## Required Sections

### 1. Surface Summary
- What kinds of public interfaces exist (HTTP, CLI, library, etc.).
- Versioning scheme if present in code or config.
- Authentication or authorization model if implemented.

### 2. HTTP / RPC Endpoints (if any)
For each endpoint found in code:
- Method(s)
- Path or route pattern
- Handler location (file + symbol)
- Request shape (body, query, headers) as implemented
- Response shape and status codes as implemented
- Auth requirements if present
- Side effects (writes, external calls) when obvious from the handler

Group by router or module. Do not invent routes.

### 3. CLI Interface (if any)
For each command and subcommand:
- Full command path
- Flags and arguments with types and defaults as defined in code
- Purpose derived from implementation
- Exit behavior when visible

### 4. Library / Package Exports (if any)
List the public symbols that external consumers are expected to use:
- Language-appropriate visibility (exported functions, classes, types, constants)
- Module path
- Brief responsibility grounded in the implementation
- Important type signatures when they are part of the contract

Omit internal helpers that are not exported or are clearly package-private.

### 5. Other Public Boundaries
Document any additional surfaces that exist (WebSocket endpoints, plugin APIs, environment-variable contracts, config file schemas, etc.) only when the code clearly exposes them.

### 6. Stability Notes
Only record stability or deprecation markers that exist in the source (annotations, comments that are part of the public contract, version gates). Do not invent a stability policy.

### 7. Gaps & Unclear Areas
List interfaces whose exact contract could not be fully determined from the code.

## Rules

- Prefer machine-checkable facts (route tables, command definitions, export lists) over prose comments.
- When multiple languages or packages exist, keep sections clearly separated.
- Cross-link to `./docs/DEV.md` or `./docs/DEV_IN_DEPTH.md` for deeper handler implementation details.
- Never document removed or commented-out endpoints as live.
- If the repository already maintains OpenAPI, JSON Schema, or similar, reference those files and only supplement what is missing or inconsistent.
