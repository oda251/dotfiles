---
name: close-task
description: タスク完了の合図（"完了"/"終わった"/"merged"/"PR closed" など)を受けたら、ローカルリソースの後片付けを行う。
confirm-before-run: false
---

## 目的

タスク終了処理を 1 度にまとめる:

1. 状態確認（uncommitted / unpushed / PR merged / worktree 有無）
2. 懸念点を全てユーザに提示して確認
3. obsidian journal (`AgentLog/`) に 1 行追記
4. worktree 削除（ローカル branch ごと、remote には触らない）

リポジトリ・worktree・PR の **無いもの** は黙ってスキップ。あるものだけ処理する。

---

## フロー

1. 状態収集
2. 状態提示 + `AskUserQuestion` 確認
3. obsidian journal 追記
4. worktree 削除（該当時のみ）
5. 完了報告

---

## 1. 状態収集

```bash
pwd
git rev-parse --is-inside-work-tree 2>/dev/null         # repo 判定
git branch --show-current 2>/dev/null                    # branch 名
git status --porcelain                                   # 未コミット変更
git log @{u}.. --oneline 2>/dev/null                     # 未 push commit（upstream 未設定なら無視）
gwq list -g --json 2>/dev/null                           # 全 worktree
gh pr list --head "$(git branch --show-current)" --state all --json number,state,url,mergedAt 2>/dev/null
```

取れない情報は「該当なし」として扱う（エラーで止めない）。

## 2. 状態提示 + 確認

収集結果を以下フォーマットで提示。**懸念があれば全て列挙**してからユーザに諮る。

```
## タスク終了処理

- branch: <name or "（なし）">
- worktree: <path or "（cwd は worktree 外）">
- PR: <url and state, or "（なし）">
- 未コミット変更: <件数 or なし>
- 未 push commit: <件数 or なし>

## 実行内容
1. AgentLog に 1 行追記
2. worktree 削除（`gwq remove -b <branch>` — ローカル branch も削除、remote は不変）<該当時のみ>
```

`AskUserQuestion` で `はい / 中断` を選ばせる。中断なら即終了。

注意点の **(a) 未コミット変更**, **(b) 未 push commit**, **(c) PR 未 merge or 不在** はそれぞれ独立に提示する（1 つでもあれば必ず明示）。

## 3. obsidian journal 追記

`AgentLog/YYYY-MM-DD.md` に 1 行 append。日次ファイルが無ければ `obsidian create` で作ってから append。

### フォーマット

```
- HH:MM [<org/repo>] [<TOPIC>](<URL>) — <SUMMARY>
```

URL は markdown リンク `[text](url)` 形式。URL が無いときは素の `<TOPIC>` を直書き。`[<org/repo>]` は repo 外なら角括弧ごと省略。

各要素:

| 要素 | 内容 | 省略時 |
|---|---|---|
| `HH:MM` | 現在時刻 | 必須 |
| `[<org/repo>]` | GitHub repo の `owner/name`（`gh repo view --json nameWithOwner` 等から取得） | repo 外なら丸ごと省略 |
| `<TOPIC>` | 優先度: ① issue → ② PR title → ③ branch → ④ 自然言語によるトピック | 必須 |
| `<URL>` | issue / PR の URL（markdown link で TOPIC に貼る） | 無ければ素の TOPIC のみ |
| `<SUMMARY>` | 本セッションでの実作業を踏まえた具体的な 1 行 | 必須 |

TOPIC の解決ルール:

- **issue がある**: `#<num> <issue-title>` を TOPIC に。URL は issue URL
- **PR がある（issue 紐付けなし）**: `<pr-title>` を TOPIC に。URL は PR URL
- **branch のみ**: `<branch-name>` を TOPIC に。URL なし
- **どれもない**: 自然言語でセッションのテーマを 1 句で（例: `hono-auth 比較検討`）

### 例

```markdown
- 14:32 [oda251/dotfiles] [#45 JWT auth ミドルウェア](https://github.com/oda251/dotfiles/issues/45) — 認証フロー実装＋テスト済み
- 14:32 [oda251/dotfiles] [feat: refactor router](https://github.com/oda251/dotfiles/pull/67) — レビュー後マージ
- 14:32 [oda251/dotfiles] feat/local-fix — ローカル検証のみで終了
- 14:32 hono-auth 比較検討 — Bearer middleware が最適と判断
```

### 実行

```bash
date_str=$(date +%Y-%m-%d)
journal="AgentLog/${date_str}.md"
obsidian create vault=obsidian-vault path="$journal" content="" 2>/dev/null || true
obsidian append vault=obsidian-vault path="$journal" \
  content="- $(date +%H:%M) [<org/repo>] [<TOPIC>](<URL>) — <SUMMARY>"
```

サマリは generic 文言（「タスク完了」等）を避け、**本セッションで実際に何をしたか**を書く。

## 4. worktree 削除

cwd が worktree 内ならまず安全な場所へ抜ける。

```bash
cd "$HOME"
gwq remove -b <branch>
```

- `-b` でローカル branch も削除（`git branch -D` 相当）
- remote branch には触れない（push -d などは絶対にしない）
- worktree が無い / cwd が worktree 外 → スキップ

失敗したら出力を転送して中断。手動 `gwq remove` を案内。

## 5. 完了報告

- journal 追記内容（1 行）
- 削除した worktree path（該当時）
- 残った懸念（未 push commit がある等）

---

## ルール

- **remote には一切触らない**（push, push -d, gh pr close 等は禁止）
- repo / worktree / PR が無い構成でも止まらず、**有るものだけ処理**する

## セルフチェック

```
□ 未コミット / 未 push / 未 merge / PR 不在を全て検出して提示したか？
□ AgentLog に **本セッションの実作業を反映した** 1 行を追記したか？
□ 日次ファイルが無いとき create してから append したか？
□ worktree 削除前に cwd を $HOME に戻したか？
```
