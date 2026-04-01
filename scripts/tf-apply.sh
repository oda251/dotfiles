#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tf-common.sh"

cd "$TF_DIR"
terragrunt run --all apply
