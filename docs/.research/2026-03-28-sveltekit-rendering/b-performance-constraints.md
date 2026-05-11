# b. SSR/SSG/ISR 各戦略のパフォーマンス特性・制約・対応アダプター

## 収集した事実

### SvelteKit のレンダリングモデル（公式ドキュメント）

- SvelteKit のデフォルトは SSR + CSR のハイブリッド: 最初のページを SSR で配信し、以降のナビゲーションは CSR で行う
  - source: https://svelte.dev/docs/kit/project-types
- `adapter-static` を使うと完全な SSG（静的サイト生成）になる。また `prerender` ページオプションで特定ページのみ事前レンダリングし、他のページは動的 SSR にできる
  - source: https://svelte.dev/docs/kit/project-types
- ISR（Incremental Static Regeneration）は Vercel の adapter が提供する機能であり、大規模な静的サイトでビルド時間を短縮するために利用できる
  - source: https://svelte.dev/docs/kit/project-types
- SPA モードも可能: CSR のみを使い、外部バックエンドと組み合わせる
  - source: https://svelte.dev/docs/kit/project-types
- ページオプション `ssr`, `csr`, `prerender` でルートごとにレンダリング戦略を切り替え可能
  - source: https://svelte.dev/docs/kit/project-types

### 公式アダプター一覧

- `@sveltejs/adapter-cloudflare` — Cloudflare Workers / Cloudflare Pages 向け
- `@sveltejs/adapter-netlify` — Netlify 向け
- `@sveltejs/adapter-node` — Node.js サーバー向け
- `@sveltejs/adapter-static` — SSG（静的サイト生成）専用
- `@sveltejs/adapter-vercel` — Vercel 向け
  - source: https://svelte.dev/docs/kit/adapters

### adapter-vercel: ISR・パフォーマンス特性・制約

- ISR は `isr` プロパティをルート設定で指定して有効化する。`expiration`（秒数）でキャッシュ期間を設定し、`bypassToken`（32文字以上）でオンデマンド再検証が可能
  - source: https://svelte.dev/docs/kit/adapter-vercel
- ISR の制約: 「全訪問者が同じコンテンツを見るルートにのみ使用すること。セッション cookie などユーザー固有の処理は JavaScript でクライアント側のみで行う必要がある（情報漏洩防止）」
  - source: https://svelte.dev/docs/kit/adapter-vercel
- ISR は `export const prerender = true` のルートには効果がない（ビルド時にコンパイル済みのため）
  - source: https://svelte.dev/docs/kit/adapter-vercel
- `allowQuery` で ISR キャッシュキーに含めるクエリパラメータを制御できる。指定外のパラメータは無視される
  - source: https://svelte.dev/docs/kit/adapter-vercel
- Edge Functions と Node.js Serverless Functions の2つのランタイムをサポート
  - source: https://svelte.dev/docs/kit/adapter-vercel
- Serverless Function の制限（SvelteKit ドキュメント記載値）: メモリ 1024MB（デフォルト）、最大実行時間 Hobby=10s / Pro=15s / Enterprise=900s。ただし Vercel 公式 limits ページ（Fluid Compute 有効時）では Hobby=300s / Pro・Enterprise=最大800s と大幅に増加しており、SvelteKit ドキュメントの値はレガシーの可能性がある
  - source: https://svelte.dev/docs/kit/adapter-vercel, https://vercel.com/docs/functions/limitations
- Edge Functions は `fs` モジュールを使用できない。`$app/server` の `read()` を使う必要がある
  - source: https://svelte.dev/docs/kit/adapter-vercel
- `split` オプションでルートごとに個別の関数をデプロイ可能
  - source: https://svelte.dev/docs/kit/adapter-vercel

### adapter-node: パフォーマンス特性・制約

- スタンドアロン Node.js サーバーを生成。Express / Connect / Polka / ネイティブ Node HTTP と互換性のあるハンドラーをエクスポート
  - source: https://svelte.dev/docs/kit/adapter-node
- レスポンスはデフォルトでストリーミング配信される
  - source: https://svelte.dev/docs/kit/adapter-node
- 圧縮は Node.js のシングルスレッド制約のため、リバースプロキシ層で行うことを推奨。直接ミドルウェアを使う場合は `@polka/compression` を使用（`compression` パッケージはストリーミング非対応でエラーになる）
  - source: https://svelte.dev/docs/kit/adapter-node
- Graceful shutdown: 新規リクエスト拒否 → 既存リクエスト完了待ち → SHUTDOWN_TIMEOUT（デフォルト30秒）後に強制切断の3段階
  - source: https://svelte.dev/docs/kit/adapter-node
- systemd ソケットアクティベーション対応。`IDLE_TIMEOUT` で非アクティブ時に自動スリープし、コンテナ環境でのリソース削減が可能
  - source: https://svelte.dev/docs/kit/adapter-node
