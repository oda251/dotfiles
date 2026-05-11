# a. SSR/SSG/ISR 各戦略の仕組みと SvelteKit での設定方法

調査観点: SSR/SSG/ISR 各戦略の仕組みと SvelteKit での設定方法

---

## Source 1: SvelteKit 公式 — Page options

URL: https://svelte.dev/docs/kit/page-options

### SSR (Server-Side Rendering)

- SvelteKit のデフォルトでは SSR が有効（`ssr = true`）。リクエストごとにサーバー上で HTML を生成し、クライアントに返す
- `+page.js`、`+page.server.js`、`+layout.js`、`+layout.server.js` から `export const ssr = false;` で無効化できる
- `ssr = false` にすると、サーバーでは HTML を生成せず、クライアント側のみでレンダリングする（SPA 的挙動）
- ルートレイアウトで `ssr = false` にするとアプリ全体が SPA になる。公式は「not recommended」としている

### CSR (Client-Side Rendering / Hydration)

- デフォルトで有効（`csr = true`）。サーバーで生成された HTML をクライアントで hydrate し、インタラクティブにする
- `export const csr = false;` で無効化可能。無効時は JS がクライアントに送信されない、`<script>` タグが除去される、フォームの progressive enhancement が無効、リンクがフルページナビゲーションになる、HMR も無効
- 開発時だけ CSR を有効にするパターン: `import { dev } from '$app/environment'; export const csr = dev;`

### prerender (SSG: Static Site Generation)

- デフォルトは `false`。`export const prerender = true;` でビルド時に静的 HTML を生成する
- `prerender = 'auto'` にすると、プリレンダリングしつつ SSR マニフェストにも残す（動的サーバーレンダリングも可能）
- プリレンダラはルートから `<a>` リンクをクロールして対象ページを発見する
- 動的ルートのプリレンダリングには `entries()` 関数でエントリーポイントを指定する:
  ```js
  export function entries() {
    return [
      { slug: 'hello-world' },
      { slug: 'another-post' }
    ];
  }
  export const prerender = true;
  ```
- form actions を持つページはプリレンダリング不可（POST 処理が必要なため）
- `url.searchParams` に依存するコンテンツはプリレンダリング時に禁止
- パーソナライズされたコンテンツもプリレンダリングに不向き

### trailingSlash

- デフォルトは `'never'`。`'always'` にすると `about/index.html` を生成、それ以外は `about.html` を生成
- `'ignore'` は相対パスのセマンティクスの違いから「not recommended」

### config（アダプター固有設定）

- `export const config` でアダプター固有の設定をページ/レイアウト単位で指定可能
- 例: `runtime: 'edge'` でエッジランタイムを選択
- トップレベル値はマージされるが、ネストされたオブジェクトは指定キーのみ上書き

### オプション間の相互作用

- `ssr = false` かつ `csr = false` にすると何もレンダリングされない
- SvelteKit はルートごとに異なる戦略を混在させることが可能。公式曰く「マーケティングページをプリレンダリングし、動的ページを SSR し、管理画面を SPA にできる」

---

## Source 2: SvelteKit 公式 — Adapters

URL: https://svelte.dev/docs/kit/adapters

- アダプターはビルド済み SvelteKit アプリをデプロイターゲット向けに変換する小さなプラグイン
- 公式アダプター 5 種:
  1. `@sveltejs/adapter-cloudflare` — Cloudflare Workers / Pages
  2. `@sveltejs/adapter-netlify` — Netlify
  3. `@sveltejs/adapter-node` — Node.js サーバー
  4. `@sveltejs/adapter-static` — 静的サイト生成 (SSG)
  5. `@sveltejs/adapter-vercel` — Vercel
- コミュニティ製アダプターも存在する
- 設定は `svelte.config.js` の `kit.adapter` で行う:
  ```js
  import adapter from 'svelte-adapter-foo';
  export default { kit: { adapter: adapter({ /* options */ }) } };
  ```
- 一部アダプターは `RequestEvent.platform` でプラットフォーム固有情報（例: Cloudflare KV）にアクセスできる

---

## Source 3: SvelteKit 公式 — adapter-static

URL: https://svelte.dev/docs/kit/adapter-static

