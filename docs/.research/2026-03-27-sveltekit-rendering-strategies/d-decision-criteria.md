# 選定判断基準

## 判断フロー

```
1. コンテンツは全ユーザーに同一か？
   ├─ NO → SSR（パーソナライズが必要）
   └─ YES → 2へ

2. コンテンツの更新頻度は？
   ├─ ほぼ変わらない（日〜週単位以下）→ SSG
   ├─ 定期的に変わる（分〜時間単位）→ 3へ
   └─ リアルタイムで変わる（秒単位）→ SSR

3. Vercel にデプロイ可能か？
   ├─ YES → ISR
   └─ NO → SSR（キャッシュヘッダーで CDN キャッシュを活用）
```

## 判断軸の詳細

### コンテンツ更新頻度
- **静的**（ドキュメント、LP）→ SSG
- **準静的**（ブログ、商品カタログ）→ ISR or SSG + 再ビルド
- **動的**（検索結果、ダッシュボード）→ SSR

### パーソナライズ要否
- **不要**（全ユーザー同一）→ SSG / ISR
- **必要**（ログイン状態、ユーザー設定）→ SSR
- **部分的**（共通コンテンツ + ユーザー固有の小パーツ）→ SSR or SSG + クライアントサイド fetch

### ページ数とビルド規模
- **少〜中規模**（〜数千ページ）→ SSG で問題なし
- **大規模**（万単位）→ ISR でビルド時間を回避、または SSR

### SEO 要件
- **重要**（公開ページ、LP、ブログ）→ SSR / SSG / ISR いずれも OK（`ssr = false` は避ける）
- **不要**（管理画面、ダッシュボード）→ CSR のみ（`ssr = false`）でも可

### インフラ制約
- **Vercel** → SSR / SSG / ISR すべて利用可能
- **自前サーバー / Docker** → adapter-node で SSR + SSG
- **CDN のみ** → adapter-static で SSG 一択

## SvelteKit ならではのポイント

- **ページ単位で混在可能**: マーケティングページは SSG、動的ページは SSR、管理画面は CSR のみ、というハイブリッド構成が1つのプロジェクトで実現できる
- **デフォルトは SSR**: 何も設定しなければ SSR + CSR のハイブリッド（transitional app）
- **ISR は Vercel 限定**: adapter-vercel の config.isr でのみ利用可能。他のアダプターでは SSR + CDN キャッシュ（Cache-Control ヘッダー）で近似可能

## Sources

- https://svelte.dev/docs/kit/page-options
- https://svelte.dev/docs/kit/project-types
- https://svelte.dev/docs/kit/adapter-vercel
- https://dev.to/mandrasch/rich-harris-explains-why-sveltekit-pushes-for-server-side-rendering-and-against-spa-5flj
