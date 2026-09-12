# 常時適用ポリシー

* 常にプロセスの改善点がないか意識しながら進める
* 大きなタスクに取り掛かる前に `~/.references/` の関連ドキュメントを参照する:
  * `policy/` — コーディング規約。`common.md` は常時読む。ほかは対象に応じて: TypeScript → `ts.md`（React はさらに `ts-react.md`）、Python → `python.md`、バックエンド → `backend.md`、テスト → `testing.md`、インフラ → `infra.md`、skill 作成 → `skill.md`、ドキュメント作成 → `documentation.md`
  * `stack/` — 技術選定とアーキテクチャ（`architecture-backend.md` = FC/IS、`architecture-frontend.md` = FSD）。技術選定・設計判断を伴うときに読む
  * `taxonomy/` — docs skill のタグ語彙（`ndc.md` / `ccs.md`）

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
* 取得は `ghq get <url>`、一覧は `ghq list`、ルートは `ghq root`

## gwq

- ローカルのGit Worktreeをまとめて管理するツール
* 作成は `gwq add -b <branch>`、一覧は `gwq list -g`（クロスリポ、`--json` でスクリプト連携）
