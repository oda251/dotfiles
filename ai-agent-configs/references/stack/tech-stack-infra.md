# 技術スタック: インフラ

## IaC: Pulumi (TypeScript, Bun runtime) + Pulumi ESC

- インフラは全て Pulumi で管理する
- ランタイムは Bun（`runtime: bun`）、言語は TypeScript
- state は Pulumi Cloud（`oda251/dotfiles/prod` スタック）で管理
- 機密値・設定値は Pulumi ESC（`oda251/dotfiles/prod` env）に集約し、`Pulumi.prod.yaml` の `environment: [dotfiles/prod]` で読み込む
- 旧構成の Terraform + Terragrunt + Infisical + SOPS は全廃

### ディレクトリ構成

```
pulumi/
├── Pulumi.yaml            # project 定義（name: dotfiles, runtime: bun）
├── Pulumi.prod.yaml       # stack 設定、ESC env 参照
├── index.ts               # エントリポイント（各サブモジュール登録）
├── src/
│   ├── lib/config.ts      # valibot で設定/スキーマ検証、型付き Config エクスポート
│   ├── repos/             # GitHub リポジトリ・ruleset・environment・workflow file
│   ├── newrelic/          # NewRelic dashboard、APIアクセスキー
│   └── workflows/         # 配布する GHA workflow テンプレート（必要時）
└── esc/dotfiles-prod.yaml # ESC env のソース (secrets は --secret で別投入)
```

## GitHub 管理: @pulumi/github プロバイダ

- リポジトリ設定、RepositoryRuleset（ブランチ保護）、RepositoryFile（配布 workflow）、RepositoryEnvironment、Actions Secrets/Variables を Pulumi で管理
- main 直プッシュ禁止、`gate` status check を PR マージの必須条件にする
- リポジトリ定義は ESC の `repos.public` / `repos.private` に置き、`src/lib/config.ts` で valibot 検証した上で `src/repos/repository.ts` が展開

### リポジトリスキーマのフラグ

`RepoSpec` にブール値フラグを立てて、リポジトリごとに追加リソースを配置する:

- `hasESC`: Production environment（reviewer gate）と `PULUMI_ACCESS_TOKEN` Environment Secret を配置。CD で Pulumi を走らせるリポに付与する（`dotfiles` リポ自身を含む）
- `hasTerraform`: `.github/workflows/terraform.yml` をリポに配布（Terraform を併用する既存リポ向け）

状態を boolean で持つことで、リポ追加時は YAML に1行足すだけで付随リソースが揃う。

## Pulumi CI/CD

- `.github/workflows/pulumi.yml` 単一ワークフローで preview（PR）と up（main push）を担う
- 主要ステップ:
  - `actions/checkout@v4`
  - `oven-sh/setup-bun@v2` で Bun ランタイム導入
  - `bun install --frozen-lockfile` で依存インストール
  - `actions/cache@v4` で `~/.pulumi/plugins` をキャッシュ（`pulumi/bun.lock` ハッシュでキー生成）
  - `pulumi/actions@v6` で `command: preview` / `command: up` を実行
- 認証は `PULUMI_ACCESS_TOKEN` シークレット（Pulumi Cloud の個人 access token）のみ。Infisical/SOPS 経由のシークレット引き出しは不要（ESC が全てを解決）
- PR 作成時に自動 preview → PR にコメント投稿（`comment-on-pr: true`）
- main マージ時に `up`、`environment: production` ジョブゲートで手動承認（reviewers=oda251）を挟んでから apply

## Lint / Format: oxlint + oxfmt + tsc

- `oxlint --type-check --type-aware` で静的解析（`.oxlintrc.json` にルール）
- `oxfmt` でフォーマット
- `tsc --noEmit` は `tsconfig.json`（`noUncheckedIndexedAccess`, `strict`, `allowImportingTsExtensions`）で型チェックのみ
- pre-commit（Lefthook）には AI agent configs 同期のみを登録（lint/typecheck は CD とエディタに寄せる）

## クラウド: Cloudflare 優先

- 基本は Cloudflare に閉じる（Workers, Pages, D1, R2, KV, Queues 等）
- Cloudflare で満たせない、または有料になる場合に他クラウドを検討する
