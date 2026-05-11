# Hono 公式認証ミドルウェア一覧

## ビルトイン認証ミドルウェア（4種）

### 1. Basic Auth
- **import**: `import { basicAuth } from 'hono/basic-auth'`
- **概要**: HTTP Basic 認証。ユーザー名/パスワードで認証する最もシンプルな方式。
- **主なオプション**: `username`, `password`, `realm`, `verifyUser`, `hashFunction`, `invalidUserMessage`, `onAuthSuccess`
- **特徴**: 複数ユーザー対応、カスタム検証ロジック（`verifyUser`）、認証成功コールバック（`onAuthSuccess`）

### 2. Bearer Auth
- **import**: `import { bearerAuth } from 'hono/bearer-auth'`
- **概要**: Bearer トークンによる認証。API キー認証に適する。
- **主なオプション**: `token`（string | string[]）, `realm`, `prefix`, `headerName`, `hashFunction`, `verifyToken`
- **特徴**: 複数トークン対応、カスタム検証（`verifyToken`）、エラーレスポンスのカスタマイズ
- **制約**: トークンは `/[A-Za-z0-9._~+/-]+=*/` にマッチする必要がある

### 3. JWT Auth
- **import**: `import { jwt } from 'hono/jwt'`、型: `import type { JwtVariables } from 'hono/jwt'`
- **概要**: JWT トークンの検証による認証。
- **主なオプション**: `secret`（必須）, `alg`（必須）, `cookie`, `headerName`, `verifyOptions`（`iss`, `nbf`, `iat`, `exp`）
- **対応アルゴリズム**: HS256, HS384, HS512, RS256, RS384, RS512, PS256, PS384, PS512, ES256, ES384, ES512, EdDSA
- **特徴**: Cookie からのトークン取得対応、ペイロードは `c.get('jwtPayload')` で取得

### 4. JWK Auth
- **import**: `import { jwk } from 'hono/jwk'`
- **概要**: JWK（JSON Web Key）を用いたトークン検証。外部 IdP との連携に適する。
- **主なオプション**: `alg`（必須、非対称アルゴリズムの配列）, `keys`, `jwks_uri`, `allow_anon`, `cookie`, `headerName`, `verification`
- **特徴**: JWKS URI からの動的キー取得、`kid` ヘッダー必須、匿名アクセス許可オプション

## JWT ヘルパー関数

- **import**: `import { sign, verify, decode } from 'hono/jwt'`
- JWT のエンコード・デコード・署名・検証ユーティリティ

## 出典
- https://hono.dev/docs/middleware/builtin/basic-auth
- https://hono.dev/docs/middleware/builtin/bearer-auth
- https://hono.dev/docs/middleware/builtin/jwt
- https://hono.dev/docs/middleware/builtin/jwk
- https://hono.dev/docs/helpers/jwt
