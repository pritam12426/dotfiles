Check the current git diff (staged if present, otherwise unstaged; if neither, diff the last commit against HEAD~1) and generate a commit message.

Rules:
- Follow Conventional Commits format: <type>(<scope>): <subject>
  Types: feat, fix, refactor, docs, style, test, chore, perf, build, ci
- Subject line: imperative mood, no period, ≤72 chars, lowercase after the colon
- Body (only if the change isn't trivially obvious from the subject): explain *why*, not just what — wrap at ~72 chars, separate from subject with a blank line
- If the diff touches multiple unrelated concerns, say so explicitly and suggest splitting into separate commits instead of forcing one message
- Base the message only on what's actually in the diff — don't infer intent that isn't visible in the code changes
- Output just the commit message (and the split-commit note if applicable) — no extra commentary
