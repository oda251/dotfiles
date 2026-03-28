---
name: plan
description: ワークスペースのゴールに基づきタスクを分解する。dispatch CLI から呼ばれるプロンプトテンプレート。
user-invocable: false
---

## 手順

### 1. ワークスペース情報の確認

プロンプトに含まれるワークスペース情報（背景・ゴール・制約）と先行タスクの成果物を確認する。

### 2. ガイドライン読み込み

プロンプトに含まれるガイドラインに従う。

### 3. タスク分解

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
