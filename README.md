# 概要

個人用dotfiles。TUIに注力した。

# 前提

- chezmoi

# 初期化

```bash
chezmoi init --apply https://github.com/oda251/dotfiles.git
```

# パッケージ管理

CLIツールは `flake.nix` + Home Manager で管理し、GUIアプリ（cask）と `mise` だけ brew に残しています。

# プラットフォーム対応

## Windows (WSL)

Windows環境ではWSLとWindows Terminalを利用します：

- **Windows Terminal**: Ghostty環境を再現（Tokyo Nightテーマ、フォント設定、透過効果）
- **Zellij**: タブ管理に使用
- **設定場所**: `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`

## macOS

- **Ghostty**: メインターミナル（Zellij連携）
- **Zellij**: タブ操作はCmd+t（新規タブ）、Cmd+w（閉じる）、Cmd+Shift+[/]（タブ切替）でGhosttyから制御
- **設定場所**: `.config/ghostty/config`, `.config/zellij/config.kdl`
