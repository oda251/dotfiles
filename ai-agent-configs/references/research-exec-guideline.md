# Research 実行ガイドライン

## exec-research タスク

指示された調査観点について情報を収集する。

収集結果の保存先: `docs/.research/{date}-{topic}/`

完了時: `dispatch task done --result "収集結果ファイルパス"`

## exec-research-write タスク

収集結果を統合ドキュメントにまとめる。

完了時: `dispatch task done --result "ドキュメントパス"`

不足観点を発見した場合:
- ドキュメントを作成した上で、不足している観点を報告する
- 追加調査タスクを起票する: `dispatch task add --title "不足観点" --type exec-research --depends-on {current_task_id}`
