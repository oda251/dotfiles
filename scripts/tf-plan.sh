#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"

cd "$TF_DIR"
source ".env.infisical"
terragrunt run-all plan
