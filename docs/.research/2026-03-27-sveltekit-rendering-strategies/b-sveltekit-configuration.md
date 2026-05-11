# SvelteKit での各戦略の設定方法

## ページオプション export

`+page.js` / `+page.ts` / `+page.server.js` / `+page.server.ts` から export する。
`+layout.js` / `+layout.ts` でも設定可能（配下の全ページに適用）。

### SSR（デフォルトで有効）

```ts
// +page.ts
export const ssr = true;  // デフォルト（省略可）
export const ssr = false; // SSR を無効化（空のシェルを返す）
```

- `ssr = false` にすると空の HTML シェルが返り、JS でクライアント描画
- SEO・アクセシビリティに悪影響。公式は非推奨

### SSG（prerender）

```ts
// +page.ts
export const prerender = true;   // ビルド時に HTML 生成
export const prerender = false;  // 動的 SSR のみ
export const prerender = 'auto'; // prerender と SSR の両方で利用可能
```

- `prerender = true` のルートは動的 SSR マニフェストから除外され、サーバーバンドルが軽量化
- `adapter-static` を使うと全ページを強制的にプリレンダリング

### CSR

```ts
// +page.ts
export const csr = false; // JS ハイドレーションを無効化
```

- `csr = false` で JS を一切送信しない（完全静的 HTML）
- フォームのプログレッシブエンハンスメント・SPA ナビゲーション不可

### ISR（adapter-vercel 限定）

```ts
// +page.server.ts
export const config = {
  isr: {
    expiration: 60,                    // 秒単位のキャッシュ有効期限（必須）
    bypassToken: 'your-32char-token',  // on-demand revalidation 用（任意）
    allowQuery: ['search']             // キャッシュキーに含める query パラメータ（任意）
  }
};
```

- `expiration: false` でキャッシュを無期限に（bypass token と組み合わせて手動更新）
- `prerender = true` のルートでは ISR 設定は無視される
- ユーザー固有データのあるページには使わない（キャッシュがリークする）

## アダプター別の挙動差異

| アダプター | SSR | SSG | ISR | 備考 |
|-----------|-----|-----|-----|------|
| adapter-node | ○ | ○ | × | 自前サーバー / Docker |
| adapter-vercel | ○ | ○ | ○ | Serverless + Edge 対応 |
| adapter-netlify | ○ | ○ × | Serverless + Edge |
| adapter-cloudflare | ○ | ○ | × | Cloudflare Workers |
| adapter-static | × | ○（全ページ） | × | 純粋な静的サイト |
| adapter-auto | 環境依存 | 環境依存 | 環境依存 | デプロイ先に自動適応 |

## Sources

- https://svelte.dev/docs/kit/page-options
- https://svelte.dev/docs/kit/adapter-vercel
- https://svelte.dev/docs/kit/project-types
