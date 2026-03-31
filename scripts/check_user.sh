#!/bin/bash

SCRIPT_NAME="$(basename "$0")"

user_value="${USER:-}"
if [[ -z "$user_value" ]]; then
  echo "エラー: USER が空です" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
matches="$(grep -rn --include='*' -F "$user_value" "$repo_root" --exclude="scripts/$SCRIPT_NAME" --exclude-dir='.git' || true)"
if [[ -n "$matches" ]]; then
  echo "エラー: USER の値 ($user_value) が含まれています"
  echo "$matches"
  exit 1
fi

echo "OK: USER の値は含まれていません"
exit 0