- `BODY_SIZE_LIMIT` デフォルト 512KB（ストリーミング中を含む）。K/M/G サフィックス対応
  - source: https://svelte.dev/docs/kit/adapter-node
- `precompress` オプション（デフォルト true）で gzip / brotli の事前圧縮ファイルを生成
  - source: https://svelte.dev/docs/kit/adapter-node
- `.env` ファイルは本番環境では自動ロードされない。`dotenv` パッケージまたは Node v20.6+ の `--env-file` フラグが必要
  - source: https://svelte.dev/docs/kit/adapter-node
- URL 解決の問題: ORIGIN やヘッダーの設定が不正だと form action で「Cross-site POST form submissions are forbidden」エラーが発生する
  - source: https://svelte.dev/docs/kit/adapter-node

### adapter-static: パフォーマンス特性・制約

- 完全に静的なファイル群（HTML, CSS, JS）を出力。任意の静的ホスティングにデプロイ可能
  - source: https://svelte.dev/docs/kit/adapter-static
- 制約: デフォルトではアプリ全体がプリレンダリング可能であることが要求される（`strict: true`）。動的ルートとの混在は不可（混在が必要な場合は別のアダプターを使う）
  - source: https://svelte.dev/docs/kit/adapter-static
- SPA フォールバック（`200.html` / `404.html`）を指定可能だが、「パフォーマンスと SEO に大きな悪影響がある」と公式ドキュメントで警告されている
  - source: https://svelte.dev/docs/kit/adapter-static
- `ssr` オプションを `false` にすると空のシェルページが生成されてしまう。SSR は有効のままにする必要がある
  - source: https://svelte.dev/docs/kit/adapter-static
- ホストが `/a` リクエストから `/a.html` を解決しない場合は `trailingSlash: 'always'` を設定する必要がある
  - source: https://svelte.dev/docs/kit/adapter-static
- `precompress: false`（デフォルト）。有効にすると `.br` / `.gz` 圧縮ファイルを生成
  - source: https://svelte.dev/docs/kit/adapter-static

### adapter-cloudflare: パフォーマンス特性・制約

- SSR をデフォルトでサポート。アプリを単一の `_worker.js` にコンパイル
  - source: https://svelte.dev/docs/kit/adapter-cloudflare
- プラットフォームバインディング: KV, Durable Objects, Cache API, R2 などの Cloudflare ランタイム機能にアクセス可能
  - source: https://svelte.dev/docs/kit/adapter-cloudflare
- Worker サイズ制限あり。大きなライブラリはクライアントサイドのみで使用する必要がある
  - source: https://svelte.dev/docs/kit/adapter-cloudflare
- `fs` モジュール使用不可。`$app/server` の `read()` を使う
  - source: https://svelte.dev/docs/kit/adapter-cloudflare
- `routes.exclude` のルール数上限: include と exclude 合わせて 100 ルールまで
  - source: https://svelte.dev/docs/kit/adapter-cloudflare
- 旧 `adapter-cloudflare-workers` は非推奨。現行は Workers Static Assets と Cloudflare Pages を対象としている
  - source: https://svelte.dev/docs/kit/adapter-cloudflare

### ページオプションの詳細と制約

- `prerender` のデフォルトは `false`。`true` / `false` / `'auto'` の3値をとる。`'auto'` はプリレンダリングしつつ動的フォールバックのためにマニフェストにも残す
  - source: https://svelte.dev/docs/kit/page-options
- プリレンダリングの制約: 全ユーザーに同一コンテンツを返すページでなければならない。form action を持つページはプリレンダリング不可（サーバーが POST を処理する必要があるため）
  - source: https://svelte.dev/docs/kit/page-options
- `ssr: false` のページはプリレンダリングできない
  - source: https://svelte.dev/docs/kit/page-options
- プリレンダリング中は `url.searchParams` にアクセスできない。ブラウザ専用コード（`onMount` 内等）に限定する必要がある
  - source: https://svelte.dev/docs/kit/page-options
- プリレンダリングされたルートはサーバー/サーバーレス関数のサイズを削減し、静的ファイル配信で劇的に高速化する
  - source: https://svelte.dev/docs/kit/page-options
- `ssr` のデフォルトは `true`。`false` にすると空のシェルページが配信され、初期表示パフォーマンスと SEO が犠牲になる
  - source: https://svelte.dev/docs/kit/page-options
- ルートレイアウトで `ssr = false` を設定するとアプリ全体が SPA になり、SSG が不可能になる
  - source: https://svelte.dev/docs/kit/page-options
- `csr` のデフォルトは `true`。`false` にすると JavaScript がクライアントに一切配信されない。フォームのプログレッシブエンハンスメントも無効化され、ナビゲーションはフルページリロードになる
  - source: https://svelte.dev/docs/kit/page-options
