---
name: obsidian
description: Obsidian vault 操作
inputs:
  purpose: 何をしたいか（ジャーナル追記 / タスク追加 / タスク確認 など）
  content: 書き込む内容（追記・追加時）
---

対象 vault: `obsidian-vault`

## ファイル操作

```bash
obsidian create vault=obsidian-vault path="{path}" content="{body}"
obsidian read vault=obsidian-vault path="{path}"
obsidian append vault=obsidian-vault path="{path}" content="{additional}"
obsidian create vault=obsidian-vault path="{path}" content="{body}" overwrite
obsidian property:set vault=obsidian-vault path="{path}" name="{key}" value="{val}" type=list
obsidian wordcount vault=obsidian-vault path="{path}"
obsidian outline vault=obsidian-vault path="{path}"
```

## journal — daily note にジャーナル追記

```bash
obsidian daily:append vault=obsidian-vault content="- $(date +%H:%M) {content}"
```

`### Log` セクションの末尾に追記される。

## tasks add — daily note にタスク追加

```bash
obsidian daily:append vault=obsidian-vault content="- [ ] {content}"
```

## tasks — タスク一覧・フィルタ

```bash
obsidian tasks vault=obsidian-vault todo        # 未完了
obsidian tasks vault=obsidian-vault daily       # daily note のタスク
obsidian tasks vault=obsidian-vault done        # 完了済み
obsidian tasks vault=obsidian-vault format=json # 全タスク（JSON）
```

## ルール

- 作成・更新したファイルは `obsidian://open?vault=obsidian-vault&file={path-without-.md}` 形式の URI をユーザーに提示する
- draft を作成したら、daily note に todo を追加する: `- [ ] draft: {topic} [[{path}]] ➕ {YYYY-MM-DD}`
