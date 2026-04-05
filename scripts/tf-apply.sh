#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tf-common.sh"

cd "$TF_DIR"

# --no-auto-approve prevents terragrunt from adding -auto-approve
# Remote execution will "error" with "handle run confirmation in the UI" - this is expected
terragrunt run --all --non-interactive apply --no-auto-approve 2>&1 | grep -v 'Cannot confirm apply' | tee /tmp/tg-apply.log || true

# Collect workspaces with no changes
no_change_ws=$(grep -oP '\[(\w+)\] terraform: No changes' /tmp/tg-apply.log | grep -oP '\[\K\w+' || true)

# Show URLs only for workspaces that have changes
pending_urls=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # Extract workspace name from URL (e.g. https://app.terraform.io/app/oda251/common/runs/...)
  ws=$(echo "$line" | grep -oP 'app/[^/]+/\K[^/]+')
  if ! echo "$no_change_ws" | grep -qx "$ws"; then
    pending_urls+="$line"$'\n'
  fi
done < <(grep -oP 'https://app\.terraform\.io/app/\S+' /tmp/tg-apply.log || true)

if [[ -n "$pending_urls" ]]; then
  echo ""
  echo "=== Review & confirm in TF Cloud ==="
  echo -n "$pending_urls"
fi
rm -f /tmp/tg-apply.log
