#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tf-common.sh"

TFE_CREDS="$HOME/.terraform.d/credentials.tfrc.json"
if ! jq -e '.credentials["app.terraform.io"]' "$TFE_CREDS" >/dev/null 2>&1; then
  echo "=== Terraform Cloud ログインが必要です ==="
  terraform login
fi

echo ""
echo "=== Workspace 初期化 ==="

stacks=()
for d in "${TF_DIR}"/*/terragrunt.hcl; do
  stacks+=("$(basename "$(dirname "$d")")")
done

for stack in "${stacks[@]}"; do
  echo "  ${stack}: init..."
  (cd "${TF_DIR}/${stack}" && terragrunt init --terragrunt-non-interactive 2>/dev/null) || true
done

echo ""
echo "=== 全スタック apply ==="
(cd "${TF_DIR}" && terragrunt run --all apply)

echo ""
echo "=== Bootstrap 完了 ==="
echo "以降は make tf-apply で全スタックを更新できます。"
