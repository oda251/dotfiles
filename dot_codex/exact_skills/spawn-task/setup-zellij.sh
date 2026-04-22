#!/usr/bin/env bash
# Delegate worktree + zellij tab creation to `wt add`, then drop a task
# prompt into the worktree and launch claude inside the newly focused tab.
#
# Usage:
#   setup-zellij.sh <branch-or-issue-arg> <prompt-file> [permission-mode]
#
# <prompt-file> is the path to the .task-prompt.md source; its contents are
# copied into <worktree>/.task-prompt.md.
set -euo pipefail

BRANCH_ARG="${1:?branch or issue argument required}"
PROMPT_SRC="${2:?prompt source file required}"
MODE="${3:-auto}"

[[ -f "$PROMPT_SRC" ]] || { echo "prompt source not found: $PROMPT_SRC" >&2; exit 1; }
[[ -n "${ZELLIJ:-}" ]] || { echo "not inside a zellij session (ZELLIJ unset)" >&2; exit 1; }
command -v wt >/dev/null 2>&1 || { echo "wt command not found on PATH" >&2; exit 1; }

# `wt add` creates the worktree, opens a new zellij tab, and cd's into it.
# Its last line of stdout is the worktree path.
worktree_dir="$(wt add "$BRANCH_ARG" | tee /dev/stderr | tail -n1)"
[[ -d "$worktree_dir" ]] || { echo "wt add did not produce a valid worktree" >&2; exit 1; }

cp "$PROMPT_SRC" "$worktree_dir/.task-prompt.md"

# The new tab is now focused and the shell has cd'd to the worktree.
# Send the claude launch command there. Use `command claude` to bypass the
# zsh wrapper in alias.zsh.tmpl (which forces --dangerously-skip-permissions
# and --remote-control).
sleep 0.2
zellij action write-chars "command claude --permission-mode ${MODE} '.task-prompt.md を読んで、記載されたタスクを実施してください'"
zellij action write 13  # Enter
