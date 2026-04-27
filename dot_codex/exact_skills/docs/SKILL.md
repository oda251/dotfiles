---
name: docs
description: "Obsidian ドキュメント作成・更新。調査・比較検討・草案など、ドキュメント自体が成果物になる作業で使う。"
inputs:
  content: ドキュメント本文
---

対象 vault: `obsidian-vault`

すべての vault 操作は `obsidian` コマンドで行う。ファイルシステムへの直書き禁止。

!`obsidian --help`

## ドキュメント作成・更新

ドキュメントの内容については `~/.references/policy/documentation.md` に必ず従うこと。

複雑な内容（コードブロック、特殊文字等）は一時ファイルに書いてから渡す:

```bash
cat > /tmp/doc.md << 'EOF'
{本文}
EOF
obsidian create vault=obsidian-vault path="{path}" content="$(cat /tmp/doc.md)"
```

### パス規約

```
{org}/note/{date}-{title}.md   # GitHub repoに紐づく作業
note/{date}-{title}.md          # repoに紐づかない
```

ドキュメントはすべて `note/` 配下に置く（調査・ミーティング・意思決定、別所投稿予定の下書き等を区別しない）。

- `date` = `YYYY-MM-DD`
- `title` = kebab-case。第三者が見て題材と目的がわかる粒度で書く（例: `hono-auth-middleware-comparison`）
- `{org}` = GitHub owner（`git remote get-url origin` から抽出。不明なら repo-less 形式）

### タグ

nested tag を活用する。ルートは以下から選ぶ。子要素は自由。

必須:

- `purpose/*` — 目的（`purpose/research`, `purpose/meeting`, `purpose/decision` 等）
- `topic/*` — トピック

該当時:

- `repo/*` — リポジトリ紐付き（`repo/{org}/{repo}`）
- `tech/*` — 技術領域（`tech/typescript`, `tech/terraform` 等）

### 関連ドキュメント

依存・関連ドキュメントは本文内に `[[path/to/doc]]` で wikilink を張る。Obsidian のバックリンクで辿れる。

## ルール

- 作成・更新したファイルは `obsidian open vault=obsidian-vault path="{path}"` で開けることをユーザーに伝える
