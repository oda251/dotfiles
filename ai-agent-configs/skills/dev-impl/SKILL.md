---
name: dev-impl
description: タスクを実装する。TDD 適用はサブエージェントが判断する。
user-invocable: false
---

タスクを実装せよ。

- 対象言語のガイドライン（`~/.claude/references/{lang}.md`, `{lang}-{framework}.md`）があれば従う
- `~/.claude/references/testing-guideline.md` に従う

## TDD 適用判断

`expect(fn(input)).toBe(output)` をテスト前に書けるか？

- **書ける** → テスト先行で実装する。正常系から始めてエッジケースへ進む。1テストケースずつ:
  1. Red: テストを1つ書き、失敗を確認する
  2. Green: テストを通す最小限のコードを書く
  3. 繰り返す（正常系 → 異常系 → 境界値）
- **書けない** → そのまま実装する
