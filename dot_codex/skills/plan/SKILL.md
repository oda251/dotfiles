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

### 3. 先行タスクの成果物を参照

親タスクファイルの完了済みタスク（✅）に子ファイルリンクがあれば、その成果物（docs/ 配下のドキュメント、収集結果等）を読み、計画に反映する。

### 4. 子タスクファイル作成

ガイドラインに従いタスクを分解し、子タスクファイルに書き出す。

保存先: `docs/.tasks/{date}-{chain}-{topic}.md`

frontmatter で親タスクファイルを参照する:

```yaml
---
parent: {親タスクファイル名}
parent-task: {親タスクのID（例: a）}
---
```

```markdown
## Phase 1
- ⬜ a. タスク内容
- ⬜ b. タスク内容
```

### 5. 親タスクのステータス更新

親タスクファイルの対象タスクを `⬜` → `🔵` に更新し、子ファイルへのリンクを付記する。

```
- 🔵 a. plan-dev: 認証機能 → 2028-03-28-dev-user-auth.md
```

## 次のスキル

→ **exec** を呼べ。子タスクファイルのパスと親タスクファイルのパスを引き継ぐ。
