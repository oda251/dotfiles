#!/usr/bin/env bash
# Emit close-task state as a single JSON object.
#
# Output schema:
#   {
#     "cwd": str,
#     "in_repo": bool,
#     "branch": str,            # "" if detached / outside
#     "dirty_count": int,       # working tree porcelain entries
#     "unpushed_count": int,    # commits ahead of @{u}; 0 if no upstream
#     "worktree_path": str,     # gwq-managed worktree root if cwd is inside one
#     "repo_nwo": str,          # "owner/name" via gh; "" if unavailable
#     "pr": object|null         # first PR for current branch, null if none
#   }
set -euo pipefail

cwd="$(pwd)"
in_repo=false
branch=""
dirty_count=0
unpushed_count=0
worktree_path=""
repo_nwo=""
pr_json="null"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  in_repo=true
  branch="$(git branch --show-current 2>/dev/null || true)"
  dirty_count="$(git status --porcelain 2>/dev/null | awk 'END{print NR}')"
  if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    unpushed_count="$(git rev-list --count '@{u}..' 2>/dev/null || echo 0)"
  fi

  toplevel="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$toplevel" && -n "$branch" ]] && command -v gwq >/dev/null 2>&1; then
    candidate="$(gwq get "$branch" 2>/dev/null || true)"
    [[ "$candidate" == "$toplevel" ]] && worktree_path="$toplevel"
  fi

  if command -v gh >/dev/null 2>&1; then
    repo_nwo="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
    if [[ -n "$branch" ]]; then
      pr_json="$(gh pr list --head "$branch" --state all --limit 1 \
        --json number,state,url,mergedAt,title \
        --jq 'first // null' 2>/dev/null || echo null)"
    fi
  fi
fi

jq -n \
  --arg cwd "$cwd" \
  --argjson in_repo "$in_repo" \
  --arg branch "$branch" \
  --argjson dirty_count "${dirty_count:-0}" \
  --argjson unpushed_count "${unpushed_count:-0}" \
  --arg worktree_path "$worktree_path" \
  --arg repo_nwo "$repo_nwo" \
  --argjson pr "${pr_json:-null}" \
  '{
    cwd: $cwd,
    in_repo: $in_repo,
    branch: $branch,
    dirty_count: $dirty_count,
    unpushed_count: $unpushed_count,
    worktree_path: $worktree_path,
    repo_nwo: $repo_nwo,
    pr: $pr
  }'
