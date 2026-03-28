# 技術スタック

dispatch およびエージェント基盤の技術選定とその根拠。

## ランタイム: Bun

- `bun:sqlite` がネイティブ組み込み（addon 不要）
- TypeScript を直接実行できる（トランスパイル不要）
- テストランナー内蔵（`bun:test`）

## ORM: drizzle-orm/bun-sqlite

- 型安全なクエリビルダー
- `bun:sqlite` とのネイティブ統合
- スキーマ定義がバリデーションスキーマの single source of truth になる（drizzle-valibot 連携）

## バリデーション: Valibot + drizzle-valibot

- drizzle テーブル定義から `createInsertSchema` でバリデーションスキーマを自動生成
- CLI 用 DTO は `v.omit()` + entries spread で基本スキーマから派生させる
- DB カラムの型変更が自動的に DTO に伝播する
- タスクタイプの動的バリデーションは `v.check()` + `isValidTaskType` で実現

```ts
const baseTaskInsert = createInsertSchema(tasks, {
  type: taskTypeSchema,  // v.pipe(v.string(), v.check(isValidTaskType))
})

const AddTaskInput = v.object({
  ...v.omit(baseTaskInsert, ["id", "status", "result", "createdAt"]).entries,
  wsId: v.pipe(v.string(), v.minLength(1)),
  dependsOn: v.optional(v.array(v.string()), []),
})
```

## エラーハンドリング: neverthrow

- 例外ではなく `Result<T, E>` 型でエラーを表現
- `ok()` / `err()` で明示的にエラーパスを型で追跡
- DB 操作の失敗を呼び出し元で安全にハンドリング

## 型設計

### Branded Types + Companion Pattern

`WorkspaceId`, `TaskId`, `TaskType` はブランド型で混同を防ぐ。

```ts
type TaskId = string & { readonly __brand: unique symbol }

const TaskId = {
  from: (value: string): TaskId => value as TaskId,
  generate: (): TaskId => generateShortId() as unknown as TaskId,
  unwrap: (id: TaskId): string => id as string,
} as const
```

### TaskType の動的バリデーション

- `TaskType` はブランド型（ハードコードされた列挙値を持たない）
- 有効なタスクタイプはスキルの `SKILL.md` フロントマター `task-types` から動的にスキャン
- Valibot の `v.check(isValidTaskType)` でランタイムバリデーション
- スキルの追加・削除で自動的にタスクタイプが増減する

### as const + 型推論（enum を使わない）

```ts
const TaskStatus = {
  Pending: "pending",
  Running: "running",
  Done: "done",
} as const

type TaskStatus = (typeof TaskStatus)[keyof typeof TaskStatus]
```

### Discriminated Union

```ts
type RunResult =
  | { readonly status: "ready"; readonly task: TaskRecord; readonly prompt: string }
  | { readonly status: "complete"; readonly message: string }
  | { readonly status: "blocked"; readonly message: string }
  | { readonly status: "error"; readonly message: string }
```

## サブエージェント実行: Claude Agent SDK

- `query()` でサブエージェントを起動（`claude -p` サブプロセスではない）
- プロセス起動コスト・フック再発火・コンテキスト汚染を排除
- `settingSources: []` で親の CLAUDE.md・フック設定の漏洩を防ぐ

## データストア: SQLite (WAL mode)

- 単一ファイル `.dispatch.db` でタスク・ワークスペース・依存関係を管理
- WAL モードで読み書き並行性を確保
- DAG 解決は `NOT EXISTS` サブクエリで実現
