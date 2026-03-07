#!/usr/bin/env bash
# Claude Code Hook -> Discord Bot ローカル API への中継スクリプト
# stdin から hook イベント JSON を受け取り、Bot の HTTP API に転送する。
# Bot 未起動時やエラー時は静かに終了する (Claude Code を止めない)。
set -euo pipefail

CLAUDE_BOT_PORT="${CLAUDE_BOT_PORT:-19280}"

INPUT="$(cat)"

# Zellij セッション名を付与 (返信先の特定に使用)
if [[ -n "${ZELLIJ_SESSION_NAME:-}" ]]; then
    INPUT="$(echo "$INPUT" | jq -c --arg zs "$ZELLIJ_SESSION_NAME" '. + {zellij_session: $zs}')"
fi

curl -s -X POST "http://127.0.0.1:${CLAUDE_BOT_PORT}/notify" \
    -H "Content-Type: application/json" \
    -d "$INPUT" \
    --connect-timeout 2 \
    --max-time 5 \
    > /dev/null 2>&1 || true
