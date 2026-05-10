#!/usr/bin/env bash
# Append a single line to today's AgentLog journal in obsidian-vault.
#
# Usage: append-journal.sh "<body>"
#
# `<body>` は markdown 1 行（時刻プレフィックスは script が付ける）。
# 例: append-journal.sh "[owner/repo] [#45 タイトル](https://...) — 実作業要約"
# 例: append-journal.sh "feat/foo — ローカル検証のみで終了"
set -euo pipefail

BODY="${1:?body argument required}"
command -v obsidian >/dev/null 2>&1 || { echo "obsidian CLI not found on PATH" >&2; exit 1; }

journal="AgentLog/$(date +%Y-%m-%d).md"
line="- $(date +%H:%M) ${BODY}"

# 日次ファイルが無ければ作る (既存なら create が失敗するので無視)
obsidian create vault=obsidian-vault path="$journal" content="" >/dev/null 2>&1 || true
obsidian append vault=obsidian-vault path="$journal" content="$line"
