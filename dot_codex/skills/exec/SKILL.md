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

ガイドラインに従って指定フェーズのタスクを実行する。起動時にステータスを `⬜` → `🔵` に更新。タスク完了時に `🔵` → `✅`。

### 3. 次のタスク判断

`~/.claude/references/next-task-guideline.md` に従う。現タスクファイルを起点に判断を開始する。
