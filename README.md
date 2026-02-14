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

**Windows環境**: nix, brew, mise は使用せず、Windows Terminal の設定のみ適用されます。必要なツール（zoxide, starship等）は別途インストールが必要です（例: winget, scoop）。

# プラットフォーム対応

## Windows (WSL)

Windows環境ではWSLとWindows Terminalを利用します：

- **Windows Terminal**: Ghostty環境を再現（Tokyo Nightテーマ、フォント設定、透過効果）
- **Zellij**: タブ管理に使用
- **キーバインド**: Windows TerminalからZellijのキーシーケンスを送信（Ctrl+t → `Ctrl-t n`、Ctrl+w → `Ctrl-t x`、Ctrl+Shift+[/] → `Ctrl-t [`/`]`）
- **設定場所**: `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
- **パッケージ管理**: nix, brew, mise は使用せず、必要なツールは手動でインストール

### Windows での追加セットアップ

Windows環境では以下のツールを別途インストールする必要があります：

```powershell
# winget を使用する場合
winget install starship
winget install ajeetdsouza.zoxide

# または scoop を使用する場合  
scoop install starship
scoop install zoxide
```

## macOS

- **Ghostty**: メインターミナル（Zellij連携）
- **Zellij**: タブ管理に使用
- **キーバインド**: GhosttyからZellijのキーシーケンスを送信（Cmd+t → `Ctrl-t n`、Cmd+w → `Ctrl-t x`、Cmd+Shift+[/] → `Ctrl-t [`/`]`）
- **設定場所**: `.config/ghostty/config`, `.config/zellij/config.kdl`
