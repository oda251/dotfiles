---
tags:
  - investigation
  - tdd
  - claude-code
  - slash-commands
  - tidy-first
---
# SwiftyJunnos/Claude-Code-with-TDD: スラッシュコマンド型 TDD テンプレート

source: [SwiftyJunnos/Claude-Code-with-TDD](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)

## サイクル構造

PLAN.md に定義されたテスト一覧を**1テストずつ**逐次処理する。"One Test at a Time" がコア原則として強制される（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）。

## ワークフロー

1. **Planning**: PLAN.md にテストを定義する（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）
2. **RED**: 次の未マークの項目に対して失敗するテストを書く（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）
3. **GREEN**: テストを通す最小限のコードを実装する（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）
4. **REFACTOR**: テストを GREEN に保ちつつコード構造を改善する（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）
5. **Commit**: 構造変更と振る舞い変更を分離してコミットする（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）
6. **Repeat**: PLAN.md の次のテストへ進む（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）

## カスタムスラッシュコマンド

| コマンド | 機能 |
|---------|------|
| `/go` | TDD サイクル開始: 次のテストを見つけて実装 |
| `/red` | 失敗するテストを書く |
| `/green` | テストを通す最小コードを実装 |
| `/refactor` | テストを GREEN に保ちつつ構造改善 |
| `/tidy` | 振る舞い変更なしの構造変更 |
| `/tdd-cycle` | RED → GREEN → REFACTOR の完全サイクル実行 |
| `/fix-defect` | TDD アプローチでバグ修正 |
| `/next-test` | 次の未マークテストを表示 |
| `/run-tests` | 全テスト実行 |
| `/commit-tidy` | 構造変更をコミット |
| `/commit-behavior` | 振る舞い変更をコミット |

（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）

## スキルチェーン

TDD ワークフロー系: tdd-go, tdd-red, tdd-green, tdd-refactor, tdd-cycle, tdd-tidy（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）

開発サポート系: code-reviewer, git-committer, pull-request-descriptor, prompt-enhancer, skill-creator（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）

## 設計原則

"Separate structural changes from behavioral changes" — Tidy First 方法論に基づき、構造変更と振る舞い変更を分離してクリーンなコミット履歴を維持する（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）。

`/next-test` コマンドが次の未マーク項目のみを表示することで、バッチ作業を防止している（[README](https://github.com/SwiftyJunnos/Claude-Code-with-TDD)）。
