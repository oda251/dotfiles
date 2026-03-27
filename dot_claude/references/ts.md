# TypeScript ガイドライン

プロジェクト横断で適用する TypeScript 共通ルール。

## パターン

### Companion Pattern

名前空間と型を同名で export し、関連する型・定数・ファクトリ関数をまとめる。

```ts
export type User = {
  id: string
  name: string
  email: string
}

export const User = {
  create: (params: Omit<User, 'id'>): User => ({
    id: crypto.randomUUID(),
    ...params,
  }),
  isValid: (user: User): boolean => user.email.includes('@'),
} as const
```

### enum を使わない

`enum` の代わりに `as const` + 型推論を使う。

```ts
// NG
enum Status { Active, Inactive }

// OK
const Status = { Active: 'active', Inactive: 'inactive' } as const
type Status = (typeof Status)[keyof typeof Status]
```

### エラーハンドリング

neverthrow を使い、例外ではなく Result 型でエラーを表現する。

```ts
import { ok, err, Result } from 'neverthrow'

const parseConfig = (raw: string): Result<Config, ParseError> => {
  // ...
}
```

## バリデーション

外部入力（API リクエスト、フォーム、環境変数等）のバリデーションには zod を使う。`.parse()` ではなく `.safeParse()` を使い、例外を投げずに Result として扱う。

```ts
const result = schema.safeParse(input)
if (!result.success) {
  // result.error で処理
}
```
