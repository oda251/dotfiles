---
name: tdd
description: 任意の実装タスクを開始するときに利用する。
---

メイン（自分 / Opus）は要件設計・赤緑判定・push を担当し、実装は Sonnet サブエージェント（`Agent`, `model: sonnet`）に委譲する。テストを書いた者（メイン or Sonnet）と実装する Sonnet は別にし、実装側にテストを編集させない。

## 手順

1. 要件をテスト可能なアサーション（入力 → 期待）の箇条書きに分解する。1項目 = テスト1つの粒度
2. 不足観点（異常系・境界・非機能・IF）を `AskUserQuestion` でユーザと詰め、要件を確定する
3. worktree を作り、空コミット → push → draft PR。PR body に要件チェックリストを書く

   ```bash
   gwq add -b feat/<slug>
   WT=$(gwq list -g --json | jq -r '.[]|select(.branch=="feat/<slug>").path' | head -1)
   git -C "$WT" commit --allow-empty -m "chore: scaffold"
   git -C "$WT" push -u origin feat/<slug>
   gh pr create --draft --head feat/<slug> --title "<title>" --body "<要件チェックリスト>"
   ```

4. 要件を1つずつ消化する（複数同時着手しない）。着手した要件ごとに、まずテストを書くか判断する:

   ```
   テストを書く = ( expect(fn(input)).toBe(output) が書ける ) && ( ビジネスロジックに関わる )
   ```

   - 書く場合:
     1. 赤テストを1つ用意する（メインが書く。委譲時は `${CLAUDE_SKILL_DIR}/red-test.md` を読んで Sonnet に渡す）
     2. メインがテストを実行し、振る舞い未実装で落ちることを確認する
     3. 別の Sonnet に `${CLAUDE_SKILL_DIR}/implement.md` を読んで渡し、テストを通す最小実装をさせる
     4. メインが緑・全体テスト緑・テスト未改変（`git -C "$WT" diff`）を確認する
   - 書かない場合: Sonnet に実装させ、メインが振る舞いと全体テスト緑を確認する
   - commit する

5. 全要件 green になったら `/simplify` → 全体テスト緑を再確認する
6. `git -C "$WT" push`。draft のまま完了報告する（マージはユーザ判断）

基盤未整備（シードデータ・テスト環境構築等）で赤テストが書けない要件は中断し、進め方をユーザと相談する。
