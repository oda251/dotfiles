# 技術スタック: TypeScript

TypeScript プロジェクトの技術選定。

## ランタイム: Bun

- TypeScript 直接実行（トランスパイル不要）
- `bun:sqlite` ネイティブ組み込み（addon 不要）
- テストランナー内蔵（`bun:test`）

## ORM: drizzle-orm

- 型安全なクエリビルダー
- テーブル定義をバリデーションスキーマの single source of truth にできる（drizzle-valibot 連携）

## バリデーション: Valibot

- drizzle テーブル定義からバリデーションスキーマを自動生成できる（drizzle-valibot）

## Lint / Format: oxlint + oxfmt

- ESLint/Prettier ではなく oxlint + oxfmt を使う
- Lefthook の pre-commit で実行する

## テスト: Vitest

- Bun プロジェクト以外では Vitest を使う

## エラーハンドリング: neverthrow

- 例外ではなく `Result<T, E>` 型でエラーを表現する

## サブエージェント実行: Claude Agent SDK

- `query()` API でサブエージェントを起動
- サブプロセス起動と比較して: プロセスコスト削減、フック再発火防止、コンテキスト汚染排除
