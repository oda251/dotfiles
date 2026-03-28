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

- drizzle テーブル定義からスキーマ自動生成 → DTO は omit/merge で派生
- DB カラムの型変更が DTO に自動伝播する
- 動的バリデーションは `v.check()` で対応

## Lint / Format: oxlint + oxfmt

- ESLint/Prettier ではなく oxlint + oxfmt を使う
- Lefthook の pre-commit で実行する

## テスト: Vitest

- Bun プロジェクト以外では Vitest を使う
- ESM ネイティブ、HMR による高速な watch モード
- `vi.mock()` より依存注入を優先する（`coding/testing-guideline.md` 参照）

## エラーハンドリング: neverthrow

- 例外ではなく `Result<T, E>` 型でエラーを表現
- エラーパスを型で追跡し、ハンドリング漏れをコンパイル時に検出

## データストア: SQLite (WAL mode)

- 単一ファイルで完結。外部サービス不要
- WAL モードで読み書き並行性を確保

## サブエージェント実行: Claude Agent SDK

- `query()` API でサブエージェントを起動
- サブプロセス起動と比較して: プロセスコスト削減、フック再発火防止、コンテキスト汚染排除
