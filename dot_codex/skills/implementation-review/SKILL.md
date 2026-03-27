---
name: implementation-review
description: 実装をレビューし、指摘があれば implementation に戻す。指摘がなければ検証して完了。
user-invocable: false
---

## 手順

### 1. レビュー

別エージェントを起動し、以下を指示する:

```
以下の変更をレビューせよ。
- 変更ファイル: [ファイルパス一覧]
- 変更の意図: [何を実現するための変更か]
- 観点: 対象言語のガイドライン（~/.claude/references/{lang}.md, {lang}-{framework}.md）があれば従う
- 問題があれば具体的な修正案を示すこと
```

### 2. 判断

- **指摘あり** → implementation に戻る
- **指摘なし** → 全テスト pass・ビルド確認して完了

## 次のスキル

- 指摘あり → **implementation** に戻る
- 指摘なし・全タスク完了 → **完了**（チェーン終端）
- 残りタスクがある場合 → 次のタスクの **test-writing** を呼ぶ
