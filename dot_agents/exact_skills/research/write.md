---
description: 収集結果を元に調査ドキュメントを作成する
internal: true
inputs:
  sources: vault内の収集結果ディレクトリパス（例: anthropic/.research/2026-04-16-hono-auth/）
  theme: 調査テーマ
---

収集結果を元に調査ドキュメントを作成する。

- documentation skill を使ってフォーマットすること（パス規約・frontmatter・出典ルール）
- 入力: 指定された収集結果ディレクトリ内の全ファイルを `obsidian read` で読むこと。
  ディレクトリ内のファイル一覧は `obsidian files folder={sources}` で取得
- 出典は原本ソース（URL等）をそのまま使うこと。
  収集結果ファイルへの参照は出典にしない
- 出力先は documentation skill の規約に従い vault に書き出す
  （`{org}/research/{date}-{topic}.md` または `research/{date}-{topic}.md`）

## セルフチェック

完了前に以下を確認:
- 各情報にインラインで出典を付けたか？
- 出典が原本ソース（URL等）か？収集結果ファイルパスを出典にしていないか？
- 調査テーマに対して網羅的か？
- obsidian CLI 経由で書き出したか？
