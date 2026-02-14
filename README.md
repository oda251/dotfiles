# 概要

個人用dotfiles。TUIに注力した。

# 前提

- chezmoi

# 初期化

```bash
chezmoi init --apply https://github.com/oda251/dotfiles.git
```

# パッケージ管理

**Mac/Linux環境**: CLIツールは `flake.nix` + Home Manager で管理し、GUIアプリ（cask）と `mise` だけ brew に残しています。

**Windows環境**: `mise` を使用してCLIツールを管理します（言語ランタイムは除外）。nix と brew は使用しません。

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

Windows環境ではWindows Terminal + PowerShellを利用します：

- **Windows Terminal**: Tokyo Nightテーマ、フォント設定、透過効果
- **PowerShell**: mise、zoxide、starship を統合
- **Zellij**: タブ管理に使用
- **キーバインド**: Windows TerminalからZellijのキーシーケンスを送信（Ctrl+t → `Ctrl-t n`、Ctrl+w → `Ctrl-t x`、Ctrl+Shift+[/] → `Ctrl-t [`/`]`）
- **設定場所**: 
  - Windows Terminal: `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
  - PowerShell: `Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- **パッケージ管理**: mise（CLIツールのみ）

### Windows でのセットアップ

1. mise をインストール:
```powershell
# winget を使用
winget install jdx.mise

# または scoop を使用
scoop install mise
```

2. chezmoi を初期化して設定を適用:
```powershell
chezmoi init --apply https://github.com/oda251/dotfiles.git
```

3. mise でCLIツールをインストール:
```powershell
mise install
```

## Windows (WSL)

WSL環境ではLinux版の設定が適用されます（Nix + Home Manager + mise）。

## macOS

- **Ghostty**: メインターミナル（Zellij連携）
- **Zellij**: タブ管理に使用
- **キーバインド**: GhosttyからZellijのキーシーケンスを送信（Cmd+t → `Ctrl-t n`、Cmd+w → `Ctrl-t x`、Cmd+Shift+[/] → `Ctrl-t [`/`]`）
- **設定場所**: `.config/ghostty/config`, `.config/zellij/config.kdl`
