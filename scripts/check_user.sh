#!/bin/bash

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_NAME="$(basename "$0")"

found_user=0

if git grep -q '\$USER' ":(exclude)scripts/$SCRIPT_NAME"; then
    echo "警告: \$USER が見つかりました"
    git grep -n '\$USER' ":(exclude)scripts/$SCRIPT_NAME"
    found_user=1
fi

if [ $found_user -eq 1 ]; then
  exit 1
else
  echo "OK: \$USER は含まれていません"
  exit 0
fi
