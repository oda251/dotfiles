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

```bash
# 調査してから実装
dispatch task add --ws {ws_id} --title "認証パターン調査" --type plan-research --depends-on {parent_task_id}
dispatch task add --ws {ws_id} --title "認証API実装" --type exec-dev --depends-on {research_task_id}
```
