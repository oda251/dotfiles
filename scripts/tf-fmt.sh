#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

terraform fmt -recursive "${REPO_ROOT}/terraform/"
