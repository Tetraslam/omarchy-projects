# Projects for Omarchy

One key to start working in a project. Press it, type a few letters, Enter, and a terminal opens in that project running [OpenCode](https://opencode.ai).

- Ranked by [zoxide](https://github.com/ajeetdsouza/zoxide), so every `cd` you've ever typed puts your real projects first. Repos under `~/Programming` that zoxide hasn't seen yet are listed after them.
- Each project shows its current branch, so worktrees of one repo read apart.
- Fuzzy matching prefers the project name and word starts.
- Picking a project teaches zoxide, just like a `cd`.

| Key | |
|---|---|
| Enter | Terminal running `opencode` (exit it and you're in a shell there) |
| Shift+Enter | Plain terminal in the project |
| Ctrl+Enter | Terminal with `$EDITOR` open on the project |
| ↑/↓, Ctrl+J/K, Tab | Move |
| Esc | Close |

## Install

```bash
omarchy plugin add https://github.com/tetraslam/omarchy-projects --enable
```

Bind it in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + R", "Projects", hl.dsp.global("projects:toggle"))
```

`omarchy-shell projects toggle` works too. Requires `zoxide` and `python3`.

## License

MIT
