---
name: plan
description: メタファイルのステップに基づき、ドメイン固有のガイドラインを読んで計画を作成する。
user-invocable: false
---

## 手順

### 1. ドメイン判別

メタファイルから現在のステップの種別（dev / research）を読み取る。

### 2. ガイドライン読み込み

種別に応じたガイドラインを読む:
- `dev` → `~/.claude/references/dev-plan-guideline.md`
- `research` → `~/.claude/references/research-plan-guideline.md`

### 3. 計画作成

ガイドラインに従いタスクを分解し、タスクファイルに書き出す。

保存先: `docs/.tasks/{date}-{chain}-{topic}.md`

| ステータス | 表記 |
|-----------|------|
| 未着手 | `⬜` |
| 実行中 | `🔵` |
| 完了 | `✅` |

```markdown
## Phase 1
- ⬜ a. タスク内容
- ⬜ b. タスク内容
```

## 次のスキル

→ **exec** を呼べ。計画ファイルのパスとメタファイルのパスを引き継ぐ。
