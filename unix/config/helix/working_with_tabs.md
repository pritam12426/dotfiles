Quick terminology note first: Helix doesn't have "tabs" the way Vim has tab _pages_ or a browser has tabs. What Helix has is **buffers** (open files) plus an optional **bufferline** — a strip at the top showing open buffers, which is what looks/behaves like tabs. So "working with tabs" in Helix = working with buffers. Here's everything relevant:

## Switching between buffers

| Key        | Command                   | Description                                                            |
| ---------- | ------------------------- | ---------------------------------------------------------------------- |
| `gn`       | `goto_next_buffer`        | Go to next buffer                                                      |
| `gp`       | `goto_previous_buffer`    | Go to previous buffer                                                  |
| `ga`       | `goto_last_accessed_file` | Jump to the last accessed buffer (like an "alternate file" toggle)     |
| `gm`       | `goto_last_modified_file` | Jump to the last modified buffer                                       |
| `<space>b` | `buffer_picker`           | Open a fuzzy picker listing all open buffers                           |
| `<space>'` | `last_picker`             | Reopen the last picker used (handy to bring the buffer picker back up) |

## Closing buffers (typable commands)

| Command                 | Alias                  | Description                              |
| ----------------------- | ---------------------- | ---------------------------------------- |
| `:buffer-close`         | `:bc`, `:bclose`       | Close current buffer                     |
| `:buffer-close!`        | `:bc!`, `:bclose!`     | Force close, discard unsaved changes     |
| `:buffer-close-others`  | `:bco`, `:bcloseother` | Close all buffers except the focused one |
| `:buffer-close-others!` | `:bco!`                | Force version of above                   |
| `:buffer-close-all`     | `:bca`, `:bcloseall`   | Close all buffers (doesn't quit Helix)   |
| `:buffer-close-all!`    | `:bca!`                | Force version of above                   |

## Moving between buffers (typable commands)

| Command            | Alias           | Description  |
| ------------------ | --------------- | ------------ |
| `:buffer-next`     | `:bn`, `:bnext` | Same as `gn` |
| `:buffer-previous` | `:bp`, `:bprev` | Same as `gp` |

## Making the bufferline visible

None of this matters visually unless you enable it:

```toml
[editor]
bufferline = "multiple"   # or "always" / "never" (default)
```

You already have `bufferline = "multiple"` set in your config, so the tab-strip only shows when more than one buffer is open — with one buffer, it stays hidden.

## Related but technically different: splits/windows (`Ctrl-w`)

Not buffers, but often used alongside them — opening the _same or different_ buffers into side-by-side panes:

| Key              | Description               |
| ---------------- | ------------------------- |
| `Ctrl-w v`       | Vertical split            |
| `Ctrl-w s`       | Horizontal split          |
| `Ctrl-w q`       | Close current split       |
| `Ctrl-w o`       | Close all other splits    |
| `Ctrl-w h/j/k/l` | Move focus between splits |
| `Ctrl-w H/J/K/L` | Swap split position       |

No key remapping is needed for any of this — it's all default behavior. If your habit from Vim is `gt`/`gT` for tab pages, the honest mapping is: use `gn`/`gp` for buffers, and `Ctrl-w` splits if you want the side-by-side "multiple things visible at once" behavior instead.
