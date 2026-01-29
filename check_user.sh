#!/bin/bash

# 同階層のすべてのファイルを探索し、$USERが含まれていないかチェック

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

found_user=0

for file in "$SCRIPT_DIR"/*; do
  # ディレクトリとこのスクリプト自身はスキップ
  if [ -d "$file" ] || [ "$(basename "$file")" = "$SCRIPT_NAME" ]; then
    continue
  fi

  if grep -q '\$USER' "$file" 2>/dev/null; then
    echo "警告: \$USER が見つかりました: $file"
    grep -n '\$USER' "$file"
    echo ""
    found_user=1
  fi
done

if [ $found_user -eq 1 ]; then
  exit 1
else
  echo "OK: \$USER は含まれていません"
  exit 0
fi
