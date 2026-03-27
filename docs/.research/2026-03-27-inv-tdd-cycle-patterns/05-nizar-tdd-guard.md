---
tags:
  - investigation
  - tdd
  - claude-code
  - hooks
  - enforcement
---
# TDD Guard: Hooks による TDD 強制

source: [TDD Guard for Claude Code - Nizar's Blog](https://nizar.se/tdd-guard-for-claude-code/)

## メカニズム

Claude Code Hooks を利用して TDD 原則を強制する。"Hooks automatically execute commands based on predefined conditions, such as before or after an agent's action, making them ideal for enforcing coding standards."（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）

## 検出する違反

ファイル変更をインターセプトし、以下の3つの違反を検証する（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）:

1. 関連する failing test なしに機能を実装すること
2. テストを通すのに必要以上の機能を実装すること
3. **一度に複数のテストを追加すること**

## ワークフロー

1. Hook がすべてのファイル変更を実行前にインターセプトする（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）
2. バリデータが hook イベントデータ、エージェントの TODO リスト、最新テスト出力を組み合わせる（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）
3. 別の Claude Code セッションが TDD 準拠を検証する（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）
4. 違反があればアクションをブロックし、問題点と修正ガイダンスを含むフィードバックを返す（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）
5. 違反がなければ処理を通す（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）

## 実装の特徴

- Hook フェーズ間のコンテキスト共有にファイルベースの永続化を使用する。プロセス間通信ではなくファイルを介して状態を共有する（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）
- 操作タイプ（Write, Edit, MultiEdit）に応じて動的に指示モジュールを組み立てる（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）

## 意義

スキルの指示だけでは Claude が TDD 規律を維持しきれない問題に対し、Hook による機械的な強制で「1テストずつ」を担保するアプローチ（[nizar.se](https://nizar.se/tdd-guard-for-claude-code/)）。
