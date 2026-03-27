---
tags:
  - investigation
  - tdd
  - claude-code
  - human-in-the-loop
---
# aliev/strict-tdd-skill: Human-in-the-Loop チェックポイント型 TDD

source: [aliev gist - Strict TDD skill for Claude Code](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)

## サイクル構造

RED → GREEN → CHECKPOINT のループ。REFACTOR フェーズを自動化せず、人間のチェックポイントに置き換えている（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）。

サイクル全体: `RED → GREEN → CHECKPOINT → (human decides) → RED → ...`（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）

## ワークフロー詳細

### Phase 1: RED（失敗するテスト）

- Claude が公開 API のみを使用して失敗するテストを1つ書く（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）
- この段階ではプロダクションコードは作成しない（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）

### Phase 2: GREEN（最小実装）

- テストを通すのに必要な最小限のコードを実装する（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）
- シンプルさを優先し、抽象化や一般化を避ける（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）

### Phase 3: CHECKPOINT（人間の制御ポイント）

- Claude が以下を報告して**停止して待機する**（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）:
  - 追加したテスト
  - 実装の詳細
  - テストスイートの状態
- 人間が次のアクションを決定する（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）:
  - リファクタリングと設計改善を要求
  - git コミットを要求
  - 手動でコード編集
  - 次の RED フェーズへの続行を指示

明示的に: "Do NOT proceed to the next test until the human says so."（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）

## 設計思想

- 抽象化は偶発的ではなく対話を通じて意図的に生まれる（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）
- 人間が次のサイクル前にすべての振る舞い変更をコントロールする（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）
- チェックポイントでアーキテクチャの議論が自然に発生する（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）
- TDD の規律の強制に焦点を当てており、TDD 自体の教育ではない（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）

## 運用上の注意

- 長いセッションでは `/tdd` を再呼び出しして規律を維持する（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）
- コスメティックな変更はチェックポイントとは独立して扱う（[gist](https://gist.github.com/aliev/3f402f7a2b84febe65da4910aab6a97c)）
