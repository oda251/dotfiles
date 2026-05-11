# サードパーティ認証連携

## Hono 公式サードパーティミドルウェア一覧（認証関連）

| ミドルウェア | パッケージ | 概要 |
|---|---|---|
| Auth.js (NextAuth) | `@hono/auth-js` | Auth.js セッションを Hono の Context に注入。GitHub, Google 等の OAuth プロバイダ対応 |
| Clerk Auth | `@hono/clerk-auth` | Clerk のユーザー管理・認証プラットフォーム連携 |
| Firebase Auth | `@hono/firebase-auth` | Firebase Authentication 連携（公式サポートは Cloudflare Workers のみ） |
| OAuth Providers | `@hono/oauth-providers` | 各種 OAuth プロバイダとの認証連携 |
| OIDC Auth | `@hono/oidc-auth` | OpenID Connect ベースの認証 |
| Cloudflare Access | `@hono/cloudflare-access` | Cloudflare Access による認証・認可 |
| Casbin | `@hono/casbin` | RBAC / ABAC のアクセス制御ライブラリ（認可） |
| Stytch Auth | `@hono/stytch-auth` | パスワードレス認証プラットフォーム連携 |
| Verify RSA JWT (JWKS) | - | RSA 署名 JWT の JWKS 検証 |

## Auth.js 連携の詳細

- `@hono/auth-js` で Auth.js のセッション管理を Hono に統合
- コールバック URL: `{server}/api/auth/callback/{provider}`
- クライアントサイドは React のみ公式対応（現時点）
- OAuth プロバイダ（GitHub, Google 等）の設定が可能

## Firebase Auth 連携の詳細

- `@hono/firebase-auth`: 公式パッケージだが Cloudflare Workers のみ公式サポート
- `@fiboup/hono-firebase-auth`: コミュニティパッケージ。より広いランタイム対応

## Better Auth 連携

- Better Auth フレームワークも Hono との統合ガイドを提供（https://better-auth.com/docs/integrations/hono）

## 出典
- https://hono.dev/docs/middleware/third-party
- https://www.npmjs.com/package/@hono/auth-js
- https://www.npmjs.com/package/@hono/firebase-auth
- https://better-auth.com/docs/integrations/hono
