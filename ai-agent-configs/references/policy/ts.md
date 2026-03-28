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

### Discriminated Union + Exhaustive Check

Union 型にタグフィールドを持たせ、switch + `never` で全パターン網羅をコンパイル時に保証する。

```ts
type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'square'; side: number }

const area = (shape: Shape): number => {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2
    case 'square':
      return shape.side ** 2
    default: {
      const _: never = shape
      throw new Error(`Unknown: ${_}`)
    }
  }
}
```

### Branded Types

プリミティブ型に型タグを付けて混同を防ぐ。companion pattern と組み合わせる。

```ts
type UserId = string & { readonly __brand: unique symbol }

export const UserId = {
  from: (value: string): UserId => value as UserId,
} as const
```

### `satisfies`

型を広げずに型チェックだけかける。`as const` との併用で型安全な定数定義。

```ts
const config = {
  port: 3000,
  host: 'localhost',
} as const satisfies Config
```

### エラーハンドリング

例外ではなく Result 型でエラーを表現する。

```ts
const parseConfig = (raw: string): Result<Config, ParseError> => {
  // ...
}
```

## 型安全

`any` 禁止（→ common.md）。`unknown` で受けて narrowing する。

## バリデーション

外部境界のバリデーション（→ common.md）には valibot を使う。`v.safeParse()` で例外を投げずに扱う。

```ts
const result = v.safeParse(schema, input)
if (!result.success) {
  // result.issues で処理
}
```
