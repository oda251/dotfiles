---
tags:
  - investigation
  - tdd
  - claude-code
  - skill-chain
---
# Claude Code スキルチェーンにおける TDD サイクル実装パターン

depends-on:
- [obra/superpowers TDD スキル](./01-obra-superpowers-tdd-skill.md)
- [gsd-build TDD リファレンス](./02-gsd-build-tdd-reference.md)
- [aliev チェックポイント型 TDD](./03-aliev-tdd-checkpoint.md)
- [SwiftyJunnos TDD テンプレート](./04-swiftyjunnos-tdd-template.md)
- [TDD Guard](./05-nizar-tdd-guard.md)
- [alexop サブエージェント型 TDD](./06-alexop-subagent-tdd.md)
- [claude-caliper](./07-claude-caliper.md)

## Q1: obra/superpowers は TDD サイクルをどう回しているか

**1テストずつ**の逐次実行。RED → RED検証 → GREEN → GREEN検証 → REFACTOR → Repeat のフローで、各フェーズの検証ステップが必須化されている（[01](./01-obra-superpowers-tdd-skill.md)）。

特徴的なのは RED/GREEN 双方に**検証ゲート**がある点。テストの失敗理由がタイポでなく機能未実装によるものかを確認する RED 検証、全テストスイートの通過とクリーンな出力を確認する GREEN 検証がある（[01](./01-obra-superpowers-tdd-skill.md)）。

スキルチェーンとしては `@testing-anti-patterns.md` を参照しており、モック回避のガイダンスと連携する（[01](./01-obra-superpowers-tdd-skill.md)）。

## Q2: gsd-build/get-shit-done の TDD 実装

RED → GREEN → REFACTOR（条件付き）の3フェーズ。各フェーズごとにコミットメッセージ規約が定められている（[02](./02-gsd-build-tdd-reference.md)）:

- RED: `test({phase}-{plan}): add failing test for [feature]`
- GREEN: `feat({phase}-{plan}): implement [feature]`
- REFACTOR: `refactor({phase}-{plan}): clean up [feature]`

バッチ処理に対して明確なルールがある: "One feature per TDD plan. If features are trivial enough to batch, they're trivial enough to skip TDD." バッチ可能な些細な機能は TDD ではなく通常 plan でテスト後付けにする（[02](./02-gsd-build-tdd-reference.md)）。

TDD を「通常タスクより重い」と正直に認めた上で、2-3 実行サイクルを要するタスクとして位置付けている点が実用的（[02](./02-gsd-build-tdd-reference.md)）。

## Q3: Red-Green サイクルを回す他のリポジトリ

調査した全リポジトリが**1テストずつ**の Red-Green サイクルを採用していた。ただし強制メカニズムが異なる。

### パターン比較

| リポジトリ | 強制方法 | サイクル単位 | 人間介入 | 特徴 |
|-----------|---------|------------|---------|------|
| obra/superpowers | スキル指示 | 1テスト | なし（自動進行） | RED/GREEN 双方に検証ゲート |
| gsd-build | リファレンス文書 | 1機能 | なし | フェーズごとコミット規約 |
| aliev/strict-tdd | スキル指示 | 1テスト | **毎サイクル CHECKPOINT** | REFACTOR を人間判断に置換 |
| SwiftyJunnos | スラッシュコマンド | 1テスト（PLAN.md） | コマンド選択時 | Tidy First 方法論統合 |
| TDD Guard | **Hooks** | 1テスト | なし（機械的ブロック） | 違反を実行前にブロック |
| alexop.dev | **サブエージェント分離** | 1機能 | なし | コンテキスト汚染防止 |
| claude-caliper | サブエージェント + plan.json | タスク単位 | 3回のみ | 13ステップの完全ワークフロー |

### 強制メカニズムの3分類

1. **スキル指示のみ**: obra/superpowers, gsd-build, aliev。Claude の指示遵守に依存する。長いセッションで規律が崩れる可能性がある（[03](./03-aliev-tdd-checkpoint.md)で `/tdd` 再呼び出しが推奨されている）
2. **Hooks による機械的強制**: TDD Guard。ファイル変更をインターセプトし、TDD 違反を実行前にブロックする。スキル指示だけでは不十分な場合の補完（[05](./05-nizar-tdd-guard.md)）
3. **サブエージェント分離**: alexop.dev, claude-caliper。フェーズごとに別エージェントを起動し、コンテキスト汚染を構造的に防止する。最も堅牢だが設定コストが高い（[06](./06-alexop-subagent-tdd.md)）

### 共通する設計判断

- 全リポジトリが「1テスト/1機能ずつ」を原則としている（未検証: バッチ TDD を推奨するリポジトリは今回の調査範囲では見つからなかった）
- GREEN フェーズで「テストを通す最小限のコード」を強調している点が共通
- REFACTOR フェーズは条件付き（改善点がある場合のみ）とするものが多い
