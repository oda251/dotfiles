#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tf-common.sh"

cd "$TF_DIR"

terragrunt run --all plan 2>&1 | tee /tmp/tg-plan.log

if grep -q 'No changes' /tmp/tg-plan.log && ! grep -qE 'will be destroyed|must be replaced|will be created|will be updated' /tmp/tg-plan.log; then
  echo ""
  echo "No changes across all stacks."
else
  urls=$(grep -oP 'https://app\.terraform\.io/app/\S+' /tmp/tg-plan.log || true)
  if [[ -n "$urls" ]]; then
    echo ""
    echo "=== Review & confirm in TF Cloud ==="
    echo "$urls"
  fi
fi
rm -f /tmp/tg-plan.log
