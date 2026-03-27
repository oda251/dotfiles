---
name: setup-impl
description: セットアップタスクを実行する。サブエージェントが読む実行指示。
user-invocable: false
---

指示されたセットアップタスクを実行せよ。

- 対象言語のガイドライン（`~/.claude/references/{lang}.md`, `{lang}-{framework}.md`）があれば従う
- 並列実装時は、共有リソース（同一ファイルへの同時書き込み等）の競合を避ける
