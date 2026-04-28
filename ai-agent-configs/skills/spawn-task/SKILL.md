---
name: spawn-task
description: 実装・ファイル変更を伴うタスク（新機能・バグ修正・リファクタ・issue 対応等）が渡された時に起動し、別セッション（新 worktree + zellij 新タブ + 新規 claude）で作業させる。純粋な質問・調査・閲覧のみのタスクは対象外。
---

## 目的

実装/編集を伴うタスクが来たら、**本セッションで即着手する前に「別セッション化するか？」をユーザに問い直す**。yes なら新 worktree + 新 zellij タブで claude を立ち上げ、no なら skill を抜けて呼び出し側で従来通り作業する。

worktree 管理は `gwq` (basedir = `~/gwq`) に委譲。skill 本体は issue→branch 変換、`.task-prompt.md` 準備、`gwq add` 起動、zellij タブ起動・claude 起動を `setup-zellij.sh` で一括実施する。

## 前提条件

* zellij セッション内（`$ZELLIJ` セット）
* cwd が git リポジトリ内（理想的には `ghq` でクローン済みのリポ — gwq の path テンプレートが `{Host}/{Owner}/{Repo}/{Branch}` で機能するため）
* `gwq` / `gh` / `jq` / `git` 利用可能

いずれか欠けていたら skill を中断。

---

## フロー

1. **最初に** `AskUserQuestion` で「このタスクを別セッションで実行する？」を 1 回だけ聞く。no / スキップを選ばれたら即終了
2. タスク情報収集（issue URL なら `gh issue view` で本文取得、それ以外は指示テキストを整理）
3. ブランチ名を自動決定（issue → `setup-zellij.sh` 内で `feat/<num>-<slug>` 変換、自由テキスト → skill 側で `feat/<slug>` 生成）
4. `.task-prompt.md` を `/tmp/` に書き出す
5. `setup-zellij.sh <branch-arg> <prompt-file> auto` を実行（permission mode は auto 固定）
6. 完了報告して本セッション側は終了

---

## 1. タスク情報収集

### issue URL / issue 番号

`setup-zellij.sh` は issue 番号 / URL を直接受け付ける（内部で `gh issue view --json number,title` で `feat/<num>-<slug>` に変換）：

* `https://github.com/owner/repo/issues/123` → そのまま渡す
* `123` → そのまま渡す

ただし skill 側では本文・ラベル等を `.task-prompt.md` に含めたいので、`gh issue view --json number,title,body,labels,url` で別途取得して整形する。

### 自由テキスト

ユーザの指示テキストからブランチ名を `feat/<slug>` 形式で生成して `setup-zellij.sh feat/<slug>` に渡す。slug は英語 3〜6 単語、kebab-case。

## 2. 起動可否確認（`AskUserQuestion` 1 回・必須）

skill が発動した直後、**何よりも先に**以下を聞く：

* 「このタスクを別セッション（新 worktree + 新 zellij タブ）で実行する？」
* 選択肢：`はい（別セッション）` / `このタブで続ける` / `スキップ（何もしない）`

`このタブで続ける` または `スキップ` を選ばれたら **即 skill を抜ける**。本セッションの claude が通常通り作業を再開する。

ブランチ名・permission mode は ここで一緒に聞かない。自動決定で進める。

## 3. `.task-prompt.md` の中身

```markdown
# <タスクタイトル>

<ソース：issue URL / 自由テキスト の別を明記>

## 内容

<issue 本文 or 自由テキスト>

## 次のアクション

このファイルを読んだら、以下の流れで着手してください：

1. 作業内容と受入れ条件を自分の言葉で整理
2. 関連ファイルを Grep / Glob で探索
3. 実装方針を提示（非自明ならユーザ確認）
4. 実装 → テスト → 報告
```

一時的に `/tmp/spawn-task-<branch>.md` に書き、`setup-zellij.sh` がそれを worktree 内にコピーする。

## 4. `setup-zellij.sh` の呼び出し

```bash
bash "$HOME/.claude/skills/spawn-task/setup-zellij.sh" \
  "<issue-arg-or-branch>" \
  "/tmp/spawn-task-<slug>.md" \
  "<permission_mode>"
```

スクリプト内で以下を実施：

* issue 引数なら `feat/<num>-<slug>` に変換
* 既存 worktree (同 branch) があれば再利用、無ければ以下の優先順で worktree を作成:
  1. ローカル branch が既存 → `gwq add <branch>`
  2. リモート branch のみ存在 (PR 追従等) → `git fetch` で `origin/<branch>` を引き、`git branch --track <branch> origin/<branch>` してから `gwq add <branch>`。**push 時に既存 PR コミットを吹き飛ばさないために必須**
  3. ローカル/リモート共に未存在 → `gwq add -b <branch>` で新規作成し `origin/HEAD` に reset
* `gwq list -g --json` で作成された worktree の path を解決
* `.task-prompt.md` を worktree にコピー
* zellij 新タブを開いて cd（macOS は write-chars 経由）
* 新タブに `command claude --permission-mode <mode> '.task-prompt.md を読んで...'` を送る

`command claude` は zsh 側の `claude` 関数（`--dangerously-skip-permissions --remote-control` を強制）を迂回するため。

## 5. 完了報告

* 作成（または再利用）した worktree のパス
* ブランチ名
* タスクソース要約
* タブを新規作成したこと（フォーカスは zellij 側で自動切替）

---

## gwq の挙動メモ

* worktree 配置: `<basedir>/<host>/<owner>/<repo>/<branch>` (デフォルトテンプレート、basedir = `~/gwq`)
  * 例: `feat/123-fix` の repo `github.com/foo/bar` → `~/gwq/github.com/foo/bar/feat-123-fix/` (`/` は `-` にスラッグ化)
* `gwq list -g`: グローバル (basedir 配下全 worktree) を一覧。`--json` でスクリプト連携可
* `gwq remove <pattern>`: pattern 部分一致で削除。fzf interactive: 引数省略
* `gwq add` 自体は worktree path を stdout しないので、作成後 `gwq list -g --json | jq` で path を引き当てる

## 失敗時の方針

| 失敗箇所 | 対応 |
|---|---|
| zellij 外で実行 | skill 中断、ユーザに案内 |
| `gwq add` 失敗 | エラーを転送して中断（タブは作られていない）|
| worktree path 解決失敗 | エラー報告。gwq list -g で手動確認を案内 |
| `.task-prompt.md` コピー失敗 | worktree は残る。手動でファイル配置を案内 |
| claude 起動失敗 | タブは残る。`.task-prompt.md` のパスを案内 |

## セルフチェック

```
□ zellij セッション内か？
□ 実装/ファイル変更を伴うタスクか？（調査・閲覧のみなら skill 自体を呼ばない）
□ 最初に AskUserQuestion で別セッション化の可否を 1 回聞いたか？
□ no/スキップを選ばれたら即終了したか？
□ ブランチ名・permission mode を追加で聞いていないか？（自動決定・auto 固定）
□ タスクソース（issue / テキスト）を正しく識別したか？
□ issue の場合 issue 本文・ラベルを .task-prompt.md に含めたか？
□ 本セッション側で完了報告したか？
```
