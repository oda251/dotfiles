---
name: journal
description: "Obsidian ジャーナル・ドキュメント記録。調査、コーディング等あらゆるタスクで細かく記録を残す。例: タスクの区切り / 手戻りや想定外の事象 / 本筋からそれる思考 / 非自明な判断 / 再利用できそうな知見"
inputs:
  content: 書き込む内容
---

対象 vault: `obsidian-vault`

すべての vault 操作は `obsidian` コマンドで行う。ファイルシステムへの直書き禁止。

!`obsidian --help`

## ジャーナル追記 vs ドキュメント作成

| | ジャーナル追記 | ドキュメント作成 |
|---|---|---|
| いつ | コーディング・PR作成など成果物がある作業の記録。短い気づき・メモ | 調査・比較検討など、ドキュメント自体が成果物になる作業 |
| 目安 | 200字以内に収まる | 200字を超える、または構造化が必要 |
| 方法 | daily note に一行追記 | 独立ファイルとして作成 |

- ドキュメントを作成・更新した場合も、ジャーナルに一行残す（リンク付き）
- 書き始めて膨らんだ場合はドキュメントに切り出し、ジャーナルからリンクする

## ジャーナル追記

```bash
obsidian daily:append vault=obsidian-vault content="- $(date +%H:%M) {content}"
```

## ドキュメント作成・更新

ドキュメントの内容については `~/.references/policy/documentation.md` に必ず従うこと。

### 種類

- **research**: 事実の収集、技術比較、現状把握
- **draft**: 外部に投稿・共有される成果物の下書き

### パス規約

```
{org}/{prefix}/{date}-{topic}.md   # GitHub repoに紐づく作業
{prefix}/{date}-{topic}.md          # repoに紐づかない
```

- `prefix` = `research` / `draft`
- `date` = `YYYY-MM-DD`
- `topic` = kebab-case
- `{org}` = GitHub owner（`git remote get-url origin` から抽出。不明なら repo-less 形式）
- **repo 名はパスに含めない。タグで管理する**

### タグ

- 種別: `research` or `draft`（必須）
- リポジトリ: `{org}/{repo}`（紐付きがある場合）
- トピック: 任意のキーワード
- `depends-on`: 依存ドキュメントがある場合（wikilink）

### draft 作成時

daily note に todo を追加する: `- [ ] draft: {topic} [[{path}]] ➕ {YYYY-MM-DD}`

## ルール

- 作成・更新したファイルは `obsidian open vault=obsidian-vault path="{path}"` で開けることをユーザーに伝える
