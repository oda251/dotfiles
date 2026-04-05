#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tf-common.sh"

cd "$TF_DIR"

terragrunt run --all apply --no-auto-approve 2>&1 | grep -v 'Cannot confirm apply' | tee /tmp/tg-apply.log || true

# Collect workspaces with no changes
no_change_ws=$(grep -oP '\[(\w+)\] terraform: No changes' /tmp/tg-apply.log | grep -oP '\[\K\w+' || true)

# Show URLs only for workspaces that have changes
pending_urls=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  ws=$(echo "$line" | grep -oP 'app/[^/]+/\K[^/]+')
  if ! echo "$no_change_ws" | grep -qx "$ws"; then
    pending_urls+="$line"$'\n'
  fi
done < <(grep -oP 'https://app\.terraform\.io/app/\S+' /tmp/tg-apply.log || true)

if [[ -n "$pending_urls" ]]; then
  echo ""
  echo "=== Review & confirm in TF Cloud ==="
  echo -n "$pending_urls"
  echo ""
  echo "After confirming, run 'make tf-apply' again for remaining stacks."
fi
rm -f /tmp/tg-apply.log
