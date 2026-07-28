---
name: security-pass
description: Performs a grounded security review of an open-source repository by inspecting real code for common vulnerability patterns. Use when a user asks for a security review, vulnerability scan, threat assessment, or security audit of a codebase.
---

# Security Pass

Perform a read-only security review of the current repository. Report only issues that can be pointed to in existing source files. Do not invent vulnerabilities or claim a clean bill of health beyond what was inspected.

## Mandatory First Steps

1. Walk the repository and identify languages, frameworks, and major components.
2. Locate trust boundaries (HTTP handlers, CLI input, file parsers, deserialization, auth, crypto, subprocess, SQL/NoSQL queries, template rendering, etc.).
3. Inspect configuration and secret handling (env vars, config files, hard-coded credentials).
4. Inspect dependency manifests for known risky patterns only when the risk is visible from the manifest or lockfile itself (do not claim CVE status unless the tool environment provides it).
5. Record the scope of the review (what was examined, what was skipped).

## Output File

Write or update `./SECURITY_REVIEW.md`.

## Required Sections

### 1. Scope
- Languages and frameworks examined
- Entry points and trust boundaries reviewed
- Areas intentionally not covered (e.g. infrastructure-as-code, deployment configs outside the repo, third-party services)

### 2. Findings
For each concrete issue:
- Severity suggestion (Critical / High / Medium / Low / Informational) with a short justification
- File path and relevant symbol or line range
- Description of the observed pattern
- Why it is a concern in this specific codebase
- Suggested direction for a fix (not a full patch unless trivial)

Group findings by category when helpful (injection, authn/authz, secrets, crypto, SSRF, path traversal, etc.).

Only report patterns that are actually present. Absence of a category means “not observed,” not “safe.”

### 3. Positive Observations
Briefly note security-relevant practices that are clearly implemented (parameterized queries, constant-time compares, secure defaults, etc.). Do not invent them.

### 4. Dependency Notes
Summarize anything security-relevant that is visible from manifests and lockfiles (pinned versions, known risky packages by name only, presence or absence of a lockfile). Do not claim up-to-date CVE data unless an external scan was actually run.

### 5. Recommendations Prioritized
A short ordered list of the highest-impact next steps derived from the findings.

### 6. Limitations
Explicitly state that this is a static, repository-only review and cannot replace a full audit, penetration test, or dependency vulnerability database scan.

## Rules

- Every finding must cite a concrete file and location.
- Do not report theoretical issues that have no evidence in the code.
- Do not claim the codebase is “secure” or “insecure” overall.
- Prefer precise language (“user-controlled path reaches `os.Open` without cleaning”) over vague labels.
- If authentication or authorization logic is complex, summarize the observed model and note unclear paths instead of guessing.
- Cross-link to `API.md` or `CODEBASE_MAP.md` when those documents already describe the relevant surfaces.