- `csr: false` はインタラクティビティ不要なページ（ブログ記事等）に有効。`export const csr = dev;` パターンで開発時のみ HMR を有効にできる
  - source: https://svelte.dev/docs/kit/page-options
- `trailingSlash` はプリレンダリングのファイル出力に影響: `'always'` → `about/index.html`、`'never'` → `about.html`
  - source: https://svelte.dev/docs/kit/page-options
- レイアウトのカスケード: 子レイアウト/ページが親の設定をオーバーライド可能。プリレンダリングしたマーケティングサイト + SSR の動的コンテンツ + CSR のみの管理画面を1つのアプリに混在できる
  - source: https://svelte.dev/docs/kit/page-options

### SSR パフォーマンスベンチマーク（6フレームワーク比較）

- テスト条件: Google Lighthouse（web.dev/measure）で5回実行し平均値。TTFB は `hey` ツールで250リクエスト（同時1ワーカー）をローカル送信。全フレームワーク SSR 構成、Tailwind CSS + Enterspeed をコンテンツソースとして使用
  - source: https://www.enterspeed.com/blog/we-measured-the-ssr-performance-of-6-js-frameworks-heres-what-we-found
- SvelteKit の SSR ベンチマーク結果:
  - Lighthouse Performance Score: 99（2位）
  - FCP: 0.9s（2位タイ）
  - LCP: 0.9s（2位）
  - TBT: 36ms（5位）
  - Speed Index: 2.3s（1位）
  - TTI: 1.0s（2位）
  - TTFB: 62ms（1位）
  - CLS: 0
  - source: https://www.enterspeed.com/blog/we-measured-the-ssr-performance-of-6-js-frameworks-heres-what-we-found

### adapter-netlify: パフォーマンス特性・制約

- Node ベースの Serverless Functions（デフォルト）と Deno ベースの Edge Functions の2モードをサポート
  - source: https://svelte.dev/docs/kit/adapter-netlify
- Edge Functions: 「サイト訪問者に地理的に近い場所で SSR を実行する Deno ベースのエッジ関数」。`edge: true` で有効化
  - source: https://svelte.dev/docs/kit/adapter-netlify
- `split` オプションでルートごとに個別の関数に分割可能（ただし Edge Functions 使用時は `split` 不可）
  - source: https://svelte.dev/docs/kit/adapter-netlify
- Edge デプロイでは `fs` モジュール使用不可。Serverless デプロイでもファイルがデプロイにコピーされないため `fs` アクセスに制限あり。`$app/server` の `read()` を使うか、プリレンダリングで対応
  - source: https://svelte.dev/docs/kit/adapter-netlify
- ISR サポートについて: 公式ドキュメントに明示的な記載なし（未確認）
  - source: https://svelte.dev/docs/kit/adapter-netlify

### ストリーミング SSR とパフォーマンス最適化

- SvelteKit の `load` 関数で Promise を await せずに返すことで、結果をクライアントにストリーミング配信できる。サーバーが全データを待つブロッキングウォーターフォールを排除する
  - source: https://sveltekit.io/blog/make-your-sveltekit-app-faster
- `@sveltejs/enhanced-img` パッケージでビルド時に静的画像を `.avif` / `.webp` に最適化・自動サイズ調整が可能（ユーザー生成コンテンツには使用不可）
  - source: https://sveltekit.io/blog/make-your-sveltekit-app-faster
- `load` 関数内で複数の Promise を順次 await するとウォーターフォールが発生する。非重要データはクライアントコンポーネントからフェッチするか、ストリーミングで配信すべき
  - source: https://sveltekit.io/blog/make-your-sveltekit-app-faster
- ストリーミングレスポンスの制約: AWS Lambda ベースのプラットフォーム（サーバーレス関数等）はストリーミングをサポートしない。従来型の Node.js サーバーやエッジベースのランタイムはサポートする
  - source: https://svelte.dev/blog/streaming-snapshots-sveltekit

### SvelteKit 組み込みのパフォーマンス最適化

- コード分割: 現在のページに必要なコードのみがロードされる
  - source: https://svelte.dev/docs/kit/performance
- アセットプリロード: ファイルが別のファイルをリクエストするウォーターフォールを防止
  - source: https://svelte.dev/docs/kit/performance
- ファイルハッシュ: アセットの永続キャッシュを有効化
  - source: https://svelte.dev/docs/kit/performance
- リクエスト結合: 複数のサーバー load 関数からのデータを単一の HTTP リクエストにまとめる
  - source: https://svelte.dev/docs/kit/performance
- 並列ロード: 独立した universal load 関数を同時実行
  - source: https://svelte.dev/docs/kit/performance
