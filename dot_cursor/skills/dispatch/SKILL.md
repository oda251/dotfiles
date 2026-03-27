---
name: dispatch
description: 次のタスクを特定し、ステータスを更新し、適切なスキルを呼び出す。
user-invocable: false
---

`~/.claude/references/task-management-guideline.md` に従う。

## 手順

### 1. 次のタスクの特定

引き継がれたタスクファイルとフェーズ番号から、対象タスクを特定する。

タスクファイルが引き継がれていない場合、task-management-guideline の「次のタスク判断」に従い、現ファイル → 親 → 再帰的に探索する。

### 2. ステータス更新

対象タスクを `⬜` → `🔵` に更新する。

### 3. スキル呼び出し

フェーズ見出しの種別に応じてスキルを呼ぶ。タスクファイルのパスとフェーズ番号を引き継ぐ:
- `plan-*` → **plan**
- `exec-*` → **exec**
