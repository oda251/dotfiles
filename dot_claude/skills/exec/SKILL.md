---
name: exec
description: 指定されたフェーズのタスクを消化する。ドメイン固有のガイドラインに従い実行・レビューを回す。
user-invocable: false
---

タスク管理は `~/.claude/references/task-management-guideline.md` に従う。

## 手順

### 1. ドメイン判別とガイドライン読み込み

引き継がれたタスクファイルとフェーズ番号から、対象フェーズの見出し（`exec-dev` / `exec-research`）を読み取り、対応するガイドラインを読む:
- `exec-dev` → `~/.claude/references/dev-exec-guideline.md`
- `exec-research` → `~/.claude/references/research-exec-guideline.md`

### 2. タスク消化

ガイドラインに従って指定フェーズのタスクを実行する。

### 3. ステータス更新と次のタスク判断

task-management-guideline に従い、ステータスを更新し、次のタスクを判断する。
