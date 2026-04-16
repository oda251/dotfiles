---
name: documentation
description: 調査・検討・意思決定のドキュメントフォーマット規則。ドキュメントを書く際に参照する。
---

## 永続化先

すべての書き込みは Obsidian CLI 経由で vault `obsidian-vault` に行う。ファイルシステムへの直書き（Write tool等）は禁止。

```bash
obsidian create vault=obsidian-vault path="{path}" content="{body}"
obsidian append vault=obsidian-vault path="{path}" content="{additional}"
obsidian property:set vault=obsidian-vault path="{path}" name="{key}" value="{val}" type=list
```

既存ドキュメントの更新は `obsidian append` / `obsidian property:set` を使う。全面書き換えの場合は `obsidian create ... overwrite` で上書きする。

## ドキュメントの種類

- **research**: 事実の収集、技術比較、現状把握。調査テーマに対して網羅的に情報を収集し、出典付きで整理する。考察・決定に発展しても同じドキュメント内に含めてよい
- **draft**: 外部に投稿・共有される成果物の下書き（GitHub issue、PR description、ADR、提案書など）

段階や進行状況は prefix 分岐ではなく frontmatter の `status` で表現する:
- `research` 用: `researching`（収集中）/ `considered`（検討済み）/ `decided`（採用）
- `draft` 用: `draft`（下書き中）/ `posted`（投稿済み）

別ドキュメントに分かれる場合は `depends-on` でリンクする。

## パス規約

```
{org}/{prefix}/{date}-{topic}.md   # GitHub repoに紐づく作業
{prefix}/{date}-{topic}.md          # repoに紐づかない
```

- `prefix` = `research` / `draft`（フルスペル、短縮しない）
- `date` = `YYYY-MM-DD`
- `topic` = kebab-case の短い識別子
- `{org}` は対象リポジトリの GitHub owner（個人 owner も含む）。`git remote get-url origin` から抽出。remote が無い / 複数 remote で不明 / 外部調査でrepoに紐づかない場合は repo-less 形式にフォールバック
- repo名（リポジトリ名）はパスに含めず、**タグ** で管理する（後述）

例:
- `anthropic/research/2026-04-16-hono-auth.md`
- `research/2026-04-16-sveltekit-rendering.md`（repo紐付きなし）
- `oda251/draft/2026-04-16-vault-consolidation.md`（issue draft等）

## frontmatter テンプレート

```yaml
---
tags:
  - research                    # or draft
  - {org}/{repo}                # リポジトリ（nested tag）。紐付きなしなら省略
  - {topic-keyword}             # 複数可
status: researching              # research: researching/considered/decided, draft: draft/posted
depends-on:
  - "[[{org}/research/2026-03-20-websocket-vs-sse]]"   # 依存ドキュメントがある場合
---
```

- `tags` は Obsidian の nested tag を活用する（`/` 区切り）
- 種別タグ（`research` / `draft`）は必須
- repo紐付きの場合は `{org}/{repo}` を nested tag として入れる（例: `anthropic/claude-code`）。パスと重複するが、タグペインで横断検索するために必要
- その他のネームスペース（`status/xxx`、`priority/xxx` 等）は将来的に標準化する。現時点では自由に追加してよい
- `status` frontmatter で段階・進行状況を表現する（prefix分岐しない）
- `depends-on` は Obsidian wikilink 形式で前段階ドキュメントを指す

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
- WebSearch のスニペットは出典にしない。WebFetch で本文を確認した上で引用する

## ユーザー通知

作成・更新したファイルごとに `obsidian://open?vault=obsidian-vault&file={path-without-.md}` 形式のURIを提示する。

## 管理ルール

- 既存ドキュメントがあれば `obsidian read` で差分を確認し、`obsidian append` / `obsidian property:set` で更新する。大きく変わった場合は新規作成し旧doc に `depends-on` で繋ぐ
- 500行を超えるファイルは分割する（`obsidian wordcount` や `outline` で確認）
- 図は mermaid で表現する
- vault 外（ローカル `docs/` 等）への書き込みはしない

## セルフチェック

```
□ obsidian CLI 経由で書き込んだか？ファイル直書きしていないか？
□ パスは {org}/{prefix}/{date}-{topic}.md 規約に従っているか？
□ 各情報にインラインで出典を付けたか？
□ 出典なしの情報に（未検証）を付けたか？
□ 関連ドキュメントへのリンク（depends-on）を付けたか？
□ 複数段階を含む場合、前段階が存在するか？
□ tags に種別（research/draft）・{org}/{repo}（該当時）・トピックを含めたか？
□ 作成・更新後、Obsidian URI をユーザーに提示したか？
□ 詳細を捏造していないか？
```