- adapter-static はアプリ全体を静的ファイルとしてプリレンダリングする SSG アダプター
- 一部だけプリレンダリングしたい場合は、別のアダプターで `prerender` オプションを使うべき
- 設定:
  ```js
  import adapter from '@sveltejs/adapter-static';
  export default {
    kit: {
      adapter: adapter({
        pages: 'build',       // プリレンダリング出力先（デフォルト: build）
        assets: 'build',      // 静的アセット出力先（デフォルト: pages と同じ）
        fallback: undefined,  // SPA 用フォールバックページ（200.html や 404.html）
        precompress: false,   // .br / .gz 圧縮ファイルを生成するか
        strict: true          // 全ページがプリレンダリング済みか検証（デフォルト: true）
      })
    }
  };
  ```
- ルートの `+layout.js` (または `+layout.server.js`) に `export const prerender = true;` を追加する必要がある
- `ssr = false` にすると空の HTML シェルしか生成されないため不可
- `trailingSlash` はホスティング環境に合わせる必要がある
- `fallback` を指定すると SPA モードとして動作（フォールバックページを返す）
- Vercel ではゼロコンフィグデプロイが可能

---

## Source 4: SvelteKit 公式 — adapter-vercel（ISR サポート）

URL: https://svelte.dev/docs/kit/adapter-vercel

### ISR (Incremental Static Regeneration) の仕組み

- Vercel アダプターは ISR をネイティブサポートしている。公式曰く「プリレンダリングのパフォーマンスとコスト面の利点を、動的レンダリングの柔軟性と組み合わせたもの」
- ISR はすべての訪問者に同一コンテンツを返すルートに適する。ユーザー固有の処理（セッション Cookie 等）はクライアント側 JS でのみ行うべき（情報漏洩リスク）
- **`prerender = true` のページでは ISR 設定は無視される**（重要な制約）

### ISR の設定方法

- ルートの `+page.js` または `+layout.js` で `config` をエクスポートする:
  ```js
  export const config = {
    isr: {
      expiration: 60,                    // 秒数。キャッシュ再生成までの時間
      bypassToken: BYPASS_TOKEN,         // オンデマンド再生成用トークン（32文字以上）
      allowQuery: ['search']             // キャッシュキーに含めるクエリパラメータ
    }
  };
  ```
- `expiration`: 必須。秒数を指定。`false` にすると無期限キャッシュ（bypassToken でオンデマンド再生成）
- `bypassToken`: 任意。`__prerender_bypass=<token>` Cookie でキャッシュをバイパス。`crypto.randomUUID()` で生成推奨
- `allowQuery`: 任意。指定したクエリパラメータのみキャッシュキーに含む。UTM パラメータ等による不要な再生成を防止。デフォルトは全クエリパラメータを無視

### ランタイムオプション

- `runtime`: `'edge'`、`'nodejs20.x'`、`'nodejs22.x'` から選択。デフォルトは Vercel プロジェクト設定に準ずる。deprecated 予定
- `regions`: Serverless はエッジネットワークリージョン配列（デフォルト `["iad1"]`）、Edge は `'all'`。Enterprise プランで複数リージョン対応
- `split`: `true` にすると個別ルートを別々の関数としてデプロイ
- `memory`: Serverless の場合 128–3008 MB（デフォルト 1024 MB）
- `maxDuration`: アカウントティアにより 10–900 秒

---

## Source 5: SvelteKit 公式 — adapter-netlify

URL: https://svelte.dev/docs/kit/adapter-netlify

- Netlify アダプターは SSR を Serverless Functions（デフォルト）または Edge Functions で実行可能
- Edge Functions は `edge: true` で有効化。Deno ベースで地理的に近い場所で実行され、動的コンテンツのレイテンシが改善
- 設定:
  ```js
  import adapter from '@sveltejs/adapter-netlify';
  export default {
    kit: {
      adapter: adapter({
        edge: false,   // Edge Functions を使うか
        split: false   // 複数関数に分割するか（edge: true とは併用不可）
      })
    }
  };
  ```
- **Netlify は ISR をネイティブサポートしていない**（SvelteKit adapter-netlify のドキュメントに ISR への言及なし）
- Edge デプロイでは Node.js の `fs` モジュール使用不可。`$app/server` の `read` 関数で代替
- Netlify Forms はプリレンダリングされた HTML ページが必要（`prerender = true` が必須）

