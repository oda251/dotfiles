#!/bin/bash

SCRIPT_NAME="$(basename "$0")"

user_value="${USER:-}"
if [[ -z "$user_value" ]]; then
  echo "エラー: USER が空です" >&2
  exit 1
fi

if git grep -q -F "$user_value" ":(exclude)scripts/$SCRIPT_NAME"; then
  echo "エラー: USER の値 ($user_value) が含まれています"
  git grep -n -F "$user_value" ":(exclude)scripts/$SCRIPT_NAME"
  exit 1
fi

echo "OK: USER の値は含まれていません"
exit 0
