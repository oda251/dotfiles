# Dev 計画ガイドライン

## 準備

対象言語・フレームワークに対応するガイドラインが��れば読む:
- `~/.claude/references/{lang}.md`（例: `ts.md`）
- `~/.claude/references/{lang}-{framework}.md`（例: `ts-react.md`）

フレームワークは設定ファイル（next.config, svelte.config, hono 等）から判定する。

## タスク分解

- 変更対象ファイルを列挙する
- ファイル間の依存関係を整理し、並列実行可能な単位に分割する
- 共有するインターフェース（型定義、API 契約等）を先に確定する
- 要件不明確・設計判断が分かれる場合はユーザーに確認。推測で実装しない
- 調査が必要な場合は `plan-research` タスクを先行させる

```bash
dispatch task add --title "認証ライブラリの比較" --type plan-research --depends-on {parent}
dispatch task add --title "ライブラリ導入" --type exec-dev --depends-on {research}
dispatch task add --title "認証 API" --type exec-dev --depends-on {research}
```