---

## Source 6: SvelteKit 公式 — adapter-cloudflare

URL: https://svelte.dev/docs/kit/adapter-cloudflare

- Cloudflare Workers / Pages 向けの SSR アダプター
- Workers は "Workers Static Assets" で動的リクエスト処理、Pages は `_worker.js` をビルド
- **Cloudflare アダプターは ISR をサポートしていない**
- `fallback` オプション: `'plaintext'`（デフォルト、404 テキスト）または `'spa'`（SPA フォールバック）
- Pages ではルート設定（`include` / `exclude`）が可能。最大 100 ルール
- `platform` オブジェクトで KV、Durable Objects 等の Cloudflare ランタイム API にアクセス可能

---

## Source 7: SvelteKit 公式 — Load

URL: https://svelte.dev/docs/kit/load

### Universal load 関数と Server load 関数の違い

- **Universal load** (`+page.js`, `+layout.js`): SSR 時はサーバーで実行、その後ブラウザで hydration 時に再実行。クライアントサイドナビゲーション時はブラウザで実行
- **Server load** (`+page.server.js`, `+layout.server.js`): 常にサーバー側でのみ実行。devalue でシリアライズ可能なデータのみ返却可（JSON, BigInt, Date, Map, Set, RegExp）
- Server load は `cookies`、`locals`、`clientAddress`、`platform`、`request` にアクセス可能
- Universal load は非シリアライズ可能データ（カスタムクラス、コンポーネントコンストラクタ）を返却可能

### SSR 時の実行順序

1. Server load 関数が最初に実行
2. Universal load 関数がサーバー上で実行（SSR の fetch レスポンスを再利用）
3. Hydration 時にブラウザで universal load が再実行（キャッシュされた fetch データを使用）

### クライアントサイドナビゲーション時

- 新ルートに該当する universal / server load のみ実行
- Universal load はブラウザで実行、server load はネットワークリクエスト経由
- 結果はキャッシュされ冗長なネットワーク呼び出しを防止

### 使い分け

- Server load: DB アクセス、プライベート環境変数、機密処理
- Universal load: 認証不要な外部 API fetch、非シリアライズ可能オブジェクトの返却
- 両方使う場合: server load の戻り値が universal load の `data` プロパティ引数になる

---

## Source 8: SvelteKit 公式 — adapter-node

URL: https://svelte.dev/docs/kit/adapter-node

- adapter-node はスタンドアロンの Node.js サーバーを生成する SSR アダプター
- 設定:
  ```js
  import adapter from '@sveltejs/adapter-node';
  export default {
    kit: {
      adapter: adapter({
        out: 'build',          // 出力ディレクトリ（デフォルト: build）
        precompress: true,     // gzip / brotli 圧縮（デフォルト: true）
        envPrefix: ''          // 環境変数プレフィックス
      })
    }
  };
  ```
- 環境変数でサーバー設定: `PORT`（デフォルト 3000）、`HOST`（デフォルト 0.0.0.0）、`SOCKET_PATH`
- リバースプロキシ対応: `ORIGIN`、`PROTOCOL_HEADER`、`HOST_HEADER`、`PORT_HEADER`
- リクエスト制限: `BODY_SIZE_LIMIT`（デフォルト 512kb）
- グレースフルシャットダウン: SIGTERM/SIGINT に対応。`SHUTDOWN_TIMEOUT`（デフォルト 30 秒）
- systemd ソケットアクティベーション対応（`IDLE_TIMEOUT` でオンデマンド起動）
- カスタムサーバー統合: `handler.js` を Express / Polka / Node http.createServer にインポート可能
- **adapter-node は ISR をネイティブサポートしていない**（キャッシュ制御はアプリケーション側やリバースプロキシで実装する必要がある）

---

## Source 9: SvelteKit 公式 — Hooks

URL: https://svelte.dev/docs/kit/hooks

### handle フックと SSR の関係

