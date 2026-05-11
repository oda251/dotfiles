# Express + TypeScript 向け JWT ライブラリ比較

## ライブラリ一覧

### jose
- **週間 DL**: 約 3,750 万
- **GitHub Stars**: 7,315
- **特徴**:
  - Web Crypto API ベースのモダン実装
  - ネイティブ async/await サポート
  - TypeScript ファーストで型定義が充実
  - Node.js / ブラウザ / Edge Runtime 対応
  - ESM 完全対応
  - アクティブにメンテナンスされている
- **評価**: 新規プロジェクトでの第一選択肢

### jsonwebtoken
- **週間 DL**: 約 3,250 万
- **GitHub Stars**: 18,147
- **特徴**:
  - 最も広く使われてきた JWT ライブラリ
  - callback ベースの API（promisify が必要）
  - @types/jsonwebtoken で型定義を追加
  - メンテナンス頻度が低下傾向
- **評価**: レガシーコードでは引き続き使用可能だが、新規では jose を推奨

### passport-jwt
- **週間 DL**: 約 240 万
- **GitHub Stars**: 1,984
- **特徴**:
  - Passport.js エコシステムの JWT Strategy
  - 複数認証方式を統一的に扱える
  - 設定が冗長になりがち
- **評価**: Passport.js を既に使っている場合のみ検討

### express-jwt
- **週間 DL**: 約 62 万
- **GitHub Stars**: 4,513
- **特徴**:
  - Express ミドルウェアとして JWT 検証を提供
  - 内部で jsonwebtoken を使用
  - req.auth にデコード結果を格納
- **評価**: シンプルな検証のみなら便利だが、jose で自作する方が柔軟

## 推奨

| シナリオ | 推奨ライブラリ |
|----------|---------------|
| 新規 Express + TypeScript プロジェクト | **jose** |
| 既存 jsonwebtoken プロジェクトの移行 | **jose**（段階的移行） |
| Passport.js 利用中 | **passport-jwt**（既存統合） |
| 最小限の検証ミドルウェア | **express-jwt** |

## Sources
- https://npm-compare.com/express-jwt,jose,jsonwebtoken,jwa,passport-jwt
- https://dev.to/silentwatcher_95/why-you-should-delete-jsonwebtoken-in-2025-1o7n
- https://joodi.medium.com/jose-vs-jsonwebtoken-why-you-should-switch-4f50dfa3554c
