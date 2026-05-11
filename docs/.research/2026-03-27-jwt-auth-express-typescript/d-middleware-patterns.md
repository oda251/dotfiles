# ミドルウェア設計パターン

## 認証と認可の分離

### 認証ミドルウェア（Authentication）
- Authorization ヘッダーから Bearer トークンを抽出
- トークンを検証しデコード
- デコード結果を `req.user` に格納
- 無効なトークンの場合 401 Unauthorized を返す

### 認可ミドルウェア（Authorization）
- `req.user` のロール/権限を確認
- 必要な権限が不足していれば 403 Forbidden を返す
- RBAC（Role-Based Access Control）パターンで実装

```typescript
// 認証: トークン検証
const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Token required' });

  try {
    const { payload } = await jwtVerify(token, secret);
    req.user = payload as AuthUser;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// 認可: ロール検証
const authorize = (...roles: Role[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
};
```

## 型安全なリクエスト拡張

```typescript
// Express の Request 型を拡張
interface AuthUser {
  sub: string;
  email: string;
  role: Role;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

// または独自の型付きリクエスト
interface AuthenticatedRequest extends Request {
  user: AuthUser; // optional ではなく必須
}
```

## エラーハンドリング

- トークン期限切れ: 401 + `{ error: 'Token expired' }` → クライアントが Refresh Token で再取得
- 不正トークン: 401 + `{ error: 'Invalid token' }`
- 権限不足: 403 + `{ error: 'Forbidden' }`
- 集約エラーハンドラーでJWT関連エラーを一元処理

## 設計原則

- 署名鍵は環境変数で管理（ハードコーディング厳禁）
- ミドルウェアの適用順序: authenticate → authorize → route handler
- 型の enum で権限を定義し、TypeScript の型チェックを活用

## Sources
- https://auth0.com/blog/node-js-and-typescript-tutorial-secure-an-express-api/
- https://dev.to/gigi_shalamberidze_75f0ac/implementing-secure-authentication-authorization-in-expressjs-with-jwt-typescript-and-prisma-377g
- https://dev.to/julienachmias/authentication-with-jwt-tokens-in-typescript-with-express-3gb1