- `handle` フックはすべてのリクエスト（プリレンダリングフェーズを含む）で実行される
- `event` オブジェクトと `resolve` 関数を受け取り、`resolve` がルートをレンダリングして Response を生成する
- `resolve` を呼ばずにカスタム Response を返すことで SvelteKit のレンダリングをバイパス可能
- `resolve` 後にレスポンスヘッダー/ボディの変更も可能

### resolve のオプション（レンダリング制御）

- `transformPageChunk`: HTML チャンクにカスタム変換を適用。チャンクは `%sveltekit.head%` やレイアウト/ページコンポーネント境界で分割される
- `filterSerializedResponseHeaders`: `load` 関数がリソースを fetch した際にどのヘッダーを含めるか制御（デフォルトはヘッダーなし）
- `preload`: `<head>` タグに追加するプリロード対象（`js`, `css`, `font`, `asset`）を制御
- プリレンダリング中のフック実行を除外するには `building` プロパティを確認する

---

## Source 10: SvelteKit 公式 — Glossary: Prerendering

URL: https://svelte.dev/docs/kit/glossary#Prerendering

### プリレンダリングの仕組み（詳細）

- ビルド時にページの内容を計算し HTML として保存する。リクエストごとの再計算が不要
- 生成された静的サイトは CDN から配信でき、TTFB（Time to First Byte）に優れる
- 訪問者数が増えても「ほぼ無料で」スケールするが、ビルドプロセスは重くなる
- プリレンダリング可能な条件: 同一 URL に直接アクセスした全ユーザーが同一のサーバーコンテンツを受け取ること
- form actions を含むページはプリレンダリング不可
- パーソナライズはクライアント側 JS で行えば可能だが、SSR のパフォーマンスメリットは失われる
- **プリレンダリング済みコンテンツの更新には新たなビルド＆デプロイが必要**（動的に更新できない。これが ISR との根本的な違い）
- 全ページをプリレンダリングすると Static Site Generation (SSG) = "JAMstack" と呼ばれる

---

## 要点整理

### SSR の仕組みと設定

| 項目 | 内容 | ソース |
|---|---|---|
| デフォルト動作 | SSR 有効 (`ssr = true`)。リクエストごとにサーバーで HTML 生成 | page-options |
| 無効化 | `export const ssr = false` で SPA 化 | page-options |
| load 関数 | server load → universal load の順で実行。hydration 時に universal load 再実行 | load |
| handle フック | 全リクエストで実行。`resolve` で SSR を実行、カスタム Response も返却可 | hooks |
| アダプター | adapter-node / adapter-vercel / adapter-netlify / adapter-cloudflare いずれも SSR 対応 | adapters |

### SSG (Prerendering) の仕組みと設定

| 項目 | 内容 | ソース |
|---|---|---|
| 仕組み | ビルド時に HTML 生成・保存。CDN 配信で TTFB 最良 | glossary |
| 設定 | `export const prerender = true` でルートごとに指定 | page-options |
| 全ページ SSG | adapter-static + ルートレイアウトに `prerender = true` | adapter-static |
| 部分的 SSG | 他アダプターで一部ルートだけ `prerender = true` | adapter-static |
| `prerender = 'auto'` | プリレンダリングしつつ SSR マニフェストにも残す | page-options |
| 制約 | form actions 不可、searchParams 依存不可、更新にはリビルド必要 | page-options, glossary |

### ISR の仕組みと設定

| 項目 | 内容 | ソース |
|---|---|---|
| 仕組み | 初回リクエストで SSR し結果をキャッシュ。`expiration` 秒後に次のリクエストで再生成 | adapter-vercel |
| SvelteKit 対応 | **Vercel アダプターのみネイティブ対応** | adapter-vercel |
| 設定 | `export const config = { isr: { expiration: 60 } }` | adapter-vercel |
| `prerender = true` との併用 | 不可。prerender されたページは ISR 設定を無視 | adapter-vercel |
| Netlify | ISR 非対応（ドキュメントに言及なし） | adapter-netlify |
| Cloudflare | ISR 非対応 | adapter-cloudflare |
| adapter-node | ISR 非対応（リバースプロキシ等で自前実装が必要） | adapter-node |

### 戦略の混在

- SvelteKit はルート単位で SSR / SSG / ISR / SPA を混在可能（page-options）
- レイアウトで設定した値は子ルートに継承されるが、子ルートで上書き可能（page-options）
