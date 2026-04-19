---
name: journal
description: "Obsidian ジャーナル・ドキュメント記録。調査、コーディング等あらゆるタスクで細かく記録を残す。例: タスクの区切り / 手戻りや想定外の事象 / 本筋からそれる思考 / 非自明な判断 / 再利用できそうな知見"
inputs:
  content: 書き込む内容
---

対象 vault: `obsidian-vault`

すべての vault 操作は `obsidian` コマンドで行う。ファイルシステムへの直書き禁止。

!`obsidian --help`

## vault レイアウト

- `AgentLog/YYYY-MM-DD.md` — **agent が書き込むログ**（このskillの出力先）
- `Inbox/YYYY-MM-DD.md` — Discord memo-bot 等の外部入力（agent は読むだけ）
- `Daily/YYYY-MM-DD.md` — ダッシュボード。AgentLog と Inbox を時系列マージして表示するだけ（agent は通常触らない）

## ジャーナル追記 vs ドキュメント作成

| | ジャーナル追記 | ドキュメント作成 |
|---|---|---|
| いつ | コーディング・PR作成など成果物がある作業の記録。短い気づき・メモ | 調査・比較検討など、ドキュメント自体が成果物になる作業 |
| 目安 | 200字以内に収まる | 200字を超える、または構造化が必要 |
| 方法 | AgentLog に一行追記 | 独立ファイルとして作成 |

- ドキュメントを作成・更新した場合も、ジャーナルに一行残す（リンク付き）
- 書き始めて膨らんだ場合はドキュメントに切り出し、ジャーナルからリンクする

## ジャーナル追記

```bash
obsidian append vault=obsidian-vault path="AgentLog/$(date +%Y-%m-%d).md" content="- $(date +%H:%M) {content}"
```

成果物（PR、issue、ドキュメント等）や根拠・参照文献がある場合は URI or wikilink を含める。

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
{org}/{type}/{date}-{title}.md   # GitHub repoに紐づく作業
{type}/{date}-{title}.md          # repoに紐づかない
```

- `type`
  - `draft` — 別所で公開・投稿する前の下書き（issue 本文、PR description、ADR 等）
  - `note` — それ以外のドキュメント全般（調査、ミーティング、意思決定 等）
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

### draft 作成時

AgentLog にタスクを追加する: `- [ ] draft: {title} [[{path}]] ➕ {YYYY-MM-DD}`

## ルール

- 作成・更新したファイルは `obsidian open vault=obsidian-vault path="{path}"` で開けることをユーザーに伝える
