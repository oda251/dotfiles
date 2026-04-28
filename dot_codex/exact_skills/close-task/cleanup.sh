#!/usr/bin/env bash
# Remove a worktree and its local branch via gwq.
#
# Usage: cleanup.sh <branch>
#
# Caller's cwd must NOT be inside the target worktree — invoke from $HOME.
# Remote branches are never touched.
set -euo pipefail

BRANCH="${1:?branch argument required}"
command -v gwq >/dev/null 2>&1 || { echo "gwq not found on PATH" >&2; exit 1; }

gwq remove -b "$BRANCH"
