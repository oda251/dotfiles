# 常時適用ポリシー

- タスクに取り掛かる前に `~/.references/` の関連ドキュメントを参照する
  - `policy/` — 常に参照する規約。`common.md` は常時読む。その他、タスクに関連し得るものは必ず読む
  - `stack/` — 技術選定。プロジェクト構築時に読む

## 引用・参照

- 論理的に自明な事柄を除き、応答には必ずインラインでソース（URL、`file:line` 等）を付ける
- 出典が無い場合は `（未検証）` と明記する
- WebSearch のスニペットは出典にしない。WebFetch で本文を読んだ上で引用する

# 汎用CLIツール

## chezmoi

- dotfiles管理。使用ツールやツール設定、AIエージェント設定など環境全般を管理する（`~/.local/share/chezmoi`）

## openurl

- `openurl <http(s)-URL>` はOS既定のブラウザーを開く（WSLではホストWindows）

## ghq

- ローカルのGitリポジトリをまとめて管理するツール

* 取得は `ghq get <url>`、一覧は `ghq list`、ルートは `ghq root`

## gwq

- ローカルのGit Worktreeをまとめて管理するツール

* 作成は `gwq add -b <branch>`、一覧は `gwq list -g`（クロスリポ、`--json` でスクリプト連携）

@RTK.md
