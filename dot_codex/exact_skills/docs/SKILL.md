---
name: docs
description: "Obsidian ドキュメント作成・更新。調査・比較検討・草案など、ドキュメント自体が成果物になる作業で使う。"
inputs:
  content: ドキュメント本文
---

対象 vault: `obsidian-vault`。

!`obsidian --help`

## ドキュメント作成・更新

ドキュメントの内容は `~/.references/policy/documentation.md` に従う。

複雑な内容（コードブロック、特殊文字等）は一時ファイルに書いてから渡す。作成時は `open` を付与する:

```bash
cat > /tmp/doc.md << 'EOF'
{本文}
EOF
obsidian create vault=obsidian-vault path="{path}" content="$(cat /tmp/doc.md)" open
```

### パス規約

```
{org}/note/{date}-{title}.md   # GitHub repoに紐づく作業
note/{date}-{title}.md          # repoに紐づかない
```

ドキュメントは種類で区別せず、すべて `note/` 配下に置く。

- `date` = `YYYY-MM-DD`
- `title` = kebab-case。題材と目的がわかる粒度（例: `hono-auth-middleware-comparison`）
- `{org}` = `git remote get-url origin` から抽出。不明なら repo-less

### タグ

frontmatter に必ずタグを付ける。タグ体系（必須タグ・条件付きタグ・分野分類・記入例）: `references/tags.md`

### 関連ドキュメント

依存・関連ドキュメントは本文内に `[[path/to/doc]]` で wikilink を張る。
