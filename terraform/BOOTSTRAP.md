# Terraform Bootstrap

初回セットアップ手順。各ステップは順番に実行すること。

## 前提

- Infisical アカウント作成済み（https://app.infisical.com）
- Grafana Cloud アカウント作成済み
- Infisical プロジェクト作成済み

## 手順

### 1. Infisical プロジェクトと Machine Identity の準備

1. Infisical Web UI でプロジェクトを作成
2. Machine Identity を作成（Universal Auth）し、プロジェクトにアクセス権を付与
3. 以下の情報を控える:
   - Organization ID
   - Project ID
   - Machine Identity の Client ID / Client Secret

### 2. 環境変数ファイルの設定

`terraform/.env.infisical` に認証情報を記入:

```
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=<client-id>
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=<client-secret>
export INFISICAL_ORG_ID=<org-id>
export TF_VAR_infisical_project_id=<project-id>
```

### 3. common スタック (Infisical シークレット枠の作成)

```sh
make tf-init
```

または手動:

```sh
cd terraform/common
source ../.env.infisical && terragrunt apply
```

apply 後、Infisical Web UI で `/terraform` フォルダ内の各シークレットに値を設定:

| シークレット | 値 |
|---|---|
| `GITHUB_PAT` | GitHub Personal Access Token |
| `TF_API_TOKEN` | Terraform Cloud API token |
| `TF_CLOUD_ORG` | Terraform Cloud organization 名 |
| `GRAFANA_API_KEY` | Grafana Cloud org-level API key |

### 4. 残りのスタックを一括 apply

```sh
make tf-apply
```

github スタックが GH Actions secrets に Infisical 認証情報を配布し、
grafana スタックが OTLP credentials を `/generated` フォルダに書き込む。

### 5. chezmoi apply

```sh
infisical login
chezmoi apply
```

settings.json に OTel 環境変数が注入される。

## 全スタック一括 (2 回目以降)

```sh
make tf-apply
```

## CI/CD

GitHub Actions は Infisical Universal Auth で認証。
`INFISICAL_CLIENT_ID` / `INFISICAL_CLIENT_SECRET` が GH Actions secrets に、
`INFISICAL_PROJECT_ID` が GH Actions variables に自動配布される。
