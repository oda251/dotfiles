# pr-diff.yazi

Yazi plugin that highlights files changed in a specific pull request directly
in the file listing — the same way
[`git.yazi`](https://github.com/yazi-rs/plugins/tree/main/git.yazi) marks
`git status` results, but for a PR diff. Driven by an in-yazi prompt, not an
env var.

## Requirements

- Yazi 26.x or newer (`ya.input`, `entry(self, job)` with `job.args`)
- `git` on `$PATH`
- `gh` on `$PATH`, authenticated (`gh auth status`)

## Installation

### Manual

Drop `main.lua` at `~/.config/yazi/plugins/pr-diff.yazi/main.lua`.

### chezmoi (this repo)

Already managed here — running `chezmoi apply` deploys it to
`~/.config/yazi/plugins/pr-diff.yazi/`.

## Configuration

### `init.lua`

```lua
require("pr-diff"):setup({
    order = 1400,
    -- sign = "±",   -- optional, default ±
})
```

`order` controls where the marker is drawn in the linemode. Keep it lower than
`git.yazi`'s order (default `1500`) so the PR marker appears before the git
status marker.

### `keymap.toml`

```toml
[[mgr.prepend_keymap]]
on = [ "g", "p" ]
run = "plugin pr-diff"
desc = "highlight files changed in a PR"
```

Pick any key you like; `g p` (for "git PR") mirrors the `g i` → lazygit
pattern. You can also preset a PR non-interactively:

```toml
[[mgr.prepend_keymap]]
on = [ "g", "P" ]
run = "plugin pr-diff -- 123"
desc = "highlight PR #123"
```

### `theme.toml` (optional)

```toml
[pr_diff]
changed      = { fg = "blue" }
changed_sign = "±"
```

Both keys are optional. Defaults: `fg = "blue"` and sign `±`.

## Usage

1. Launch yazi inside a repo clone (the plugin resolves the repo root by
   walking up from the current directory).
2. Press `g p` (or whichever key you bound).
3. Type the PR number and press Enter. An empty input clears the highlight.

The plugin runs `gh pr diff --name-only <PR>` at the repo root, stores the
result in memory, and re-renders the linemode. Subsequent navigation inside
the same repo keeps the highlight; navigating into a different repo hides it
(state is keyed to the resolved repo root).

## Behavior & limits

- One PR highlighted at a time per yazi process.
- Results are fetched once per invocation and cached in memory; re-trigger
  the hotkey to refresh.
- Directories that contain at least one changed file are also marked.
- Errors from `gh` (e.g. PR not found, not authenticated, network) surface as
  a yazi notification; the previous state is preserved.
