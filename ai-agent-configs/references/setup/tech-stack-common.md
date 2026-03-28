# 技術スタック: 共通

言語非依存の技術選定。

## Git Hooks: Lefthook

- Lefthook を使う（husky/pre-commit ではない）
- pre-commit: lint, format
- pre-push: テスト（必要に応じて）

## テスト基盤: Testcontainers

外部依存（DB, キャッシュ等）は mock ではなく Testcontainers で本物を立てる。
