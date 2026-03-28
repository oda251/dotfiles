# 技術スタック: 共通

言語非依存の技術選定。

## Git Hooks: Lefthook

- Lefthook を使う（husky/pre-commit ではない）
- pre-commit: lint, format
- pre-push: テスト（必要に応じて）

## テスト基盤: Testcontainers

外部依存（DB, キャッシュ等）の実物をコンテナで立てる（→ testing.md「ローカルで再現できる依存」）。

## E2E テスト: Playwright

- ブラウザテストには Playwright を使う