- データインライン化: SSR 中の fetch リクエストをブラウザで再実行せずリプレイする
  - source: https://svelte.dev/docs/kit/performance
- SPA モードでは空のページが最初にフェッチされ、その後 JavaScript をフェッチするため追加のラウンドトリップが発生する
  - source: https://svelte.dev/docs/kit/performance
- Vite のコード分割は多数の小ファイルを生成するため、最適なパフォーマンスには HTTP/2 以上が必要
  - source: https://svelte.dev/docs/kit/performance

### Cloudflare Workers のデプロイ制約（adapter-cloudflare 利用時）

- Worker スクリプトサイズ: Free プラン 3MB（gzip 圧縮後）/ 64MB（非圧縮）、Paid プラン 10MB（gzip）/ 64MB（非圧縮）
  - source: https://developers.cloudflare.com/workers/platform/limits/
- 「大きな Worker バンドルは起動時間に影響する」。設定や静的ファイルは R2 / KV / Workers Static Assets に外部化することを推奨
  - source: https://developers.cloudflare.com/workers/platform/limits/
- CPU 時間: Free プラン 10ms/リクエスト、Paid プラン 最大5分（デフォルト30秒）。SSR やアクセス認証のロジックは通常 10-20ms を消費する
  - source: https://developers.cloudflare.com/workers/platform/limits/
- メモリ: 128MB/isolate（両プラン共通）。超過時は実行中のリクエスト完了後に新しい isolate を作成
  - source: https://developers.cloudflare.com/workers/platform/limits/
- 起動時間: グローバルスコープの実行に最大1秒
  - source: https://developers.cloudflare.com/workers/platform/limits/
- サブリクエスト: Free プラン 50/リクエスト、Paid プラン 10,000/リクエスト
  - source: https://developers.cloudflare.com/workers/platform/limits/
- 日次リクエスト: Free プランのみ 100,000/日の制限あり
  - source: https://developers.cloudflare.com/workers/platform/limits/

### Vercel Functions のデプロイ制約（adapter-vercel 利用時）

- バンドルサイズ上限: 非圧縮 250MB（AWS Lambda の制限に準拠）
  - source: https://vercel.com/docs/functions/limitations
- メモリ: Hobby 最大 2GB/1vCPU、Pro/Enterprise 最大 4GB/2vCPU
  - source: https://vercel.com/docs/functions/limitations
- 最大実行時間（Fluid Compute 有効時）: Hobby 300s（5分）、Pro/Enterprise 最大 800s（13分）
  - source: https://vercel.com/docs/functions/limitations
- Edge Runtime: レスポンス開始まで25秒以内でなければならない。ストリーミングは最大300秒まで継続可能
  - source: https://vercel.com/docs/functions/limitations
- リクエスト/レスポンスボディサイズ上限: 4.5MB。超過時は 413 エラー
  - source: https://vercel.com/docs/functions/limitations
- ファイルディスクリプタ: 全同時実行で共有の 1,024 個。ランタイム自体の使用分を含む
  - source: https://vercel.com/docs/functions/limitations
- 同時実行数: Hobby/Pro 最大 30,000、Enterprise 100,000+（自動スケール）
  - source: https://vercel.com/docs/functions/limitations
- 課金: アクティブ CPU 時間と確保メモリ時間で課金。I/O 待ち（AI モデル呼び出し、DB クエリ等）は CPU 時間に含まれない
  - source: https://vercel.com/docs/functions/limitations

### 各戦略のパフォーマンス特性まとめ（対応アダプター）

- SSG（プリレンダリング）: 全アダプターで利用可能。静的ファイル配信のため TTFB が最小。CDN キャッシュと最も親和性が高い。制約: ビルド時に全ページ生成が必要でビルド時間が増加する。動的コンテンツ不可
  - source: https://svelte.dev/docs/kit/page-options, https://svelte.dev/docs/kit/adapter-static
- SSR: adapter-node, adapter-vercel, adapter-cloudflare, adapter-netlify で利用可能。adapter-static では不可。リクエスト時にサーバーでレンダリングするため TTFB は SSG より遅いが、動的コンテンツ対応可能
  - source: https://svelte.dev/docs/kit/project-types, https://svelte.dev/docs/kit/adapters
- ISR: adapter-vercel のみ。SSG のパフォーマンスと動的レンダリングの柔軟性を両立。expiration 秒数後にバックグラウンドで再生成。制約: ユーザー固有コンテンツは使用不可
  - source: https://svelte.dev/docs/kit/adapter-vercel
- ストリーミング SSR: adapter-node とエッジランタイム（adapter-cloudflare, adapter-vercel edge, adapter-netlify edge）で利用可能。AWS Lambda ベースのサーバーレス関数ではストリーミング不可
  - source: https://svelte.dev/blog/streaming-snapshots-sveltekit
