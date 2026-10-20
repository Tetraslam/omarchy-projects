# Projects for Omarchy

One key to start working in a project. Press it, type a few letters, Enter, and a new tab opens in your Ghostty window, in that project, running [OpenCode](https://opencode.ai). With no Ghostty window open, you get a new terminal instead.

- Ranked by [zoxide](https://github.com/ajeetdsouza/zoxide), so every `cd` you've ever typed puts your real projects first. Repos under `~/Programming` that zoxide hasn't seen yet are listed after them.
- Each project shows its current branch, so worktrees of one repo read apart.
- Fuzzy matching prefers the project name and word starts.
- Picking a project teaches zoxide, just like a `cd`.
- Your machines are listed too: Tailscale peers (online ones first, phones skipped) and `~/.ssh/config` hosts. Enter opens an SSH session; type `ssh` to show only machines.

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

`omarchy-shell projects toggle` works too. Requires `zoxide`, `python3`, `jq` and `wtype`.

To open projects as tabs in your Ghostty window, add this to `~/.bashrc`:

```bash
[[ -f ~/.config/omarchy/plugins/tetraslam.projects/shell-hook.bash ]] && source ~/.config/omarchy/plugins/tetraslam.projects/shell-hook.bash
```

Ghostty on Linux has no command for opening a tab in an existing window, so the launcher focuses your most recent Ghostty window and presses Ctrl+Shift+T; the new tab's shell picks up the waiting `cd … && opencode` from a private file in `$XDG_RUNTIME_DIR` and runs it, adding it to your history.