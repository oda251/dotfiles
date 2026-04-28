#!/usr/bin/env bash
# Create a worktree via gwq and launch claude inside a new zellij tab.
#
# Usage:
#   setup-zellij.sh <branch | issue-number | issue-url> <prompt-file> [permission-mode]
#
# Behavior:
#   - issue 番号 / URL の場合 gh+jq で `feat/<num>-<slug>` に変換
#   - ローカル branch を ensure_local_branch で揃えてから `gwq add <branch>` で worktree 作成
#     (basedir は ~/.config/gwq/config.toml で設定済み: ~/gwq)
#   - <prompt-file> を <worktree>/.task-prompt.md にコピー
#   - zellij 新タブ (--cwd は darwin 不安定なので write-chars で cd) を開いて claude を起動
set -euo pipefail

ARG="${1:?branch or issue argument required}"
PROMPT_SRC="${2:?prompt source file required}"
MODE="${3:-auto}"

[[ -f "$PROMPT_SRC" ]] || { echo "prompt source not found: $PROMPT_SRC" >&2; exit 1; }
[[ -n "${ZELLIJ:-}" ]] || { echo "not inside a zellij session (ZELLIJ unset)" >&2; exit 1; }
command -v gwq >/dev/null 2>&1 || { echo "gwq not found on PATH" >&2; exit 1; }
command -v jq >/dev/null 2>&1  || { echo "jq not found on PATH" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git not found on PATH" >&2; exit 1; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "not inside a git repository" >&2; exit 1; }

resolve_branch() {
  local arg="$1"
  if [[ "$arg" =~ ^[0-9]+$ || "$arg" =~ ^https?:// ]]; then
    command -v gh >/dev/null 2>&1 || { echo "gh CLI required to resolve issue" >&2; exit 1; }
    local json number title slug
    json="$(gh issue view "$arg" --json number,title 2>/dev/null)" \
      || { echo "failed to fetch issue '$arg'" >&2; exit 1; }
    number="$(printf '%s' "$json" | jq -r '.number')"
    title="$(printf '%s' "$json" | jq -r '.title')"
    slug="$(printf '%s' "$title" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
    if [[ -n "$slug" ]]; then
      printf 'feat/%s-%s' "$number" "$slug"
    else
      printf 'feat/%s' "$number"
    fi
    return 0
  fi
  printf '%s' "$arg"
}

# ローカル branch を「あるべき start-point」で用意する。優先順位:
#   1. 既存のローカル branch を再利用
#   2. リモートに同名 branch があれば tracking branch として作成 (PR 追従)
#   3. どこにも無ければ origin/HEAD (= default branch) から新規作成
# 呼び出し後は `gwq add <branch>` で worktree 化するだけでよい。
ensure_local_branch() {
  local branch="$1"

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    return 0
  fi

  # remote-tracking ref が無ければ fetch を試行 (オフライン時は無視)
  if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git fetch --quiet origin "$branch" 2>/dev/null || true
  fi

  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git branch --track "$branch" "origin/$branch"
    echo "spawn-task: tracking existing remote branch 'origin/$branch'"
    return 0
  fi

  local default_ref
  default_ref="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/||')"
  default_ref="${default_ref:-origin/main}"
  git fetch --quiet origin "${default_ref#origin/}" 2>/dev/null || true
  git branch "$branch" "$default_ref"
  echo "spawn-task: new branch '$branch' created from $default_ref"
}

BRANCH="$(resolve_branch "$ARG")"
[[ -n "$BRANCH" ]] || { echo "could not resolve branch from '$ARG'" >&2; exit 1; }

# 既存 worktree を再利用 (同じ branch がどこかで checkout 済みならそのパスを使う)
worktree_dir="$(
  git worktree list --porcelain \
    | awk -v b="refs/heads/$BRANCH" '
        $1 == "worktree" { p = $2 }
        $1 == "branch" && $2 == b { print p; exit }
      '
)"

if [[ -n "$worktree_dir" ]]; then
  echo "spawn-task: reusing existing worktree at $worktree_dir"
else
  ensure_local_branch "$BRANCH"
  gwq add "$BRANCH"

  # gwq add は path を直接 stdout しないので list -g --json で解決
  worktree_dir="$(
    gwq list -g --json \
      | jq -r --arg b "$BRANCH" '.[] | select(.branch == $b) | .path' \
      | head -n1
  )"
  [[ -n "$worktree_dir" && -d "$worktree_dir" ]] \
    || { echo "spawn-task: gwq add succeeded but worktree path not found" >&2; exit 1; }
fi

cp "$PROMPT_SRC" "$worktree_dir/.task-prompt.md"

# zellij --cwd は darwin で不安定。write-chars で cd
if [[ "$(uname)" == "Darwin" ]]; then
  zellij action new-tab --name "$BRANCH"
  zellij action write-chars " builtin cd -- $(printf '%q' "$worktree_dir") && clear"
  zellij action write 13  # Enter
else
  zellij action new-tab --name "$BRANCH" --cwd "$worktree_dir"
fi

# 新タブに claude 起動コマンド送信。`command claude` で zsh ラッパを迂回
sleep 0.2
zellij action write-chars "command claude --permission-mode ${MODE} '.task-prompt.md を読んで、記載されたタスクを実施してください'"
zellij action write 13  # Enter

printf '%s\n' "$worktree_dir"
