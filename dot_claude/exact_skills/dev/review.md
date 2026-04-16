---
description: 実装内容をレビューし、品質を検証する
internal: true
inputs:
  changes: レビュー対象の変更内容
  criteria: レビュー観点
---

- 対象言語のガイドライン
  （`~/.claude/references/policy/{lang}.md`,
  `{lang}-{framework}.md`）があれば従う
- テストがある場合:
  `~/.claude/references/policy/testing.md` に従う
- 問題があれば具体的な修正案を示すこと
