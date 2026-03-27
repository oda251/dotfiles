---
name: exec
description: タスクファイルに基づきタスクを消化する。ドメイン固有のガイドラインに従い実行・レビューを回す。
user-invocable: false
---

## 手順

### 1. ドメイン判別とガイドライン読み込み

タスクファイルのファイル名から種別（dev / research）を判別し、対応するガイドラインを読む:
- `dev` → `~/.claude/references/dev-exec-guideline.md`
- `research` → `~/.claude/references/research-exec-guideline.md`

### 2. タスク消化

タスクファイルの現フェーズの未完了タスクを特定し、ガイドラインに従って実行する。

同一フェーズ内のタスクを並列でサブエージェントに委譲する。全タスク完了後、次フェーズがあれば続けて並列起動する。

**タスクファイルの書き換えは plan / after-task のみが行う。exec およびサブエージェントはタスクファイルを変更しない。**

### 4. 完了処理

全フェーズ完了 → **after-task** を呼べ。タスクファイルのパスを引き継ぐ。
