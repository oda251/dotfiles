#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tf-common.sh"

if [[ ! -f "$ENV_FILE" ]]; then
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
  read -p "Terraform Cloud Organization: " tf_cloud_org

  printf 'export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=%s\nexport INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=%s\nexport INFISICAL_ORG_ID=%s\nexport TF_VAR_infisical_project_id=%s\nexport TF_CLOUD_ORGANIZATION=%s\n' \
    "$client_id" "$client_secret" "$org_id" "$project_id" "$tf_cloud_org" > "$ENV_FILE"
  echo ""
  echo "${ENV_FILE} を書き込みました。"
  source "$ENV_FILE"
fi

TFE_CREDS="$HOME/.terraform.d/credentials.tfrc.json"
if ! jq -e '.credentials["app.terraform.io"]' "$TFE_CREDS" >/dev/null 2>&1; then
  echo ""
  echo "=== Terraform Cloud ログインが必要です ==="
  terraform login
fi

# workspace を作成（init で自動作成）し、execution mode を local に設定
echo ""
echo "=== Workspace 初期化 & execution mode → local ==="
export TFE_TOKEN=$(jq -r '.credentials["app.terraform.io"].token' "$TFE_CREDS" 2>/dev/null || true)

set_local_mode() {
  local ws="$1"
  if [[ -n "$TFE_TOKEN" ]]; then
    curl -sf \
      -H "Authorization: Bearer ${TFE_TOKEN}" \
      -H "Content-Type: application/vnd.api+json" \
      -X PATCH \
      "https://app.terraform.io/api/v2/organizations/${TF_CLOUD_ORGANIZATION}/workspaces/${ws}" \
      -d '{"data":{"type":"workspaces","attributes":{"execution-mode":"local"}}}' > /dev/null && echo "  ${ws}: local" || echo "  ${ws}: skipped"
  fi
}

stacks=()
for d in "${TF_DIR}"/*/terragrunt.hcl; do
  stacks+=("$(basename "$(dirname "$d")")")
done

for stack in "${stacks[@]}"; do
  (cd "${TF_DIR}/${stack}" && terragrunt init --terragrunt-non-interactive 2>/dev/null && set_local_mode "$stack") &
done
wait

echo ""
echo "=== common スタック apply (シークレット枠を作成) ==="
(cd "${TF_DIR}/common" && terragrunt apply)

echo ""
echo "=== Infisical Web UI で /terraform フォルダ内のシークレットに値を設定してください ==="
echo "  - GITHUB_PAT                 : GitHub Personal Access Token"
echo "  - TF_API_TOKEN               : Terraform Cloud API token"
echo "  - TF_CLOUD_ORG               : Terraform Cloud organization 名"
echo "  - NEW_RELIC_API_KEY           : New Relic User API key"
echo "  - NEW_RELIC_ACCOUNT_ID        : New Relic account ID"
echo "  - INFISICAL_CI_CLIENT_ID      : Infisical CI 用 client ID"
echo "  - INFISICAL_CI_CLIENT_SECRET  : Infisical CI 用 client secret"
echo ""
read -p "設定完了したら Enter を押してください..."

echo ""
echo "=== 全スタック apply ==="
(cd "${TF_DIR}" && terragrunt run --all apply)

echo ""
echo "=== Bootstrap 完了 ==="
echo "以降は scripts/tf-apply.sh で全スタックを更新できます。"
