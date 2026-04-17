# TypeScript ガイドライン

プロジェクト横断で適用する TypeScript 共通ルール。

## パターン

- **Companion Pattern**: 名前空間と型を同名で export し、関連する型・定数・ファクトリ関数をまとめる
- **Discriminated Union + Exhaustive Check**: Union 型にタグフィールドを持たせ、switch + `never` で全パターン網羅をコンパイル時に保証する
- **Branded Types**: プリミティブ型に型タグを付けて混同を防ぐ。Companion Pattern と組み合わせる
- **`satisfies`**: 型を広げずに型チェックだけかける。`as const` との併用で型安全な定数定義
- **エラーハンドリング**: 例外ではなく Result 型でエラーを表現する

## バリデーション

外部境界のバリデーション（→ common.md）には valibot を使う。`v.safeParse()` で例外を投げずに扱う。
