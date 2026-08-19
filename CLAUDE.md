# chezmoi dotfiles

chezmoi で管理する dotfiles リポジトリ。

## ai-agent-configs/

AI コーディングツール（Claude Code, Codex）の共通設定ソース。

エージェント設定の追加・変更はすべて `ai-agent-configs/` 配下で行うこと。配布先（`dot_claude/`, `dot_codex/`）は直接編集しない。

`ai-agent-configs/` への変更は、pre-commit hook が各プロバイダ用ディレクトリへ自動配布して同じ commit に含める。

