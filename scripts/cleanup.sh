#!/bin/bash

# ==============================================================================
# 環境クリーンアップスクリプト
# Brewfileに記載されていないパッケージの削除や、不要なキャッシュのクリアを行います。
# ==============================================================================

set -e

# Homebrewのパス設定
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d "$HOME/.linuxbrew" ]]; then
  eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi

echo "🚀 クリーンアップを開始します..."

# 1. Homebrewのクリーンアップ
if command -v brew &> /dev/null; then
  echo "📦 Homebrew: 整理中..."
  
  # Brewfile (通常 ~/.Brewfile) に記載されていないパッケージを削除
  # 注意: dot_Brewfile.tmpl に記載されていないものはすべて削除されます
  echo "   - Brewfileにないパッケージを削除します (bundle cleanup)..."
  brew bundle cleanup --global --force

  # 未使用の依存関係を削除
  echo "   - 不要な依存パッケージを削除します (autoremove)..."
  brew autoremove

  # 古いバージョンの削除とキャッシュクリア
  echo "   - キャッシュと旧バージョンを削除します (cleanup)..."
  brew cleanup
else
  echo "⚠️ Homebrewが見つかりません。スキップします。"
fi

# 2. mise (ツールマネージャー) のクリーンアップ
if command -v mise &> /dev/null; then
  echo "🛠️  mise: 整理中..."
  # 使用されていないツールバージョンを削除
  mise prune --yes
else
  echo "⚠️ miseが見つかりません。スキップします。"
fi

# 3. その他一般的な開発系キャッシュ
echo "🧹 その他のキャッシュ削除..."
if command -v npm &> /dev/null; then
  echo "   - npmキャッシュをクリアしています..."
  npm cache clean --force
fi

echo "✨ 全てのクリーンアップが完了しました！"
