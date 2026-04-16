# 技術スタック: インフラ

## IaC: Pulumi (TypeScript, Bun runtime) + Pulumi ESC

- インフラは Pulumi で管理する
- ランタイムは Bun（`runtime: bun`）、言語は TypeScript
- state は Pulumi Cloud で管理
- 機密値・設定値は Pulumi ESC に集約し、`Pulumi.<stack>.yaml` の `environment` フィールドで読み込む

### ディレクトリ構成

```
pulumi/
├── Pulumi.yaml              # project 定義（runtime: bun）
├── Pulumi.<stack>.yaml      # stack 設定、ESC env 参照
├── index.ts                 # エントリポイント
├── src/
│   ├── lib/config.ts        # valibot で設定検証、型付き Config エクスポート
│   └── <domain>/            # ドメインごとに分割
└── esc/<env>.yaml           # ESC env のソース（secrets は --secret で別投入）
```

## GitHub 管理: @pulumi/github プロバイダ

- リポジトリ設定、RepositoryRuleset（ブランチ保護）、RepositoryFile（配布 workflow）、RepositoryEnvironment、Actions Secrets/Variables を Pulumi で管理
- main 直プッシュ禁止、PR マージには CI status check 通過を必須にする
- リポジトリ定義は ESC の構造化 config に置き、`src/lib/config.ts` で valibot 検証してから展開
- リポジトリスキーマには boolean フラグを持たせ、リポごとに付与するリソース（環境作成・workflow 配布等）を切り替える。リポ追加時に YAML 1行で付随リソースが揃うようにする

## Pulumi CI/CD

- `.github/workflows/pulumi.yml` 単一ワークフローで preview（PR）と up（main push）を担う
- 主要ステップ:
  - `actions/checkout@v4`
  - `oven-sh/setup-bun@v2` で Bun ランタイム導入
  - `bun install --frozen-lockfile` で依存インストール
  - `actions/cache@v4` で `~/.pulumi/plugins` をキャッシュ（lockfile ハッシュでキー生成）
  - `pulumi/auth-actions@v1` で GitHub OIDC → 短命 Pulumi access token 交換
  - `pulumi/actions@v6` で `command: preview` / `command: up` を実行
- 認証は OIDC trust（Pulumi Cloud の OIDC issuer 設定 + auth policy）。静的 `PULUMI_ACCESS_TOKEN` シークレットは持たない
- Trust policy の `sub` クレームで `repo:<owner>/<repo>:environment:<env>` まで絞る
- workflow に `permissions: id-token: write` を必ず付ける
- PR 作成時に自動 preview → PR にコメント投稿（`comment-on-pr: true`）
- main マージ時に `up`、`environment: <name>` ジョブゲートで手動承認を挟んでから apply

## Lint / Format: oxlint + oxfmt + tsc

- `oxlint --type-check --type-aware` で静的解析（`.oxlintrc.json` にルール）
- `oxfmt` でフォーマット
- `tsc --noEmit` は `tsconfig.json`（`noUncheckedIndexedAccess`, `strict`, `allowImportingTsExtensions`）で型チェックのみ

## クラウド: Cloudflare 優先

- 基本は Cloudflare に閉じる（Workers, Pages, D1, R2, KV, Queues 等）
- Cloudflare で満たせない、または有料になる場合に他クラウドを検討する
