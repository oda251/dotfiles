---
name: plan
description: ワークスペースのゴールに基づきタスクを分解する。dispatch CLI から呼ばれるプロンプトテンプレート。
user-invocable: false
task-types: [plan-dev, plan-research]
---

## 手順

### 1. ワークスペース情報の確認

プロンプトに含まれるワークスペース情報（背景・ゴール・制約）と先行タスクの成果物を確認する。

### 2. タスク分解

ゴールを達成するためのタスクを分解し、dispatch CLI でタスクを追加する。

`plan-{X}` が追加できるタスクタイプ:
- `plan-*`（任意のドメインへの計画委譲。自ドメイン含む）
- `exec-{X}`（自ドメインの実行のみ。他ドメインの exec は書けない）

`--depends-on` で依存関係を指定する。ルートタスク以外は必ず依存先がある。

### タスクタイトルの書き方

タスクタイトルは実装者がそれだけ読んで何をすべきか理解できる粒度で書く。

```bash
# NG: 曖昧
dispatch task add --title "認証" --type exec-dev ...
dispatch task add --title "調査" --type exec-research ...

# NG: ワークスペースのゴールをそのまま書いただけ
dispatch task add --title "認証APIを作る" --type exec-dev ...

# OK: 何をどうするか、成果物が想像できる
dispatch task add --title "JWT / Session / OAuth の認証方式比較（Express + TS 環境での推奨ライブラリ含む）" --type plan-research --depends-on {parent}
dispatch task add --title "認証ミドルウェア実装（JWT 検証 + リフレッシュトークンローテーション）" --type exec-dev --depends-on {research}
dispatch task add --title "認証 API エンドポイント実装（POST /auth/login, POST /auth/refresh, DELETE /auth/logout）" --type exec-dev --depends-on {middleware}
```

## plan-dev 固有

- 技術選定・ライブラリ追加を伴う場合は `~/.claude/references/setup/` を参照する
- 対象言語・フレームワークに対応するガイドラインがあれば読む:
  - `~/.claude/references/{lang}.md`（例: `ts.md`）
  - `~/.claude/references/{lang}-{framework}.md`（例: `ts-react.md`）
  - フレームワークは設定ファイル（next.config, svelte.config, hono 等）から判定する
- 変更対象ファイルを列挙する
- ファイル間の依存関係を整理し、並列実行可能な単位に分割する
- 共有するインターフェース（型定義、API 契約等）を先に確定する
- 要件不明確・設計判断が分かれる場合はユーザーに確認。推測で実装しない
- 調査が必要な場合は `plan-research` タスクを先行させる

## plan-research 固有

ユーザーの要求から以下を整理する:

- **調査テーマ**: 何を調べるのか
- **調査の目的**: なぜ調べるのか（実装判断、技術選定、現状把握など）
- **必要な粒度**: 概要レベルか、実装詳細レベルか

不明確な場合はユーザーに確認する。推測で進めない。

調査テーマを観点ごとにタスクとして分解する。gather タスクの後に write タスクを追加する:

```bash
dispatch task add --title "観点1" --type exec-research --depends-on {parent}
dispatch task add --title "観点2" --type exec-research --depends-on {parent}
dispatch task add --title "調査結果を統合ドキュメントにまとめる" --type exec-research-write --depends-on {gather1},{gather2}
```
