---
name: exec
description: 指定されたフェーズのタスクを消化する。ドメイン固有のガイドラインに従い実行・レビューを回す。
user-invocable: false
---

## 手順

### 1. ドメイン判別とガイドライン読み込み

引き継がれたタスクファイルとフェーズ番号から、対象フェーズの見出し（`exec-dev` / `exec-research`）を読み取り、対応するガイドラインを読む:
- `exec-dev` → `~/.claude/references/dev-exec-guideline.md`
- `exec-research` → `~/.claude/references/research-exec-guideline.md`

### 2. タスク消化

**exec は自分で実作業をしない。必ずサブエージェントに委譲する。** WebSearch, WebFetch, Edit, Write 等を exec 自身が直接使ってはならない。ガイドラインで指定されたスキルをサブエージェントに渡し、サブエージェントが作業する。

ガイドラインに従って指定フェーズのタスクを実行する。タスク完了時に `🔵` → `✅` に更新。

## 次のスキル

→ **dispatch** を呼べ。タスクファイルのパスを引き継ぐ。
