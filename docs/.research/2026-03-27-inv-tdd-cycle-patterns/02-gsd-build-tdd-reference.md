---
tags:
  - investigation
  - tdd
  - claude-code
  - skill-chain
  - gsd-build
---
# gsd-build/get-shit-done TDD リファレンス

source: [gsd-build/get-shit-done references/tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)

## サイクル構造

RED → GREEN → REFACTOR の3フェーズを逐次実行する。ドキュメントの記述: "TDD work is fundamentally heavier than standard tasks—it requires 2-3 execution cycles (RED → GREEN → REFACTOR), each with file reads, test runs, and potential debugging."（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）

## ワークフロー詳細

### RED フェーズ

- プロジェクト慣例に従いテストファイルを作成する（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- 期待される振る舞いを記述するテストを書く（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- テスト実行し失敗を確認する（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- コミット: `test({phase}-{plan}): add failing test for [feature]`（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）

### GREEN フェーズ

- テストを通す最小限のコードを書く（最適化なし）（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- テスト実行し通過を確認する（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- コミット: `feat({phase}-{plan}): implement [feature]`（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）

### REFACTOR フェーズ（条件付き）

- 明らかな改善点がある場合のみ実行する（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- テストが通り続けることを確認する（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- 変更があった場合のみコミット: `refactor({phase}-{plan}): clean up [feature]`（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）

## バッチ処理に関するルール

> "One feature per TDD plan. If features are trivial enough to batch, they're trivial enough to skip TDD—use a standard plan and add tests after."

1つの TDD plan に1機能のみ。バッチ処理できるほど些細な機能なら TDD ではなく通常 plan でテスト後付けにする（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）。

## スキルチェーン

外部スキルへのクロスリファレンスは含まれていない（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）。

## 特徴

- 各フェーズごとにコミットメッセージの規約が定められている（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
- TDD は通常タスクより重いことを認めた上で、2-3 実行サイクルを要するタスクとして位置付けている（[tdd.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）
