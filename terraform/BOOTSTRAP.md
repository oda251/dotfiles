# Terraform Bootstrap

初回セットアップ手順。各ステップは順番に実行すること。

## 前提

- Bitwarden アカウント作成済み
- Grafana Cloud アカウント作成済み
- `bw login` 済み（chezmoi が `bw` コマンドを利用）

## 手順

### 1. 環境変数ファイルの設定

`terraform/.env.bw` にBitwarden 認証情報を記入:

```
TF_VAR_bw_email=<your-bitwarden-email>
TF_VAR_bw_master_password=<your-master-password>
TF_CLOUD_ORGANIZATION=<your-tf-cloud-org>
```

### 2. common スタック (Bitwarden アイテム作成)

```sh
cd terraform/common
source ../.env.bw && terragrunt apply
```

apply 後、Bitwarden UI で各アイテムに値を設定:

| アイテム | フィールド | 値 |
|---|---|---|
| `github-pat` | password | GitHub PAT |
| `terraform-cloud` | password | TF Cloud API token |
| `terraform-cloud` | organization (カスタムフィールド) | TF Cloud org 名 |
| `grafana-cloud` | api-key (カスタムフィールド) | Grafana Cloud org-level API key |

### 3. 残りのスタックを一括 apply

```sh
cd terraform
source .env.bw && terragrunt run-all apply
```

### 4. chezmoi apply

```sh
chezmoi apply
```

settings.json に OTel 環境変数が注入される。

### 全スタック一括 (2 回目以降)

```sh
make tf-apply
```

または:

```sh
cd terraform
source .env.bw && terragrunt run-all apply
```
