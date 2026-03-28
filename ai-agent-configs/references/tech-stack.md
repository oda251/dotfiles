# 技術スタック

共通の技術選定方針。

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

## エラーハンドリング: neverthrow

- 例外ではなく `Result<T, E>` 型でエラーを表現
- エラーパスを型で追跡し、ハンドリング漏れをコンパイル時に検出

## データストア: SQLite (WAL mode)

- 単一ファイルで完結。外部サービス不要
- WAL モードで読み書き並行性を確保

## サブエージェント実行: Claude Agent SDK

- `query()` API でサブエージェントを起動
- サブプロセス起動と比較して: プロセスコスト削減、フック再発火防止、コンテキスト汚染排除
