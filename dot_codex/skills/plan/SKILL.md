---
name: plan
description: 指定されたフェーズを展開し、子タスクファイルを作成する。
user-invocable: false
---

## 手順

### 1. 指定フェーズの確認

引き継がれたタスクファイルとフェーズ番号から、対象フェーズを読み取る。

### 2. ドメイン判別とガイドライン読み込み

フェーズ見出しの種別からドメインを判別し、対応するガイドラインを読む:
- `plan-dev` → `~/.claude/references/dev-plan-guideline.md`
- `plan-research` → `~/.claude/references/research-plan-guideline.md`

### 3. 先行フェーズの成果物を参照

同一タスクファイル内の完了済みフェーズ（✅）に成果物リンク（`[調査結果](...)` 等）があれば読み、計画に反映する。

### 4. 子タスクファイル作成

ガイドラインに従いタスクを分解し、子タスクファイルに書き出す。

保存先: `docs/.tasks/{date}-{chain}-{topic}.md`

frontmatter で親タスクファイルを参照する:

```yaml
---
parent: {親タスクファイル名}
parent-phase: {フェーズ番号}
---
```

### 5. 親タスクに子ファイルリンクを付記

```
- 🔵 a. [認証機能](docs/.tasks/2028-03-28-dev-user-auth.md)
```

## 次のスキル

→ **dispatch** を呼べ。子タスクファイルのパスを引き継ぐ。
