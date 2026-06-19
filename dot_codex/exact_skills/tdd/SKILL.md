---
name: tdd
description: 任意の実装タスクを開始するときに利用する。
---

メイン（自分 / Opus）は要件設計・赤テスト・赤緑判定・push を担当し、実装は Sonnet サブエージェント（`Agent`, `model: sonnet`）に委譲する。実装する Sonnet にはテストを編集させない。

## 手順

1. `main` を基点に worktree を作り、要件ファイル `$WT/docs/tmp/<slug>.md` を用意する

   ```bash
   git branch feat/<slug> main
   gwq add feat/<slug>
   WT=$(gwq list -g --json | jq -r '.[]|select(.branch=="feat/<slug>").path' | head -1)
   ```

2. 要件をテスト可能なアサーション（入力 → 期待）に分解し、要件ファイルにチェックリストで書く。1項目 = テスト1つの粒度
3. 不足観点（異常系・境界・非機能・IF）を `AskUserQuestion` で詰め、要件ファイルを確定する

4. 要件を1つずつ消化する（複数同時着手しない）。各要件で:

   1. テストを書くか判断する: `テストを書く = ( expect(fn(input)).toBe(output) が書ける ) && ( ビジネスロジックに関わる )`
   2. 書くなら、メインが赤テストを1つ書き、実行して振る舞い未実装で落ちることを確認する
   3. Sonnet のサブエージェントに `${CLAUDE_SKILL_DIR}/implement.md` と本タスクに関連する `~/.references` ガイドラインのパスを渡し、最小実装をさせる
   4. メインが検証する。全体テスト緑（既存を壊さない）。テストを書いたなら対象テスト緑・テスト未改変（`git -C "$WT" diff`）、書かないなら振る舞いを直接確認
   5. commit する

5. 全要件 green になったら `/simplify` → 全体テスト緑を再確認する
6. push して draft PR を作成（PR body は要件ファイル）。一時ファイルは消す。draft のまま完了報告する（マージはユーザ判断）

   ```bash
   git -C "$WT" push -u origin feat/<slug>
   gh pr create --draft --head feat/<slug> --title "<title>" --body-file "$WT/docs/tmp/<slug>.md"
   rm "$WT/docs/tmp/<slug>.md"
   ```

基盤未整備（シードデータ・テスト環境構築等）で赤テストが書けない要件は中断し、進め方をユーザと相談する。
