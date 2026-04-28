# dotfiles

個人用 dotfiles。`chezmoi` を起点にローカル環境を再現する。

## セットアップ

```bash
chezmoi init --apply https://github.com/oda251/dotfiles.git
```

`chezmoi apply` で `run_once_*` / `run_onchange_*` フックが走り、Homebrew / mise / フォント等を一括導入する。

## 構成

| ディレクトリ | 役割 |
|---|---|
| `ai-agent-configs/` | Claude Code / Codex / Cursor の設定ソース |
| `apps/` | 個人プロジェクト |
| `dot_*/` | chezmoi が配布する dotfiles (直接編集しない) |
| `pulumi/` | GitHub リポジトリ / NewRelic ダッシュボードの IaC |
| `scripts/` | リポジトリ自身の保守スクリプト |
| `exact_dot_references/` | AI エージェントが参照する reference docs (`~/.references`) |
| `run_*.tmpl` | chezmoi の `run_*` フック (パッケージ導入等) |

## 直接使うツール

| ツール | 役割 |
|---|---|
| **chezmoi** | dotfiles 配布の起点 |
| **mise** | 言語ランタイム + CLI ツールの統一管理 |
| **brew** (macOS) / **winget** (Windows) | mise で扱わないアプリ |
| **pulumi** | GitHub repos / NewRelic ダッシュボードの IaC |
| **obsidian** | ドキュメント・作業ログ (`~/obsidian-vault`) |
| **ghq** + **gwq** | git リポ / worktree 管理 |
| **lefthook** | このリポジトリ自身の pre-commit |

## AI エージェント設定

`ai-agent-configs/` を Single Source of Truth とし、`routes.txt` に従って `dot_claude/` (Claude Code) / `dot_codex/` (Codex) / `dot_cursor/` (Cursor) へ配布する。

```text
sync|<src-dir>|<dst-dir>            # ディレクトリ丸ごと同期
copy|<src>|<dst>                    # 単発コピー
concat|<dst>|<src1>|<src2>|...      # 連結して 1 ファイル化
```

配布は `make sync-configs` または pre-commit hook (lefthook) で自動。プロバイダ追加は `routes.txt` に行を足すだけ。

## プラットフォーム

| OS | Terminal + Shell |
|---|---|
| macOS | Ghostty + zsh |
| Linux | (任意) + zsh |
| Windows | Windows Terminal + PowerShell |
