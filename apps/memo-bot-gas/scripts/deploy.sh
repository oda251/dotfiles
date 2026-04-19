#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

: "${MEMO_BOT_GAS_SCRIPT_ID:?must be set (esc run -- bun run deploy)}"
: "${GCP_PROJECT_ID:?must be set}"

cat > .clasp.json <<EOF
{
  "scriptId": "${MEMO_BOT_GAS_SCRIPT_ID}",
  "rootDir": "./src",
  "projectId": "${GCP_PROJECT_ID}"
}
EOF

clasp push -f
