---
name: test-review
description: テストの網羅性をレビューする。
user-invocable: false
---

レビュー共通ルールは `~/.claude/references/review-guideline.md`、テスト固有の基準は `~/.claude/references/testing-guideline.md` に従う。

## 手順

別エージェントを起動し、以下を指示する:

```
以下のテストをレビューせよ。
- テストファイル: [ファイルパス一覧]
- テスト対象の振る舞い: [何をテストしているか]
- 観点: ~/.claude/references/testing-guideline.md の「テストレビュー基準」に従う
- 問題があれば具体的な修正案を示すこと
```

指摘があれば実装者が修正する。

## 次のスキル

→ **implementation** を呼べ。テストファイルのパスとタスク定義を引き継ぐ。
