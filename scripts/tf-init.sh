#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"
ENV_FILE="${TF_DIR}/.env.infisical"

echo "=== Infisical Bootstrap ==="

echo "1) https://app.infisical.com でアカウント・プロジェクトを作成"
echo "2) Settings > Machine Identities で Universal Auth の Identity を作成"
echo "3) 作成した Identity にプロジェクトへのアクセス権を付与"
echo ""

read -p "Organization ID: " org_id
read -p "Project ID: " project_id
read -p "Client ID: " client_id
read -sp "Client Secret: " client_secret
echo ""

printf 'export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=%s\nexport INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=%s\nexport INFISICAL_ORG_ID=%s\nexport TF_VAR_infisical_project_id=%s\n' \
  "$client_id" "$client_secret" "$org_id" "$project_id" > "$ENV_FILE"
echo ""
echo "${ENV_FILE} を書き込みました。"

echo ""
echo "=== common スタック apply (シークレット枠を作成) ==="
(cd "${TF_DIR}/common" && source "../.env.infisical" && terragrunt apply)

echo ""
echo "=== Infisical Web UI で /terraform フォルダ内のシークレットに値を設定してください ==="
echo "  - GITHUB_PAT           : GitHub Personal Access Token"
echo "  - TF_API_TOKEN         : Terraform Cloud API token"
echo "  - TF_CLOUD_ORG         : Terraform Cloud organization 名"
echo "  - NEW_RELIC_API_KEY    : New Relic User API key"
echo "  - NEW_RELIC_ACCOUNT_ID : New Relic account ID"
echo ""
read -p "設定完了したら Enter を押してください..."

echo ""
echo "=== 全スタック apply ==="
(cd "${TF_DIR}" && source ".env.infisical" && terragrunt run-all apply)

echo ""
echo "=== Bootstrap 完了 ==="
echo "以降は scripts/tf-apply.sh で全スタックを更新できます。"
