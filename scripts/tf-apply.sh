#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"

cd "$TF_DIR"
eval "$(mise hook-env 2>/dev/null)" || true
source ".env.infisical"
terragrunt run-all apply
