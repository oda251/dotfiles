---
tags:
  - investigation
  - tdd
  - claude-code
  - subagent
  - skill-chain
  - hooks
---
# alexop.dev: サブエージェント分離型 TDD

source: [Forcing Claude Code to TDD: An Agentic Red-Green-Refactor Loop](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)

## 問題意識

Claude Code はデフォルトで実装ファーストになり、エッジケースと TDD 原則を無視する。単一コンテキストで TDD を試みると、実装の詳細がテストロジックに「にじむ」コンテキスト汚染が発生する（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）。

## アーキテクチャ

3つのコンポーネントで構成される（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）:

### Skills（`.claude/skills/tdd-integration/skill.md`）

高レベルのオーケストレーション。3フェーズのワークフローを定義し、各フェーズ完了まで次に進めないゲートを設ける（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）。

### Subagents（`.claude/agents/`）

各フェーズに特化した独立ワーカー（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）:

- `tdd-test-writer`: RED フェーズ担当。失敗する統合テストを書く
- `tdd-implementer`: GREEN フェーズ担当。テストを通す最小実装を書く
- `tdd-refactorer`: REFACTOR フェーズ担当。コードを評価し改善する

### Hooks（`.claude/hooks/user-prompt-skill-eval.ts`）

ライフサイクルへのインジェクション。スキルの起動率を約20%から約84%に向上させる（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）。

## サブエージェント分離の意義

各エージェントが完全に分離して動作し、コンテキスト汚染を防ぐ（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）:

- テストライターは実装計画を見れない（テストが実際の要件を反映する）
- 実装者は失敗するテストのみ見る
- リファクタラーは実装の経緯なしにクリーンなコードを評価する

## サイクルプロセス

### Phase 1: RED

テストライターが `createTestApp()` ヘルパーを使って失敗する統合テストを作成し、失敗を確認してから次へ進む（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）。

### Phase 2: GREEN

実装者がテストのアサーションを満たす最小コードを書き、テスト通過を確認する（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）。

### Phase 3: REFACTOR

チェックリスト（composable の抽出、条件の簡素化、命名改善、重複除去）に照らして評価し、改善を適用するか "no refactoring needed" を確認する（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）。

## 実例: Workout Detail 機能

"implement workout detail view" のリクエストに対し（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）:

1. 詳細ビューへのナビゲーションを検証する失敗テストを生成
2. コンポーネント、ルート変更、ナビゲーションハンドラの3ファイルを作成
3. 再利用可能な composable と共有フォーマッタを抽出

各機能が完全なサイクルを完了してから次の機能に進む。

## 導入コスト

設定に約2時間。その後はフィーチャーリクエストに対して自動的に Red-Green-Refactor が強制される（[alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)）。
