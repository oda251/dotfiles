# dotfiles

個人用 dotfiles。`chezmoi` を起点に WSL / macOS 環境を一括で再現する。

## セットアップ

どちらの OS でも入口は同じワンライナー。chezmoi 本体を standalone バイナリとして `~/.local/bin` に取得し、そのまま `init --apply` まで走らせる。

```bash
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply oda251
```

これ 1 本で **chezmoi → Homebrew → mise → 各種パッケージ** が芋づる式に入る。chezmoi を先に単体で立てるのが要点で、brew を事前に入れる必要はない（brew は chezmoi の初回 apply の `run_once_before_00` が導入する）。`~/.Brewfile` や mise の設定は chezmoi が配布する dotfile なので、chezmoi は brew/mise の下流ではなく**起点**にあたる。

初回は現在のシェルの `PATH` に `~/.local/bin` が無いと 2 回目以降の `chezmoi` が見つからないことがある。zsh へログインし直せば `PATH` に入る。

途中で `sudo` を求められる（ログインシェル変更・`apt`・`/etc/wsl.conf` 書き換え）。

### macOS

前提: なし。初回は Xcode Command Line Tools と Homebrew の導入を促される。

1. 上のワンライナーを実行
2. Brewfile から `ghostty` / `google-chrome` / フォント（cask）と `mise` 等（formula）が入る
3. ログインシェルが zsh に変わる（再ログインで反映）

### WSL (Ubuntu)

前提: WSL2 + Ubuntu（systemd 有効を推奨）、`curl`。

1. 上のワンライナーを実行
2. Homebrew (linuxbrew) → `apt` で zsh・ビルド依存・Obsidian・fcitx5 → mise ツールが入る
3. `/etc/wsl.conf` に `appendWindowsPath = false` が追記される
4. Windows 側で `wsl --shutdown` してから再起動し、interop 設定と zsh ログインシェルを反映

素の Linux（非 WSL）も同じワンライナーで動く。fcitx5 / `wsl.conf` 関連の手順だけスキップされる。

## 更新

```bash
chezmoi update    # リポジトリを pull して apply
chezmoi upgrade   # chezmoi 本体（standalone バイナリ）を自己更新
```
