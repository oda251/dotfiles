# 概要

個人用dotfiles。TUIに注力した。

# 前提

- chezmoi

# 初期化

```bash
chezmoi init --apply https://github.com/<YOUR_USER>/dotfiles.git
```

# パッケージ管理

**Mac/Linux環境**: nix, mise, brew

**Windows環境**: winget

## AIエージェント設定の振り分け

`pre-commit` 実行時に `ai-agent-configs/routes.txt` を読み込み、定義に従って設定ファイルを同期する。

例:

```text
copy|ai-agent-configs/rules/base.md|dot_claude/CLAUDE.md
copy|ai-agent-configs/skills/documentation/SKILL.md|dot_claude/skills/documentation/SKILL.md
```

`rules` と `skills` を分離管理し、各エージェントの所定パスへ配布する。
プロバイダやスキル追加時は `routes.txt` に行を追加するだけでよい。

## mise で管理されるツール

### 全プラットフォーム共通

- fzf, fd, ripgrep, bat, eza, zoxide, starship
- yazi, lazygit, lazydocker, delta
- gh, zellij, neovim, bottom

### Mac/Linux のみ

- node, npm, uv, bun, rust, terraform
- prettier, biome, java

# プラットフォーム対応

## Windows

Windows Terminal + PowerShell

## macOS

Ghostyy + zsh
