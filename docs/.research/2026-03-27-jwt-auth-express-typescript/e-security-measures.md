# セキュリティ対策

## トークン失効・ブラックリスト

### トークンブラックリスト
- Redis 等の高速キャッシュに失効トークンの jti（JWT ID）を保存
- TTL をトークンの残り有効期限に設定し、自動クリーンアップ
- 検証時にブラックリストを確認してから処理を進める

### シークレットローテーション
- 署名鍵を定期的にローテーションし、既存トークンを一括無効化
- JWKS（JSON Web Key Set）エンドポイントを公開し、鍵の切り替えをスムーズに

### イベント駆動失効
- 分散イベントシステム（Redis Pub/Sub 等）でリアルタイムに失効イベントを伝播

## トークンローテーション

### Refresh Token Rotation
- Refresh Token 使用時に新しい Refresh Token を発行し、旧トークンを無効化
- **単一使用強制**: 各 Refresh Token は 1 回のみ使用可能
- **サーバー側追跡**: Refresh Token の jti を DB に保存
- **トークンファミリー管理**: 同一セッションのトークンをファミリーとして追跡し、再利用検出時にファミリー全体を失効

## CSRF 防御

- **SameSite Cookie**: `SameSite: 'Strict'` または `'Lax'` で CSRF を軽減
- **CSRF Token**: 状態変更操作（POST/PUT/DELETE）に CSRF トークンを要求
- **Double Submit Cookie**: Cookie と リクエストヘッダーの両方で CSRF トークンを送信し照合

## XSS 防御

- **httpOnly Cookie**: JavaScript からのトークンアクセスを完全に遮断
- **Content Security Policy (CSP)**: インラインスクリプトの実行を制限
- **入力サニタイズ**: ユーザー入力の適切なエスケープ処理
- **Secure 属性**: HTTPS 通信のみで Cookie を送信

## レート制限

- ログイン・トークン更新エンドポイントにレート制限を適用
- express-rate-limit ライブラリの使用
- IP ベース + ユーザーベースの二重制限
- ブルートフォース攻撃の防止

## 推奨アルゴリズム（2025年時点）

| 優先度 | アルゴリズム | 特徴 |
|--------|------------|------|
| 1 | EdDSA | 最新・最高セキュリティ・高パフォーマンス |
| 2 | ES256 | 小さい鍵サイズで強いセキュリティ |
| 3 | RS256 | 広いサポート・互換性重視 |

## Sources
- https://jwt.app/blog/jwt-best-practices/
- https://skycloak.io/blog/jwt-token-lifecycle-management-expiration-refresh-revocation-strategies/
- https://nano-gpt.com/blog/jwt-refresh-tokens-rotation-revocation
- https://www.apisec.ai/blog/jwt-security-vulnerabilities-prevention
- https://dev.to/alvinseyidov/modern-web-authentication-security-jwt-cookies-csrf-and-common-developer-mistakes-fpj
