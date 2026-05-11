# SSR / SSG / ISR の仕組みと動作原理

## SSR (Server-Side Rendering)

- リクエストごとにサーバーで HTML を生成する
- SvelteKit のデフォルト動作
- 初回ロードは SSR、以降のナビゲーションは CSR（ハイドレーション）で動作する「transitional app」モデル
- SEO に有利（検索エンジンが完全な HTML をクロール可能）
- パーソナライズされたコンテンツやリアルタイムデータに対応
- サーバーが常に必要（コスト・運用負荷あり）

## SSG (Static Site Generation)

- ビルド時に全ページの HTML を事前生成する
- SvelteKit では `prerender = true` または `adapter-static` で実現
- CDN から配信可能で TTFB が最速
- サーバー不要（ホスティングコストが低い）
- コンテンツ更新にはビルド・デプロイが必要
- 大規模サイトではビルド時間が問題になりうる

## ISR (Incremental Static Regeneration)

- 初回リクエスト時に静的ページを生成し、キャッシュする
- 設定した有効期限（expiration）後にバックグラウンドで再生成
- SSG の速度と SSR の鮮度を両立するハイブリッド手法
- SvelteKit では **adapter-vercel 限定**の機能
- `bypassToken` による on-demand revalidation も可能

## Sources

- https://svelte.dev/docs/kit/page-options
- https://svelte.dev/docs/kit/project-types
- https://svelte.dev/docs/kit/glossary
- https://www.pkgpulse.com/blog/ssr-vs-ssg-vs-isr-vs-ppr-rendering-2026
