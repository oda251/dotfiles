---
name: spawn-task
description: 実装・ファイル変更を伴うタスク（新機能・バグ修正・リファクタ・issue 対応等）が渡された時に毎回候補として起動。別セッション（新 worktree + zellij 新タブ）で処理するかを confirm-before-run で都度ユーザに打診する。ユーザが「このタブで進める」「スキップ」を選んだら発動しない。純粋な質問・調査・閲覧のみのタスクは対象外。
confirm-before-run: true
---

## 目的

実装/編集を伴うタスクが来たら、**本セッションで即着手する前に「別セッション化するか？」をユーザに問い直す**。yes なら新 worktree + 新 zellij タブで claude を立ち上げ、no なら skill を抜けて呼び出し側で従来通り作業する。

worktree/タブ管理は PATH 上の `workspace` コマンド（`~/.local/bin/workspace`）に委譲し、skill 本体はタスクプロンプトの準備と claude 起動だけを担う。

## 前提条件

* zellij セッション内（`$ZELLIJ` セット）
* cwd が git リポジトリ内
* `gh` / `jq` / `git` 利用可能

いずれか欠けていたら skill を中断。

---

## フロー

`confirm-before-run: true` により **skill 本体が走る前にユーザが yes/no を選ぶ**。yes でここから下が実行される想定。

1. タスク情報収集
2. ブランチ名/issue 引数の決定
3. 細部確認（ブランチ名の妥当性 + permission mode）を `AskUserQuestion` で 1 回だけ
4. `.task-prompt.md` を `/tmp/` に書き出す
5. `setup-zellij.sh <branch-arg> <prompt-file> <mode>` を実行
6. 完了報告して本セッション側は終了

---

## 1. タスク情報収集

### issue URL / issue 番号

`workspace add` 自体が issue を受け付けるのでそのまま渡せばよい：

* `https://github.com/owner/repo/issues/123` → `workspace add https://...`
* `123` → `workspace add 123`

ブランチ名は `feat/<number>-<english-slug>` に自動変換される。
skill 側では `gh issue view --json number,title,body,labels,url` で **本文・ラベル等** を取得して `.task-prompt.md` に含める。

### 自由テキスト

ユーザの指示テキストからブランチ名を `feat/<slug>` 形式で生成して `workspace add <slug>` に渡す。slug は英語 3〜6単語、kebab-case。

## 2. 細部確認（`AskUserQuestion` 1 回）

skill 起動の可否は `confirm-before-run` で既に済んでいる。ここでは **実行ディテールのみ** を確認する：

* 生成したブランチ名で問題ないか（編集可能なよう候補提示）
* permission mode（デフォルト `auto`、他 `plan` / `acceptEdits` / `default`）

ここで追加の「本当に spawn する？」を二重に聞かない。ユーザが編集したいのは枝葉の値だけ。

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

* `workspace add` で worktree 作成 + zellij 新タブ作成 + cd（macOS の zellij `--cwd` 問題は workspace 側で吸収）
* `.task-prompt.md` を worktree にコピー
* 新タブに `command claude --permission-mode <mode> '.task-prompt.md を読んで...'` を送る

`command claude` は zsh 側の `claude` 関数（`--dangerously-skip-permissions --remote-control` を強制）を迂回するため。

## 5. 完了報告

* 作成（または再利用）した worktree のパス
* ブランチ名
* タスクソース要約
* タブを新規作成したこと（フォーカスは workspace add によって自動で切り替わっている）

---

## workspace コマンドの仕様（抜粋）

skill 内から直接使う箇所だけ：

* `workspace add <branch|issue-num|issue-url> [--base <ref>]`
  * issue の場合 `feat/<num>-<slug>` に変換
  * `~/.worktree/<repo>/<branch>/` に作成
  * base 未指定なら `origin/HEAD`
  * 既存 worktree があれば再利用
  * zellij 新タブを開き cd（macOS workaround込み）
  * stdout 最終行 = worktree 絶対パス

詳細は `workspace --help`。

## 失敗時の方針

| 失敗箇所 | 対応 |
|---|---|
| zellij 外で実行 | skill 中断、ユーザに案内 |
| `workspace add` 失敗 | エラーを転送して中断（タブは作られていない）|
| `.task-prompt.md` コピー失敗 | worktree は残る。手動でファイル配置を案内 |
| claude 起動失敗 | タブは残る。`.task-prompt.md` のパスを案内 |

## セルフチェック

```
□ zellij セッション内か？
□ 実装/ファイル変更を伴うタスクか？（調査・閲覧のみなら skill 自体を呼ばない）
□ タスクソース（issue / テキスト）を正しく識別したか？
□ issue の場合 issue 本文・ラベルを .task-prompt.md に含めたか？
□ ブランチ名と permission mode を AskUserQuestion で確認したか？
□ permission mode の既定は auto か？
□ 本セッション側で完了報告したか？
```
