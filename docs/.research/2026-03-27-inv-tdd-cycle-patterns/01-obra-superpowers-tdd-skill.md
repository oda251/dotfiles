---
tags:
  - investigation
  - tdd
  - claude-code
  - skill-chain
  - obra-superpowers
---
# obra/superpowers TDD スキル

source: [obra/superpowers skills/test-driven-development/SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)

## サイクル構造

**1テストずつ**の逐次実行方式。1つの振る舞いに対して failing test を書き、pass させ、次へ進む（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）。

## ワークフロー詳細

### RED フェーズ

- 望む振る舞いを示す最小のテストを1つ書く（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- 要件: 単一の振る舞い、明確な命名、実コード使用（モックは不可避な場合のみ）（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）

### RED 検証（必須）

- テストを実行し失敗を確認する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- 失敗メッセージが想定通りか検証する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- タイポではなく機能未実装による失敗であることを確認する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- テストが通った場合は機能が既に存在するのでテストを修正する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- テストがエラーになった場合はエラーを解消し再実行する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）

### GREEN フェーズ

- テストを通す最もシンプルなコードを書く（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- 機能追加、無関係なリファクタリング、過剰設計を禁止。原則は "Just enough to pass"（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）

### GREEN 検証（必須）

- テストが通ることを確認する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- 他のテストも全て通ることを確認する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- 出力がクリーン（エラー/警告なし）であることを確認する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- テストが失敗した場合はコードを修正する（テストではなく）（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）

### REFACTOR フェーズ

- GREEN 達成後のみ実行する（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- 重複除去、命名改善、ヘルパー抽出を行う（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）
- リファクタリング中もテストを GREEN に保つ（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）

## スキルチェーン

- `@testing-anti-patterns.md` を参照している。モックの落とし穴やテスト専用プロダクションメソッドの回避に関するガイダンス（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）

## 基本原則

> "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"

テスト前に書かれたコードは削除し、テストファーストで書き直す必要がある（[SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）。
