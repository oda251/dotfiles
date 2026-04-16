---
description: 調査観点に基づき情報を収集する
inputs:
  topic: 調査テーマ
  purpose: 調査の目的（技術選定、現状把握など）
  depth: 必要な粒度（概要 or 実装詳細）
confirm-before-run: false
next: write
---

- 観点に対して妥当な結論が出せる情報が集まったら終了する。
  網羅性より判断に足る情報の確保を優先する
- 出力形式: 事実のリスト。各項目に必ずソースを併記すること
  （URL、ファイルパス:行番号、ドキュメント名+セクション等）
- WebSearch のスニペットを事実として記録するな。
  必ず WebFetch でページ本文を読み、本文の情報のみ記録すること
- 1リソースごとに即 `obsidian create` で書き出せ。まとめて書くな
- 関連する内部リンクがあれば追え。十分な情報があれば深追いしない
- ソースのない情報は記録しない。確認できなかった項目は「未確認」と明記する

## 保存先

vault `obsidian-vault` の以下に書き出す:

```
{org}/.research/{date}-{topic}/   # GitHub repoに紐づく作業
.research/{date}-{topic}/          # repoに紐づかない
```

- `{org}` は対象リポジトリの GitHub owner（`git remote get-url origin` から抽出）。
  remote 不明または外部調査の場合は repo-less 形式
- `.research/` プレフィックスは「最終ドキュメントではない中間収集物」であることを示す（documentation skill の `{prefix}/` とは別扱い）
- 1リソース = 1ファイルで保存。ファイル名は `{source-slug}.md` など識別可能な形

書き出しコマンド例:

```bash
obsidian create vault=obsidian-vault \
  path="anthropic/.research/2026-04-16-hono-auth/hono-docs-middleware.md" \
  content="..."
```
