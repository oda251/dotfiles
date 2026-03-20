---
name: documentation
description: 調査・検討・意思決定のドキュメントフォーマット規則。ドキュメントを書く際に参照する。サブエージェントもこのスキルに従う。
---

## ドキュメントの種類

必ず investigation → consideration → decision の順序を踏む。前段階の省略は不可。

- **investigation (inv-)**: 事実の収集、技術比較、現状把握
- **consideration (con-)**: 選択肢の評価、トレードオフ分析
- **decision (dec-)**: 採用した方針、理由、今後のアクション

同一ドキュメント内で複数段階を記述してよい。その場合、プレフィックスは最上位レベルを採用する（dec > con > inv）。

```markdown
<!-- 1ファイルに全段階を含む場合 → dec- -->
# SSE 採用の決定

## 調査
WebSocket と SSE を比較した結果...（出典付き）

## 検討
SSE はサーバー→クライアントの単方向で十分なユースケースにおいて...

## 決定
SSE を採用する。理由: ...
```

別ドキュメントに分かれる場合は depends-on でリンクする。

## ファイル命名

`docs/{date}-{prefix}-{topic}.md`

- `inv-` / `con-` / `dec-`

例: `docs/2026-03-20-inv-websocket-vs-sse.md`

## Obsidian 互換 frontmatter

```markdown
---
tags:
  - investigation
  - websocket
  - sse
---
```

tags にはドキュメントの種類とトピックのキーワードを含める。

## ドキュメント間のリンク

```markdown
---
tags:
  - decision
  - realtime
  - sse
---
# リアルタイム通信方式の決定

depends-on:
- [リアルタイム通信の選択肢検討](./2026-03-20-con-realtime-options.md)
```

## 出典ルール

情報単位ごとにインラインで出典を付ける。末尾まとめは禁止。

```markdown
# 良い例
`useEffect` は第2引数に依存配列を受け取る（[React 18.2 公式ドキュメント](https://react.dev/reference/react/useEffect)）。

# 悪い例
useEffect は第2引数に依存配列を受け取る。
参考: React公式ドキュメント
```

- 出典が無い情報は **（未検証）** と明記する
- 確認不能なら「わかりません」と明言する
- バージョン固有の挙動にはバージョンを明記する

## 管理ルール

- `docs/` ディレクトリが存在しなければ作成する
- 既存ドキュメントがあれば差分を確認し更新する。大きく変わった場合は新規作成
- 500行を超えるファイルは分割する
- 図はmermaidで表現する

## セルフチェック

```
□ 各情報にインラインで出典を付けたか？
□ 出典なしの情報に（未検証）を付けたか？
□ 関連ドキュメントへのリンクを付けたか？
□ 前段階が存在するか？（スキップ不可）
□ 詳細を捏造していないか？
```
