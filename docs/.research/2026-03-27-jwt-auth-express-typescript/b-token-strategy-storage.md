# Access Token / Refresh Token 戦略とトークン保存場所

## トークン戦略

### Access Token
- 短い有効期限（15分程度）
- API リクエストの認証に使用
- ステートレス検証が可能

### Refresh Token
- 長い有効期限（7日〜30日）
- Access Token の再発行に使用
- サーバー側での失効管理が必要

## 保存場所の比較

### localStorage
- **利点**: JavaScript から簡単にアクセス可能、API ヘッダーへの付与が容易
- **欠点**: XSS 攻撃に脆弱（悪意のある JS がトークンを読み取れる）
- **評価**: セキュリティ上、非推奨

### httpOnly Cookie
- **利点**: JavaScript からアクセス不可のため XSS 耐性が高い。Secure + SameSite 属性で追加保護
- **欠点**: CSRF 対策が別途必要。Cookie サイズ上限 4KB
- **評価**: Refresh Token の保存に推奨

### メモリ（アプリケーション状態）
- **利点**: XSS/CSRF 双方に最も強い。ページ離脱時に自動消去
- **欠点**: ページリロードでトークンが消失。タブ間共有不可
- **評価**: Access Token の保存に推奨

## 推奨ハイブリッド戦略

| トークン | 保存場所 | 理由 |
|----------|----------|------|
| Access Token | メモリ（変数/state） | XSS/CSRF 両方に強い |
| Refresh Token | httpOnly + Secure + SameSite Cookie | JS アクセス不可で安全 |

- Access Token 期限切れ時に Refresh Token で自動更新
- Cookie 設定: `httpOnly: true`, `secure: true`, `sameSite: 'Strict'`

## Sources
- https://www.cyberchief.ai/2023/05/secure-jwt-token-storage.html
- https://dev.to/cotter/localstorage-vs-cookies-all-you-need-to-know-about-storing-jwt-tokens-securely-in-the-front-end-15id
- https://www.descope.com/blog/post/developer-guide-jwt-storage
- https://workos.com/blog/secure-jwt-storage
