---
name: task-manage
description: "Obsidian タスク管理。タスクの追加・確認・完了。「タスク見て」「TODO確認」「タスク追加」等で起動。"
inputs:
  purpose: 何をしたいか（追加 / 確認 / 完了）
  content: タスク内容（追加時）
---

対象 vault: `obsidian-vault`

すべての vault 操作は `obsidian` コマンドで行う。

!`obsidian --help`

## タスク追加

```bash
obsidian daily:append vault=obsidian-vault content="- [ ] {content} ➕ $(date +%Y-%m-%d)"
```

## タスク確認

```bash
obsidian tasks vault=obsidian-vault todo
obsidian tasks vault=obsidian-vault daily
obsidian tasks vault=obsidian-vault done
```
