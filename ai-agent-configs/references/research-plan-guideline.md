# Research 計画ガイドライン

## テーマの明確化

ユーザーの要求から以下を整理する:

- **調査テーマ**: 何を調べるのか
- **調査の目的**: なぜ調べるのか（実装判断、技術選定、現状把握など）
- **必要な粒度**: 概要レベルか、実装詳細レベルか

不明確な場合はユーザーに確認する。推測で進めない。

## タスク分解

調査テーマを観点ごとにタスクとして分解する。gather タスクの後に write タスクを追加する:

```bash
dispatch task add --title "観点1" --type exec-research --depends-on {parent}
dispatch task add --title "観点2" --type exec-research --depends-on {parent}
dispatch task add --title "調査結果を統合ドキュメントにまとめる" --type exec-research-write --depends-on {gather1},{gather2}
```
