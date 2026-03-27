# Research 実行ガイドライン

## exec-research フェーズ

同一フェーズ内のタスクは並列でサブエージェントに委譲する。

サブエージェントに計画ファイルのパス + タスクID + 保存先 + **research-gather** スキルを使うよう指示する。

収集結果の保存先: `docs/.research/{date}-{topic}/`（エージェントごとにファイルを分ける）

## exec-research-write フェーズ

1. サブエージェントに収集結果ディレクトリ + 出力先 + **research-write** スキルを使うよう指示する
2. サブエージェントにドキュメントパス + **research-review** スキルを使うよう指示する
   - **十分** → タスク完了
   - **不足あり** → 不足観点を新タスクとして gather フェーズに追加し、dispatch に戻す
