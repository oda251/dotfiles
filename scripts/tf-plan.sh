#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"
ENV_FILE="${TF_DIR}/.env.infisical"

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

cd "$TF_DIR"
terragrunt run-all plan
