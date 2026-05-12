---
name: copilot-review
description: GitHub Copilot CLI を呼び出してローカルで PR レビューを行う手動コマンド。PR URL / 番号を引数に取る。
disable-model-invocation: true
argument-hint: <PR-URL or PR-number>
allowed-tools: Bash(copilot *)
---

## 目的

PR bot (Copilot bot, Codex bot 等) の指摘待ちを縮める。push 直後ではなく、push 前に手元で同等のレビューを回す。

## 実行手順

1. `$ARGUMENTS` が空なら、ユーザに PR URL か番号を 1 度だけ尋ねる。返ってこなければ中止。
2. Copilot CLI を起動する。diff は Copilot 自身に `gh pr diff` で取りに行かせる (temp file は使わない)。

   ```bash
   copilot \
     --model gpt-5.3-codex \
     --allow-all \
     --no-ask-user \
     -s \
     -p "$(cat ${CLAUDE_SKILL_DIR}/prompt.md)

   Target PR: $ARGUMENTS"
   ```

3. Copilot の出力をユーザに提示する。findings があれば severity (CRITICAL / HIGH / MEDIUM / LOW) でグルーピング、無ければ 1 行で `LGTM`。

## ルール

- Copilot にはレビュー専念させ、ファイル編集 / commit / push / PR コメント投稿は **絶対にやらせない** (prompt.md 内で明示)
- 結果は stdout に出して終わり。PR / Issue / Slack 等への書き込みはしない
- 本スキル中、Claude 自身は `gh` や `git` を呼ばない。diff 取得は Copilot に任せる
