# Terraform Bootstrap

初回セットアップ手順。各ステップは順番に実行すること。

## 前提

- 1Password アカウント作成済み
- Grafana Cloud アカウント作成済み
- `op signin` 済み

## 手順

### 1. 1Password サービスアカウント作成

1Password の Web UI でサービスアカウントを作成し、`dotfiles` vault へのアクセスを許可。
credential と vault-id を控える。

### 2. common スタック (1Password アイテム作成)

```sh
cd terraform/common
op run --env-file=../.env.op -- terragrunt apply
```

apply 後、1Password UI で各アイテムに値を設定:

| アイテム | フィールド | 値 |
|---|---|---|
| `github-pat` | password | GitHub PAT |
| `terraform-cloud` | password | TF Cloud API token |
| `terraform-cloud` | Terraform Cloud > organization | TF Cloud org 名 |
| `grafana-cloud` | API > api-key | Grafana Cloud org-level API key |
| `1password-sa` | Service Account > credential | SA トークン |
| `1password-sa` | Service Account > vault-id | vault ID |

### 3. github スタック

```sh
cd terraform/github
op run --env-file=../.env.op -- terragrunt apply
```

### 4. grafana スタック

```sh
cd terraform/grafana
op run --env-file=../.env.op -- terragrunt apply
```

### 5. chezmoi apply

```sh
chezmoi apply
```

settings.json に OTel 環境変数が注入される。

### 全スタック一括

2 回目以降は:

```sh
cd terraform
op run --env-file=.env.op -- terragrunt run-all apply
```
