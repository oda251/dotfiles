# タグ体系

必須:

- `purpose/*` — 目的（`purpose/research`, `purpose/meeting`, `purpose/decision`, `purpose/comparison`, `purpose/draft` 等）

該当時:

- `tech/*` — 技術関連ノート。具体ツール（`tech/hono`）と概念（`tech/async`）の両方を拾う
- `repo/*` — リポジトリ紐付き（`repo/{org}/{repo}`）

永続知財として横断検索に乗せたい場合（長期参照する調査結果など）はさらに分野分類タグを付ける。流れていく系（draft・意思決定ログ・ミーティングメモ等）は不要:

- `ndc/*` — 汎用分野分類。語彙: `~/.references/taxonomy/ndc.md`
- `ccs/*` — 計算機分野の領域分類。語彙: `~/.references/taxonomy/ccs.md`

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
