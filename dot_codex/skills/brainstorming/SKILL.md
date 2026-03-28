---
name: brainstorming
description: 「Xを作りたい」「Xを実装して」など構築・設計タスクで使う。対話で要件を引き出し、設計方針を合意してから実装に進む。要件が曖昧なとき、設計判断が必要なときは必ず使うこと。
---

## 手順

### 1. 要件の確認

ユーザーの要求からゴール・制約・スコープが明確か判断する。

- **明確** → 対話をスキップし、ステップ 2 へ
- **曖昧** → 思考パートナーとして対話する:
  - まず動機を聞く（何を達成したいか、なぜか）
  - エネルギーがある方向に掘り下げる
  - 曖昧さには具体例で返す
  - 一度に多くを聞かない。1つずつ質問する
  - 選択肢がある場合は具体的な選択肢を提示する
  - ユーザーが方針を承認してから次に進む。推測で進めない

### 2. ワークスペース作成

dispatch CLI でワークスペースを作成する:

```bash
dispatch ws create \
  --title "JWT認証移行" \
  --background "既存のセッション認証からJWTに移行したい" \
  --goal "JWT ベースの認証 API" \
  --goal "既存セッションとの並行稼働期間" \
  --constraint "Express + TypeScript" \
  --constraint "connect-redis は残す"
```

### 3. 初期タスク追加

ドメインを判断し、plan タスクを1つ追加する:
- 実装・構築 → `plan-dev`
- 調査・比較・技術選定 → `plan-research`

```bash
dispatch task add --ws {ws_id} --title "ゴールの達成" --type plan-dev
```

### 4. 実行開始

```bash
dispatch run --ws {ws_id}
```
