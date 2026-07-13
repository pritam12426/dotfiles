Since you mostly live in **main** and **status**, here's what you're leaving on the table — ranked by how much it'd actually help a solo dev day-to-day:

**1. Stage view — biggest missed win**
This is where you do partial/interactive staging. From status view, hit `Enter` on a modified file and it drops you into stage view, showing the diff hunk by hunk. From there:
- `u` stages/unstages the current chunk
- `1` (or `stage-update-line`) stages a *single line*, not the whole hunk
- `s` — the `stage-split-chunk` binding I added — splits a chunk into smaller pieces so you can stage more precisely

This alone replaces `git add -p` and is the single most useful thing tig does that a plain `git status` workflow doesn't give you.

**2. Blame view**
`git tig blame <file>` or hit `b` on a file in tree/status. Even solo, this is how you answer "why is this line like this / when did I write this" without digging through `git log -p`. You've already got a nice `blame-view` config, just start using it.

**3. Tree view**
Browse the repo at any commit (not just the working tree) — press `Enter` on a commit in main view, then navigate into tree. Useful for "what did this file look like 3 commits ago" without checking out anything.

**4. Refs view**
Shows all branches/tags in one place. As a solo dev you probably don't juggle branches much, but it's the fastest way to clean up stale local branches (`d` to delete) instead of `git branch -d` by hand.

**5. Search / grep view**
`/pattern` searches within a view. There's also a dedicated grep view (`git tig grep <pattern>`) that searches file contents across the repo — faster than remembering `git grep` flags.

**6. Stash view**
If you ever `git stash`, tig has a stash view listing them with diff preview on `Enter` — better than `git stash list` + `git stash show -p`.

---

Given your usage pattern, I'd suggest bindings that jump you from status straight into these:

```
bind status b view-blame
bind main t view-tree
bind generic <Ctrl-g> view-grep
```

Want me to fold these into your config file too?



---


Here's a broader set — some are tig features, some are just git habits that pair well with tig's UI:

**Commit hygiene, made easy by tig**
- `bind main F !git commit --fixup %(commit)` — mark a fixup for an earlier commit right from the log, then `git rebase -i --autosquash` folds it in later. Great for "oops, small fix to 3 commits ago" without breaking your history into noise.
- Since you're solo, you can rewrite history freely — use main view + `R` (your existing hard-reset bind) or add a rebase bind: `bind main E !git rebase -i %(commit)^` to interactively edit from the selected commit.

**Undo safety net**
- `bind generic <Ctrl-z> view-log` won't help directly, but knowing `git reflog` is your safety net matters more solo since there's no PR/branch protection catching mistakes. You already have `bind generic W :!git reflog` — actually use it when something feels wrong before panicking.

**Diffing across time**
- In main view, select two commits isn't native to tig, but you can bind a "diff against previous version of this file" — e.g. `bind blame D !git diff %(commit)^ %(commit) -- %(file)` to see exactly what changed in the commit you're blaming.

**.gitignore workflow**
- You already have a custom `tig_add_to_ignore` script bound — good. Pair it with `git status --ignored` occasionally so build artifacts don't sneak into commits.

**Commit message templates**
- Not a tig feature, but works great with tig's workflow: set `git config commit.template ~/.gitmessage` with a short checklist (what changed / why). When you hit `C` to commit from status, it opens your editor with the template pre-filled.

**Autosquash / cleanup before "done"**
- Solo devs often make messy WIP commits then want a clean history before pushing. Bind: `bind main Q !git rebase -i --autosquash origin/%(repo:head)` to squash fixups against what's already pushed.

**Worktrees for parallel work**
- Not tig-specific, but useful solo: `git worktree add ../project-hotfix hotfix-branch` lets you work on two branches in separate folders simultaneously without stashing. Tig can be pointed at either worktree independently.

**Periodic refresh for long sessions**
- If you leave tig open in a split terminal while coding, `set refresh-mode = periodic` + `set refresh-interval = 5` keeps main/status auto-updating as you save files, so you don't need to manually `R`efresh.

Want me to pick the ones that fit your actual habits and merge them into the config, or would you rather try a few manually first and see what sticks?
