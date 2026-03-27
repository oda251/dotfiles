---
tags:
  - investigation
  - tdd
  - claude-code
  - subagent
  - workflow
---
# nikhilsitaram/claude-caliper: 13ステップ自動化ワークフロー

source: [nikhilsitaram/claude-caliper](https://github.com/nikhilsitaram/claude-caliper)

## 概要

11個のスキルをインストールし、設計からPRマージまでの13ステップワークフローを自動化する。人間の判断は3回のみ（[README](https://github.com/nikhilsitaram/claude-caliper)）。

## TDD の強制方法

タスクごとに RED-GREEN-REFACTOR サイクルを逐次実行する（[README](https://github.com/nikhilsitaram/claude-caliper)）:

> "RED: Write test expecting 429 after 10 requests in 1 minute → Run: `npm test -- --grep "rate limit"` → expect FAIL"

タスク markdown に正確なファイルパスと検証コマンドを含むステップバイステップの TDD 指示が記載される。実装サブエージェントはこれらのサイクルを逐次的に実行する必要がある（[README](https://github.com/nikhilsitaram/claude-caliper)）。

## 開発サイクル（13ステップ）

1. ユーザーが機能を記述する（[README](https://github.com/nikhilsitaram/claude-caliper)）
2. Claude が 2-3 の設計アプローチを提案する（[README](https://github.com/nikhilsitaram/claude-caliper)）
3. **ユーザーが設計を承認**（判断 #1）（[README](https://github.com/nikhilsitaram/claude-caliper)）
4. フレッシュなサブエージェントが 8 ポイントチェックリストで設計を検証する（[README](https://github.com/nikhilsitaram/claude-caliper)）
5. フレッシュなサブエージェントがファイルパス付きの実行計画を作成する（[README](https://github.com/nikhilsitaram/claude-caliper)）
6. フレッシュなサブエージェントが計画の曖昧さとドリフトをレビューする（[README](https://github.com/nikhilsitaram/claude-caliper)）
7. オーケストレーターがタスクごとに並列実装サブエージェントを起動する（[README](https://github.com/nikhilsitaram/claude-caliper)）
8. タスクごとのレビュアー（フレッシュエージェント）が各タスクを検証する（[README](https://github.com/nikhilsitaram/claude-caliper)）
9. 実装レビューがクロスタスクの全体パスを行う（[README](https://github.com/nikhilsitaram/claude-caliper)）
10. PR が自動作成される（[README](https://github.com/nikhilsitaram/claude-caliper)）
11. **ユーザーが PR をレビュー**（判断 #2）（[README](https://github.com/nikhilsitaram/claude-caliper)）
12. フレッシュなサブエージェントが外部バイアスなしに diff をレビューする（[README](https://github.com/nikhilsitaram/claude-caliper)）
13. **ユーザーがマージ**（判断 #3）（[README](https://github.com/nikhilsitaram/claude-caliper)）

ステップ 3-9 は無人で実行される（[README](https://github.com/nikhilsitaram/claude-caliper)）。

## サブエージェント分離

"The task reviewer never wrote the code it's reviewing" — レビューにはフレッシュなサブエージェントを使用し、合理化バイアスを防止する（[README](https://github.com/nikhilsitaram/claude-caliper)）。

## 計画構造

`plan.json` にファイルセット、検証コマンド、依存グラフを含む機械可読なタスク仕様が格納される（[README](https://github.com/nikhilsitaram/claude-caliper)）。
