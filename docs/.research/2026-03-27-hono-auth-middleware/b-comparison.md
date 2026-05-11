# 各ミドルウェアの比較

## ユースケース別マッピング

| ミドルウェア | ユースケース | トークン形式 | 複雑さ |
|---|---|---|---|
| Basic Auth | 管理画面、内部ツール、簡易保護 | ユーザー名:パスワード（Base64） | 低 |
| Bearer Auth | API キー認証、静的トークン | 任意文字列 | 低 |
| JWT Auth | ステートレスセッション、自前 JWT 発行 | JWT（対称・非対称） | 中 |
| JWK Auth | 外部 IdP 連携（Auth0, Cognito 等） | JWT + JWKS エンドポイント | 中〜高 |

## API 設計の共通パターン

全ミドルウェアに共通:
- `app.use('/path/*', middleware(options))` でパス単位保護
- 個別ルートへの直接適用も可能
- Authorization ヘッダーがデフォルトのトークンソース

## カスタマイズ性

| 機能 | Basic Auth | Bearer Auth | JWT Auth | JWK Auth |
|---|---|---|---|---|
| カスタム検証 | `verifyUser` | `verifyToken` | - | - |
| Cookie 対応 | - | - | `cookie` | `cookie` |
| カスタムヘッダー | - | `headerName` | `headerName` | `headerName` |
| エラーカスタマイズ | `invalidUserMessage` | 3種の error object | - | - |
| 成功コールバック | `onAuthSuccess` | - | - | - |
| 匿名アクセス許可 | - | - | - | `allow_anon` |

## 制約・注意点

- **Basic Auth**: パスワードが Base64 でエンコードされるだけで暗号化されない（HTTPS 必須）
- **Bearer Auth**: トークン値は正規表現 `/[A-Za-z0-9._~+/-]+=*/` にマッチする必要がある
- **JWT Auth**: 対称鍵（HS*）使用時は secret の管理が重要。Authorization ヘッダーのスキーム指定が必要
- **JWK Auth**: 非対称アルゴリズムのみ対応。`kid` ヘッダーが必須

## 出典
- https://hono.dev/docs/middleware/builtin/basic-auth
- https://hono.dev/docs/middleware/builtin/bearer-auth
- https://hono.dev/docs/middleware/builtin/jwt
- https://hono.dev/docs/middleware/builtin/jwk
