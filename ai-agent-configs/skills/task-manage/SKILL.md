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

## 書き込み先

```bash
obsidian append vault=obsidian-vault path="AgentLog/$(date +%Y-%m-%d).md" content="- [ ] {task}"
```

## タスクフォーマット

Obsidian Tasks プラグインを利用している。タスクは Markdown チェックボックスで管理し、以下の絵文字アノテーションが使える:

- `➕` 作成日 **必須**
- `📅` 期限
- `⏳` 予定
- `🛫` 開始
- `✅` 完了（自動付与）

タスク内容は第三者が読んでも何をすべきかわかる粒度で書く。関連リソースがあればインラインリンクを含める。

例: `- [ ] [oda251/dotfiles#42](https://github.com/oda251/dotfiles/issues/42) Terraform CD の environment: production 欠落を修正する ➕ 2026-04-19 📅 2026-04-20`
