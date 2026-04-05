#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tf-common.sh"

cd "$TF_DIR"

terragrunt run --all --non-interactive apply --no-auto-approve 2>&1 | tee /tmp/tg-apply.log || true

# Parse log: collect URLs and no-change workspaces in single pass
declare -A no_change
declare -A urls
while IFS= read -r line; do
  if [[ "$line" =~ \[([a-z_-]+)\].*No\ changes ]]; then
    no_change[${BASH_REMATCH[1]}]=1
  elif [[ "$line" =~ https://app\.terraform\.io/app/[^/]+/([^/]+)/runs/[^[:space:]]+ ]]; then
    urls[${BASH_REMATCH[1]}]=${BASH_REMATCH[0]}
  fi
done < /tmp/tg-apply.log

# Filter URLs for workspaces with changes
pending_urls=""
for ws in "${!urls[@]}"; do
  [[ -z "${no_change[$ws]:-}" ]] && pending_urls+="${urls[$ws]}"$'\n'
done

if [[ -n "$pending_urls" ]]; then
  echo ""
  echo "=== Review & confirm in TF Cloud ==="
  echo -n "$pending_urls"
  echo ""
  echo "After confirming, run 'make tf-apply' again for remaining stacks."
fi
rm -f /tmp/tg-apply.log
