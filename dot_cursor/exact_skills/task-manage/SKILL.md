---
name: task-manage
description: "Google Tasks / Calendar でのタスク・予定管理。タスクの追加・確認・完了。「タスク見て」「TODO確認」「タスク追加」「予定入れて」等で起動。"
inputs:
  purpose: 何をしたいか（追加 / 確認 / 完了）
  kind: task / event（省略時は内容から推定）
  content: タスク・予定の内容
---

すべての操作は `gws` コマンドで行う。Tasks API と Calendar API のラッパー。

!`gws tasks --help`
!`gws calendar --help`

## task vs calendar event の使い分け

| | Calendar event | Google Tasks |
|---|---|---|
| 性質 | 特定時刻に拘束される | 完了すべき行動。タイミング柔軟 |
| 例 | 会議、予約、移動、time-block | コードレビュー、買い出し、週報 |
| リカーリング | RRULE で完全制御可 | API 未公開（UI でのみ） |

判断に迷ったら聞く。デフォルトは task。

## tasklist の解決

デフォルトは "マイタスク"（最初の tasklist）:

```bash
TASKLIST_ID=$(gws tasks tasklists list --format json | jq -r '.items[0].id')
```

## 追加

### Tasks に追加

```bash
gws tasks tasks insert \
  --params "{\"tasklist\":\"$TASKLIST_ID\"}" \
  --json '{"title":"<task>","due":"YYYY-MM-DDT00:00:00.000Z","notes":"<details/url>"}'
```

- `title`: 第三者が読んで何をすべきかわかる粒度
- `due`: RFC3339。日付のみ運用なら `T00:00:00.000Z` を付ける（時刻指定は API では保存されるが UI には表示されない仕様）
- `notes`: GitHub URL 等の関連リソース。Markdown は不可、プレーンテキスト

### Calendar event に追加

時刻拘束あり:

```bash
gws calendar +insert \
  --summary "<title>" \
  --start "YYYY-MM-DDTHH:MM:SS+09:00" \
  --end   "YYYY-MM-DDTHH:MM:SS+09:00" \
  --description "<body>"
```

自然言語入力で済むなら quickAdd（"明日 15時 ミーティング" 等）:

```bash
gws calendar events quickAdd --params '{"calendarId":"primary","text":"<natural language>"}'
```

リカーリングは `events insert` の `recurrence` に RRULE を渡す:

```bash
gws calendar events insert --params '{"calendarId":"primary"}' --json '{
  "summary":"週報",
  "start":{"dateTime":"2026-04-27T17:00:00+09:00"},
  "end":{"dateTime":"2026-04-27T17:30:00+09:00"},
  "recurrence":["RRULE:FREQ=WEEKLY;BYDAY=MO"]
}'
```

## 確認

```bash
# 未完了タスク
gws tasks tasks list \
  --params "{\"tasklist\":\"$TASKLIST_ID\",\"showCompleted\":false}" \
  --format table

# 期限が今日までのタスク
gws tasks tasks list \
  --params "{\"tasklist\":\"$TASKLIST_ID\",\"showCompleted\":false,\"dueMax\":\"$(date -u -d 'tomorrow' +%Y-%m-%dT00:00:00.000Z)\"}"

# 今日の予定
gws calendar +agenda --today --format table

# 明日の予定
gws calendar +agenda --tomorrow --format table
```

## 完了

タイトル一致でタスク取得 → patch:

```bash
TASK_ID=$(gws tasks tasks list \
  --params "{\"tasklist\":\"$TASKLIST_ID\",\"showCompleted\":false}" \
  --format json | jq -r '.items[] | select(.title | contains("<keyword>")) | .id' | head -1)

gws tasks tasks patch \
  --params "{\"tasklist\":\"$TASKLIST_ID\",\"task\":\"$TASK_ID\"}" \
  --json '{"status":"completed"}'
```

複数候補が出たらユーザに確認。

## ルール

- リカーリングは Tasks ではなく **Calendar event** で管理する（Tasks API は recurrence 未公開: [Issue #36759725](https://issuetracker.google.com/issues/36759725)）
- 「今日の空き時間にやりたい行動」は Tasks に日付付き（時刻なし）で登録 → Cal の終日エリアに表示される
- 時間ブロックを確保したい行動は Tasks に登録後、Calendar event 化を提案
- 関連リソース（GitHub URL 等）は Tasks の `notes` / Calendar の `description` に
- タスクの粒度は第三者が読んで何をすべきかわかるレベル
