---
name: close-task
description: タスク完了の合図（"完了"/"終わった"/"merged"/"PR closed" など)を受けたら、ローカルリソースの後片付けを行う。
confirm-before-run: false
---

## 目的

タスク終了処理を 1 度にまとめる:

1. 状態確認（`collect.sh`）
2. 状態提示 + `AskUserQuestion` 確認
3. Daily ノート (`Daily/<date>.md`) の末尾に 1 行追記
4. worktree 削除（`cleanup.sh` — ローカル branch ごと、remote には触らない）

無いものは黙ってスキップ。あるものだけ処理する。

---

## フロー

### 1. 状態収集

```bash
bash "$HOME/.claude/skills/close-task/collect.sh"
```

JSON 1 オブジェクトを stdout に出す:

```json
{
  "cwd": "...",
  "in_repo": true,
  "branch": "feat/foo",
  "dirty_count": 0,
  "unpushed_count": 0,
  "worktree_path": "/Users/.../gwq/.../feat-foo",
  "repo_nwo": "owner/repo",
  "pr": { "number": 12, "state": "MERGED", "url": "...", "mergedAt": "...", "title": "..." }
}
```

`in_repo=false` / `branch=""` / `worktree_path=""` / `repo_nwo=""` / `pr=null` は「無い」を意味する。エラーで止まらず、有るものだけ処理する。

### 2. 状態提示 + 確認

```
## タスク終了処理

- branch: <name or "（なし）">
- worktree: <path or "（cwd は worktree 外）">
- PR: <url and state, or "（なし）">
- 未コミット変更: <件数 or なし>
- 未 push commit: <件数 or なし>

## 実行内容
1. Daily ノートに 1 行追記
2. worktree 削除（`cleanup.sh <branch>` — ローカル branch も削除、remote は不変）<該当時のみ>
```

`AskUserQuestion` で `はい / 中断` を選ばせる。中断なら即終了。

(a) 未コミット変更, (b) 未 push commit, (c) PR 未 merge or 不在 はそれぞれ独立に提示する（1 つでもあれば必ず明示）。

### 3. Daily ノート追記

本セッションで実際に行ったことを `Daily/<date>.md` の末尾に 1 行残す。Daily ノートが無ければ `daily` テンプレから作成する（`append-journal.sh` が処理）。

#### フォーマット

```
- HH:MM [<org/repo>] [<TOPIC>](<URL>) — <SUMMARY>
```

URL は markdown リンク `[text](url)` 形式。URL が無いときは素の `<TOPIC>` を直書き。`[<org/repo>]` は repo 外なら角括弧ごと省略。

| 要素 | 内容 | 省略時 |
|---|---|---|
| `HH:MM` | 現在時刻 | script が自動付与 |
| `[<org/repo>]` | `repo_nwo` | repo 外なら丸ごと省略 |
| `<TOPIC>` | 優先度: ① issue → ② PR title → ③ branch → ④ 自然言語によるトピック | 必須 |
| `<URL>` | issue / PR の URL（markdown link で TOPIC に貼る） | 無ければ素の TOPIC のみ |
| `<SUMMARY>` | 本セッションでの実作業を踏まえた具体的な 1 行 | 必須 |

TOPIC の解決ルール:

- **issue がある**: `#<num> <issue-title>` を TOPIC に。URL は issue URL
- **PR がある（issue 紐付けなし）**: `<pr-title>` を TOPIC に。URL は PR URL
- **branch のみ**: `<branch-name>` を TOPIC に。URL なし
- **どれもない**: 自然言語でセッションのテーマを 1 句で（例: `hono-auth 比較検討`）

#### 例

```markdown
- 14:32 [oda251/dotfiles] [#45 JWT auth ミドルウェア](https://github.com/oda251/dotfiles/issues/45) — 認証フロー実装＋テスト済み
- 14:32 [oda251/dotfiles] [feat: refactor router](https://github.com/oda251/dotfiles/pull/67) — レビュー後マージ
- 14:32 [oda251/dotfiles] feat/local-fix — ローカル検証のみで終了
- 14:32 hono-auth 比較検討 — Bearer middleware が最適と判断
```

#### 実行

時刻プレフィックスより後ろの本文を作って `append-journal.sh` に渡す:

```bash
bash "$HOME/.claude/skills/close-task/append-journal.sh" \
  "[<org/repo>] [<TOPIC>](<URL>) — <SUMMARY>"
```

サマリは generic 文言（「タスク完了」等）を避け、**本セッションで実際に何をしたか**を書く。

### 4. worktree 削除

cwd が worktree 内なら **先に `$HOME` へ抜ける**（同一プロセスで cd してから script を呼ぶ）。

```bash
cd "$HOME"
bash "$HOME/.claude/skills/close-task/cleanup.sh" "<branch>"
```

`worktree_path` が空 / cwd が worktree 外なら **このステップ自体を省略**。

失敗したら出力を転送して中断。手動 `gwq remove` を案内。

### 5. 完了報告

- journal 追記内容（1 行）
- 削除した worktree path（該当時）
- 残った懸念（未 push commit がある等）

---

## ルール

- **remote には一切触らない**（push, push -d, gh pr close 等は禁止）
- repo / worktree / PR が無い構成でも止まらず、**有るものだけ処理**する

## セルフチェック

```
□ collect.sh の出力を踏まえて未コミット / 未 push / 未 merge / PR 不在を全て検出して提示したか？
□ Daily ノートに **本セッションの実作業を反映した** 1 行を追記したか？
□ Daily ノートが無いとき daily テンプレから create してから append したか？
□ worktree 削除前に cwd を $HOME に戻したか？
```
