---
name: plan
description: 指定されたフェーズを展開し、子タスクファイルを作成する。
user-invocable: false
---

タスク管理は `~/.claude/references/task-management-guideline.md` に従う。

## 手順

### 1. 指定フェーズの確認

引き継がれたタスクファイルとフェーズ番号から、対象フェーズを読み取る。

### 2. ドメイン判別とガイドライン読み込み

フェーズ見出しの種別からドメインを判別し、対応するガイドラインを読む:
- `plan-dev` → `~/.claude/references/dev-plan-guideline.md`
- `plan-research` → `~/.claude/references/research-plan-guideline.md`

### 3. 先行タスクの成果物を参照

親タスクファイルの完了済みフェーズ（全タスク ✅）に子ファイルリンクがあれば、その成果物（docs/ 配下のドキュメント、収集結果等）を読み、計画に反映する。

### 4. 子タスクファイル作成

ガイドラインに従いタスクを分解し、子タスクファイルに書き出す。

### 5. ステータス更新と次のタスク判断

task-management-guideline に従い、親タスクのステータスを更新し、次のタスクを判断する。
