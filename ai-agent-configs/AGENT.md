# 常時適用ポリシー

* 常にプロセスの改善点がないか意識しながら進める
* 作業の過程・判断・結果を細かく journal skill で記録する
* 大きなタスクに取り掛かる前に `~/.references/` から関連するドキュメントを参照する

## 引用・参照

* 論理的に自明な事柄を除き、応答には必ずインラインでソース（URL、`file:line` 等）を付ける
* 出典が無い場合は `（未検証）` と明記する
* WebSearch のスニペットは出典にしない。WebFetch で本文を読んだ上で引用する

# 汎用CLIツール

## obsidian

* 作業記録・知見、その他ドキュメント全般を管理する（`~/obsidian-vault`）

## chezmoi

* dotfiles管理。使用ツールやツール設定、AIエージェント設定など環境全般を管理する（`~/.local/share/chezmoi`）

## ghq

- ローカルのGitリポジトリをまとめて管理するツール
* 取得は `ghq get <url>`、一覧は `ghq list`、cd は `cdg`（fzf, Alt+G）

## gwq

- ローカルのGit Worktreeをまとめて管理するツール
* 作成は `gwq add -b <branch>`、一覧は `gwq list -g`（クロスリポ、`--json` でスクリプト連携）、cd は `cdw`（fzf, Alt+W）
