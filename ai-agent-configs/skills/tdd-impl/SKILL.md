---
name: tdd-impl
description: TDD サイクル（Red-Green）をテストケース単位で繰り返す。
user-invocable: false
---

## 手順

別エージェントを起動し、以下を指示する:

```
以下の振る舞いに対して TDD サイクル（Red-Green）を回せ。
- タスク: [タスク定義]
- 対象ファイル: [ファイルパス]
- ガイドライン:
  - ~/.claude/references/testing-guideline.md に従う
  - 対象言語のガイドライン（~/.claude/references/{lang}.md, {lang}-{framework}.md）があれば従う

正常系から始めてエッジケースへ進む。1テストケースずつ以下を繰り返す:
1. Red: テストを1つ書き、失敗を確認する（タイポではなく機能未実装による失敗であること）
2. Green: テストを通す最小限のコードを書き、全テストスイートが Green であることを確認する
3. 次のテストケースに進み、1-2 を繰り返す（正常系 → 異常系 → 境界値）
```

## 次のスキル

→ **implementation-review** を呼べ。変更ファイル一覧を引き継ぐ。
