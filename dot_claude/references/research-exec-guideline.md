# Research 実行ガイドライン

## exec-research フェーズ

同一フェーズ内のタスクは並列でサブエージェントに委譲する。

サブエージェントに計画ファイルのパス + タスクID + 保存先 + **research-gather** スキルを使うよう指示する。

収集結果の保存先: `docs/.research/{date}-{topic}/`（エージェントごとにファイルを分ける）

## exec-research-write フェーズ

サブエージェントに収集結果ディレクトリ + 出力先 + **research-write** スキルを使うよう指示する。

サブエージェントが不足観点を報告した場合:
- 不足観点を新タスクとして gather フェーズに追加し、dispatch に戻す

## 全フェーズ完了時

親タスクファイルの子ファイルリンクに成果物パスを付記する:
```
- ✅ a. [認証パターン比較](docs/.tasks/2028-03-28-research-auth.md) → [調査結果](docs/2026-03-28-res-jwt-auth.md)
```
