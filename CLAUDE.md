# chezmoi dotfiles

chezmoi で管理する dotfiles リポジトリ。

## ai-agent-configs/

AI コーディングツール（Claude Code, Codex, Cursor）の共通設定ソース。

エージェント設定の追加・変更はすべて `ai-agent-configs/` 配下で行うこと。配布先（`dot_claude/`, `dot_codex/`, `dot_cursor/` 等）は直接編集しない。

`ai-agent-configs/` の変更は lefthook の pre-commit hook (`distribute-ai-agent-configs`) が各プロバイダ用ディレクトリへ自動同期し、同じ commit に含めて取り込む。配布先ファイルを手動で stage / commit する必要はない。

