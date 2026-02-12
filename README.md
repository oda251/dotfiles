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
