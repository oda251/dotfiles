# chezmoi dotfiles

chezmoi で管理する dotfiles リポジトリ。

## エージェント設定 (dot_agents/)

AI コーディングツール（Claude Code, Codex 等）の共通設定マスタ。

- `dot_agents/AGENTS.md`: 共通エージェント指示マスタ（`~/.agents/AGENTS.md`）
- `dot_agents/exact_skills/`: 共通スキルマスタ（`~/.agents/skills/`）

各エージェント（`dot_claude/`, `dot_codex/`）はこれらに対してシンボリックリンクを張る構成になっており、エージェント共通の指示やスキルを追加・変更する場合は `dot_agents/` 配下で行う。
Claude Code 固有の設定（hooks, settings.json, statusline 等）は `dot_claude/` 直下で管理する。
