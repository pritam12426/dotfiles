Check the current git staged diff and generate a detailed commit message.

Rules:
- Follow Conventional Commits format: <type>(<scope>): <subject>
  Types: feat, fix, refactor, docs, style, test, chore, perf, build, ci
- Subject line: imperative mood, no period, ≤72 chars, lowercase after the colon
- Keep the subject line under **72 characters** and use the imperative mood.
- Add a blank line after the subject.
- Write a comprehensive body that explains:

  - What changed.
  - Why the change was made.
  - How it was implemented.
  - Any notable implementation details, edge cases, or tradeoffs.
  - Any user-visible or developer-facing impact.
- Group related changes into clear bullet points where appropriate.
- If multiple files contribute to the same feature or fix, describe them together instead of listing files one by one.
- Do **not** invent motivations or behavior that are not supported by the diff.
- Return **only** the final commit message inside a Markdown code block so it can be pasted directly into `git commit`.
