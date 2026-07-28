---
name: release-checklist
description: Produces a release checklist tailored to the actual versioning, changelog, build, and publish process of a repository. Use when a user asks for a release checklist, release process, version bump guide, or publishing steps derived from the project.
---

# Release Checklist

Generate a concrete, project-specific release checklist from the repository’s real scripts, config, and conventions. Do not invent versioning schemes, publish commands, or required steps that are not evidenced in the code or existing docs.

## Mandatory First Steps

1. Walk the repository.
2. Detect the versioning approach:
   - Version files or constants
   - Git tags
   - Changelog format (Keep a Changelog, conventional commits, etc.)
   - Package manifest version fields
3. Locate build, test, and publish scripts (Makefile, package.json scripts, CI jobs, shell scripts, etc.).
4. Identify artifact types (library packages, binaries, containers, documentation sites).
5. Note any existing release documentation or previous release tags for pattern matching.
6. If Git history is available, inspect recent tags and release commits for the actual process used.

## Output File

Write or update `./RELEASE_CHECKLIST.md`.

## Required Sections

### 1. Release Model
- How version numbers are determined and where they live
- Tag naming convention if present
- Branch policy for releases if visible from CI or docs
- Artifact types produced by a release

### 2. Pre-Release Checklist
Ordered steps that must happen before a version is cut, derived only from existing quality gates:
- Tests that are required (from CI or scripts)
- Lint / typecheck / format checks that exist
- Changelog or release-note updates that the project already expects
- Version bump locations (list every file that carries the version)

### 3. Version Bump Steps
Exact files and fields to update, with the project’s own conventions. Include any helper scripts the repository already provides.

### 4. Build & Verify
Commands the repository already uses to produce release artifacts and to verify them. Prefer project scripts over ad-hoc commands.

### 5. Publish / Tag Steps
- How artifacts are published (package registries, container registries, GitHub releases, etc.) as implemented or documented in-repo
- Tag and push sequence if that is the project’s practice
- Any signing, attestation, or provenance steps that exist

### 6. Post-Release
- Downstream notifications or doc updates the repository already performs
- Verification that the published artifact is reachable

### 7. Rollback Notes
Only document rollback or unpublish steps that the project itself describes or that are obvious from the tooling it uses. Do not invent a rollback policy.

### 8. Open Questions
List any part of the release process that could not be determined from the repository.

## Rules

- Every command and file path must exist in the repository or its CI config.
- Prefer quoting the project’s own scripts and make targets over rewriting them.
- If the project uses Changesets, release-please, goreleaser, semantic-release, or similar, document the actual configuration rather than a generic process.
- Cross-link to `CHANGELOG.md`, `CONTRIBUTING.md`, or CI docs instead of duplicating long explanations.
- Never assume a GitHub release, npm publish, or Docker push unless the repository contains evidence for it.
