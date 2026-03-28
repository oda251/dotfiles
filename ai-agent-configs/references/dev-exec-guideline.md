# Dev 実行ガイドライン

## exec-dev タスク

実装後にレビューを行う:

1. 実装する
2. 変更内容をセルフレビューする（dev-review の観点で）
3. **指摘なし** → `dispatch task done --id {task_id} --result "変更ファイルパス"` で完了
4. **指摘あり** → 修正してステップ 2 に戻る
