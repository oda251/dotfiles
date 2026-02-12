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

## Nix + Home Manager

- `run_once_after_00_install_nix.sh.tmpl`: Nixの公式 multi-user installer を冪等に実行し、そのまま `home-manager switch` まで行います。
- `run_onchange_after_30_apply_home_manager.sh.tmpl`: `flake.nix` に変更があるたびに `home-manager switch` を再実行します。
- Home Manager が `~/.zshrc` を生成し、そこから `~/.zsh/chezmoi.zshrc`（chezmoi管理）を source します。PATH設定・エイリアス・プラグインはすべて chezmoi 側のファイルに残ります。

Nix がまだ入っていない初回は `chezmoi apply` → シェル再起動 → `chezmoi apply` の2回で完了します。
