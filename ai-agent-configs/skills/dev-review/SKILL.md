---
name: dev-review
description: 実装とテストをレビューする。サブエージェントが読む実行指示。
user-invocable: false
---

変更をレビューせよ。

- 対象言語のガイドライン（`~/.claude/references/policy/{lang}.md`, `{lang}-{framework}.md`）があれば従う
- テストがある場合: `~/.claude/references/policy/testing.md` に従う
- 問題があれば具体的な修正案を示すこと
