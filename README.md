# 概要

個人用dotfiles。TUIに注力した。

# 前提

- chezmoi

# 初期化

```bash
chezmoi init --apply https://github.com/oda251/dotfiles.git
```

# パッケージ管理

**Mac/Linux環境**: nix, mise, brew

**Windows環境**: winget, mise

## mise で管理されるツール

### 全プラットフォーム共通（CLIツール）

- fzf, fd, ripgrep, bat, eza, zoxide, starship
- yazi, lazygit, lazydocker, delta
- gh, zellij, neovim, bottom
- k9s, kubectl, kubectx, kubens

### Mac/Linux のみ（言語ランタイム）

- node, npm, uv, bun, rust, terraform
- prettier, biome, java

# プラットフォーム対応

## Windows

Windows Terminal + PowerShell

## macOS

Ghostyy + zsh