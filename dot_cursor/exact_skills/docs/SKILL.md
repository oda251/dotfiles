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

必須:

- `purpose/*` — 目的（`purpose/research`, `purpose/meeting`, `purpose/decision`, `purpose/comparison`, `purpose/draft` 等）

該当時:

- `tech/*` — 技術関連ノート。具体ツール（`tech/hono`）と概念（`tech/async`）の両方を拾う
- `repo/*` — リポジトリ紐付き（`repo/{org}/{repo}`）

永続知財として横断検索に乗せたい場合（長期参照する調査結果など）はさらに分野分類タグを付ける。流れていく系（draft・意思決定ログ・ミーティングメモ等）は不要:

- `ndc/*` — 汎用分野分類。語彙: `~/.references/taxonomy/ndc.md`
- `ccs/*` — 計算機分野の領域分類。語彙: `~/.references/taxonomy/ccs.md`

`ccs/*` は計算機分野、`ndc/*` は汎用知識、`tech/*` は実体（ツール+概念）。

例: Hono の認証ミドルウェア比較ノートを永続化する場合

```yaml
tags:
  - purpose/research
  - purpose/comparison
  - tech/hono
  - tech/typescript
  - tech/middleware
  - tech/authentication
  - ccs/security
  - ccs/software
  - ndc/007
  - ndc/548
```

### 関連ドキュメント

依存・関連ドキュメントは本文内に `[[path/to/doc]]` で wikilink を張る。
