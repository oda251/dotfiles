---
description: 確定した仕様に基づきコードを実装する
inputs:
  what: 何を実装するか
  where: どのファイル/モジュールに
  spec: 準拠する仕様やインターフェース
confirm-before-run: true
next: review
---

- 対象言語のガイドライン
  （`~/.claude/references/policy/{lang}.md`,
  `{lang}-{framework}.md`）があれば従う
- `~/.claude/references/policy/testing.md` に従う
- ライブラリ追加・プロジェクト初期設定など技術選定を伴う場合は
  `~/.claude/references/setup/` を参照する

## TDD 適用判断

`expect(fn(input)).toBe(output)` をテスト前に書けるか？

- **書ける** → テスト先行で実装する。
  正常系から始めてエッジケースへ進む。1テストケースずつ:
  1. Red: テストを1つ書き、失敗を確認する
  2. Green: テストを通す最小限のコードを書く
  3. 繰り返す（正常系 → 異常系 → 境界値）
- **書けない** → そのまま実装する
