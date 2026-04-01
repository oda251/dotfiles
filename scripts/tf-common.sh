#!/bin/bash
# Shared setup for tf-*.sh scripts

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"
ENV_FILE="${TF_DIR}/.env.infisical"

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
