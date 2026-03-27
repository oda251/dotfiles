---
name: investigation-review
description: 調査ドキュメントの網羅性をレビューし、不足があれば research-planning に戻す。
user-invocable: false
---

レビュー共通ルールは `~/.claude/references/review-guideline.md` に従う。

## 手順

### 1. レビューの実行

別エージェントを起動し、以下を指示する:

```
以下の調査ドキュメントをレビューせよ。
- ドキュメント: [ファイルパス]
- 調査テーマ: [テーマ]
- 調査の目的: [目的]
- 観点: ~/.claude/references/review-guideline.md の「調査レビュー」に従う
- 問題があれば「不足している情報」を具体的にリストアップすること
```

### 2. レビュー結果の判断

- **十分** → 調査完了。ユーザーにドキュメントを提示する
- **不足あり** → research-planning に戻り、不足分のリソースを追加して再収集する

## 次のスキル

- 十分な場合 → **完了**（チェーン終端）
- 不足がある場合 → **research-planning** に戻る
