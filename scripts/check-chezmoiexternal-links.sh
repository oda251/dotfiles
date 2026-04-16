#!/usr/bin/env bash
# check-chezmoiexternal-links.sh
#
# Validate URLs in .chezmoiexternal.toml files.
# Exits 0 if all URLs are reachable, 1 if any are broken.
#
# Usage:
#   ./scripts/check-chezmoiexternal-links.sh [path/to/.chezmoiexternal.toml ...]
#
# If no arguments are given, searches for .chezmoiexternal.toml in the
# chezmoi source directory (CHEZMOI_SOURCE or current directory).

set -euo pipefail

# --- Configuration -----------------------------------------------------------
TIMEOUT="${LINK_CHECK_TIMEOUT:-10}"          # per-request timeout (seconds)
MAX_RETRIES="${LINK_CHECK_RETRIES:-2}"       # retry count on transient failure
RETRY_DELAY="${LINK_CHECK_RETRY_DELAY:-3}"   # seconds between retries
CONCURRENCY="${LINK_CHECK_CONCURRENCY:-5}"   # max parallel checks

# --- Helpers -----------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

log_ok()   { printf "${GREEN}  OK${NC}  %s\n" "$1"; }
log_fail() { printf "${RED}FAIL${NC}  %s (HTTP %s)\n" "$1" "$2"; }
log_warn() { printf "${YELLOW}WARN${NC}  %s\n" "$1"; }
log_info() { printf "INFO  %s\n" "$1"; }

# --- Discover TOML files -----------------------------------------------------
discover_files() {
  local search_dir="${CHEZMOI_SOURCE:-$(chezmoi source-path 2>/dev/null || echo .)}"

  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$@"
    return
  fi

  # Find all .chezmoiexternal.toml (and .toml.tmpl variants)
  find "$search_dir" \( -name '.chezmoiexternal.toml' -o -name '.chezmoiexternal.toml.tmpl' \) -type f 2>/dev/null
}

# --- Extract URLs from TOML --------------------------------------------------
# Extracts the value of `url = "..."` lines from .chezmoiexternal.toml.
# Also handles chezmoi template expressions conservatively: lines with
# unresolved {{ }} are warned and skipped.
extract_urls() {
  local file="$1"
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # Match: url = "..." or url = '...'
    if [[ "$line" =~ ^[[:space:]]*url[[:space:]]*=[[:space:]]*[\"\'](.+)[\"\'][[:space:]]*$ ]]; then
      local url="${BASH_REMATCH[1]}"

      # Skip lines with unresolved chezmoi templates
      if [[ "$url" == *'{{'* ]]; then
        log_warn "Skipping templated URL at ${file}:${line_num}: ${url}" >&2
        continue
      fi

      printf '%s\t%s\t%s\n' "$url" "$file" "$line_num"
    fi
  done < "$file"
}

# --- Check a single URL ------------------------------------------------------
check_url() {
  local url="$1"
  local attempt=0
  local http_code=""

  while (( attempt <= MAX_RETRIES )); do
    # Use HEAD first; fall back to GET if HEAD is 405
    http_code=$(curl -o /dev/null -s -w '%{http_code}' \
      --head \
      --location \
      --max-time "$TIMEOUT" \
      --retry 0 \
      "$url" 2>/dev/null) || http_code="000"

    if [[ "$http_code" == "405" ]]; then
      http_code=$(curl -o /dev/null -s -w '%{http_code}' \
        --location \
        --max-time "$TIMEOUT" \
        --retry 0 \
        "$url" 2>/dev/null) || http_code="000"
    fi

    # 2xx or 3xx → success
    if [[ "$http_code" =~ ^[23] ]]; then
      echo "$http_code"
      return 0
    fi

    # 4xx → no point retrying
    if [[ "$http_code" =~ ^4 ]]; then
      echo "$http_code"
      return 1
    fi

    # Transient (5xx, 000/timeout) → retry
    attempt=$((attempt + 1))
    if (( attempt <= MAX_RETRIES )); then
      sleep "$RETRY_DELAY"
    fi
  done

  echo "$http_code"
  return 1
}

# --- Main --------------------------------------------------------------------
main() {
  local -a toml_files=()

  while IFS= read -r f; do
    [[ -n "$f" ]] && toml_files+=("$f")
  done < <(discover_files "$@")

  if [[ ${#toml_files[@]} -eq 0 ]]; then
    log_warn "No .chezmoiexternal.toml files found."
    exit 0
  fi

  log_info "Found ${#toml_files[@]} file(s) to check."

  # Collect all URLs: url\tfile\tline
  local -a url_entries=()
  for toml in "${toml_files[@]}"; do
    while IFS= read -r entry; do
      [[ -n "$entry" ]] && url_entries+=("$entry")
    done < <(extract_urls "$toml")
  done

  if [[ ${#url_entries[@]} -eq 0 ]]; then
    log_warn "No URLs found in the TOML files."
    exit 0
  fi

  log_info "Checking ${#url_entries[@]} URL(s)..."
  echo ""

  local broken=0
  local checked=0
  local pids=()
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  for entry in "${url_entries[@]}"; do
    local url file line_num
    url=$(printf '%s' "$entry" | cut -f1)
    file=$(printf '%s' "$entry" | cut -f2)
    line_num=$(printf '%s' "$entry" | cut -f3)

    # Throttle concurrency
    while (( ${#pids[@]} >= CONCURRENCY )); do
      local new_pids=()
      for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
          new_pids+=("$pid")
        fi
      done
      pids=("${new_pids[@]}")
      if (( ${#pids[@]} >= CONCURRENCY )); then
        sleep 0.2
      fi
    done

    # Run check in background
    (
      result_file="${tmpdir}/${checked}"
      if http_code=$(check_url "$url"); then
        log_ok "$url"
        echo "ok" > "$result_file"
      else
        log_fail "$url" "$http_code"
        echo "  -> ${file}:${line_num}" >&2
        echo "fail" > "$result_file"
      fi
    ) &
    pids+=($!)
    checked=$((checked + 1))
  done

  # Wait for all background jobs
  wait

  # Count failures
  for f in "$tmpdir"/*; do
    [[ -f "$f" ]] || continue
    if [[ "$(cat "$f")" == "fail" ]]; then
      broken=$((broken + 1))
    fi
  done

  echo ""
  log_info "Results: $((checked - broken))/${checked} OK, ${broken} broken."

  if (( broken > 0 )); then
    exit 1
  fi
  exit 0
}

main "$@"
