# JWT の基本構造とアルゴリズム選択

## JWT 構造

JWT は 3 つのパートで構成される: Header / Payload / Signature。

- **Header**: 署名アルゴリズムとトークンタイプを指定
- **Payload**: クレーム（iss, sub, exp, iat, jti 等）を格納
- **Signature**: Header + Payload を秘密鍵で署名し、改ざん検知を実現

## アルゴリズム比較

### HS256 (HMAC + SHA-256)
- **種別**: 対称鍵（署名と検証に同一の秘密鍵）
- **性能**: 最も高速
- **用途**: 単一サービス内での利用に適する
- **リスク**: 鍵の共有が必要なため、マイクロサービス構成では鍵漏洩リスクが高い

### RS256 (RSA + SHA-256)
- **種別**: 非対称鍵（秘密鍵で署名、公開鍵で検証）
- **性能**: HS256 より低速
- **用途**: 最も広くサポートされ、公開鍵シナリオに適する
- **利点**: 鍵漏洩時に署名鍵のみローテーションで対応可能

### ES256 (ECDSA + P-256 + SHA-256)
- **種別**: 非対称鍵（楕円曲線暗号）
- **性能**: RS256 と同等のセキュリティを小さい鍵サイズで実現（256bit EC ≈ 3072bit RSA）
- **用途**: モダンなシステムでの推奨選択肢

### EdDSA (Ed25519)
- **種別**: 非対称鍵
- **性能**: 最新かつ最もセキュアで、パフォーマンスも優秀
- **備考**: 量子耐性の性質を持つとされる

## 推奨

- **新規プロジェクト**: EdDSA または ES256 を推奨
- **広い互換性が必要**: RS256
- **単一サービス内の簡易用途**: HS256（ただし非対称鍵への移行を推奨）
- **ホワイトリスト方式**: 許可するアルゴリズムを明示的に定義し、algorithm confusion 攻撃を防ぐ

## Sources
- https://auth0.com/blog/rs256-vs-hs256-whats-the-difference/
- https://supertokens.com/blog/rs256-vs-hs256
- https://www.scottbrady.io/jose/jwts-which-signing-algorithm-should-i-use
- https://curity.io/resources/learn/jwt-best-practices/
