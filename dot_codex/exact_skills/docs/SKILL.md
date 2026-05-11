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
obsidian create vault=obsidian-vault path="{path}" content="$(cat /tmp/doc.md)" open
```

作成時は必ず `open` を付与し、保存と同時に Obsidian で開く。

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

nested tag を活用する。**個数ではなく分野で網羅性を担保する**。下記の必須カテゴリそれぞれから最低 1 つ拾う。

必須:

- `purpose/*` — 目的（`purpose/research`, `purpose/meeting`, `purpose/decision`, `purpose/comparison` 等）
- `ndc/*` — 汎用分野分類。日本十進分類法（NDC）の 3 桁コードで付ける。あらゆるノートに付与し「広い知の中での位置」を示す。語彙: `~/.references/taxonomy/ndc.md`

技術関連ノートの場合（追加で必須）:

- `tech/*` — 技術。**具体ツール（`tech/typescript`, `tech/hono`, `tech/terraform`）と概念レベル（`tech/async`, `tech/middleware`, `tech/authentication`）の両方を拾う**。ツール名だけで埋めない
- `ccs/*` — 計算機分野の領域分類。ACM CCS 2012 のトップレベル 13 区分に準拠。語彙: `~/.references/taxonomy/ccs.md`

該当時:

- `repo/*` — リポジトリ紐付き（`repo/{org}/{repo}`）

**運用ルール**:

- 「`tech/*` がツール名だけ」になっていたら必ず立ち止まる。そのノートで扱っている**概念・パターン・問題領域**も `tech/*` で表現する
- `ccs/*` は計算機分野の分類、`ndc/*` は汎用知識分類、`tech/*` は実体（ツール+概念）の語彙、と役割を分ける

例: Hono の認証ミドルウェア比較ノート

```yaml
tags:
  - purpose/research
  - purpose/comparison
  - tech/hono           # ツール
  - tech/typescript     # ツール
  - tech/middleware     # 概念
  - tech/authentication # 概念
  - ccs/security        # CCS 領域
  - ccs/software        # CCS 領域
  - ndc/007             # NDC: 情報科学
  - ndc/548             # NDC: 情報工学
```

### 関連ドキュメント

依存・関連ドキュメントは本文内に `[[path/to/doc]]` で wikilink を張る。Obsidian のバックリンクで辿れる。
