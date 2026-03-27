---
name: plan
description: タスクファイルの未完了ステップを展開し、子タスクファイルを作成する。
user-invocable: false
---

## 手順

### 1. 親タスクファイルの読み込み

引き継がれたタスクファイルから、最初の未完了タスクを特定する。

### 2. ドメイン判別とガイドライン読み込み

タスクの種別（dev / research）に応じたガイドラインを読む:
- `dev` → `~/.claude/references/dev-plan-guideline.md`
- `research` → `~/.claude/references/research-plan-guideline.md`

### 3. 子タスクファイル作成

ガイドラインに従いタスクを分解し、子タスクファイルに書き出す。

保存先: `docs/.tasks/{date}-{chain}-{topic}.md`

frontmatter で親タスクファイルを参照する:

```yaml
---
parent: {親タスクファイル名}
---
```

```markdown
## Phase 1
- ⬜ a. タスク内容
- ⬜ b. タスク内容
```

### 4. 親タスクのステータス更新

親タスクファイルの対象タスクを `⬜` → `🔵` に更新する。

## 次のスキル

→ **exec** を呼べ。子タスクファイルのパスと親タスクファイルのパスを引き継ぐ。
