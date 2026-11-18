# chezmoi dotfiles

chezmoi で管理する dotfiles リポジトリ。

## エージェント設定 (dot_agents/)

AI コーディングツール（Claude Code, Codex 等）の共通設定マスタ。

- `dot_agents/AGENTS.md`: 共通エージェント指示マスタ（`~/.agents/AGENTS.md`）
- `dot_agents/exact_skills/`: 共通スキルマスタ（`~/.agents/skills/`）

エージェント共通の指示やスキルを追加・変更する場合は `dot_agents/` 配下で行う。
プロバイダ固有の設定（hooks, settings.json, statusline 等）のみ `dot_claude/` 等の直下で管理する。
