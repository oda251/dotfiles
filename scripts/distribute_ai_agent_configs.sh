#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
routes_file="$repo_root/ai-agent-configs/routes.txt"

if [[ ! -f "$routes_file" ]]; then
  echo "routes file not found: $routes_file" >&2
  exit 0
fi

sync_count=0

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf "%s" "$value"
}

sync_copy() {
  local src_rel="$1"
  local dst_rel="$2"
  local src="$repo_root/$src_rel"
  local dst="$repo_root/$dst_rel"

  if [[ ! -f "$src" ]]; then
    echo "source file not found: $src_rel" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ ! -f "$dst" ]] || ! cmp -s "$src" "$dst"; then
    cp "$src" "$dst"
    echo "synced: $src_rel -> $dst_rel"
    sync_count=$((sync_count + 1))
  fi
}

sync_concat() {
  local dst_rel="$1"
  shift
  local dst="$repo_root/$dst_rel"
  local tmp
  tmp="$(mktemp)"

  : > "$tmp"
  local sources=("$@")
  local total="${#sources[@]}"
  local i=0

  for src_rel in "${sources[@]}"; do
    i=$((i + 1))
    local src="$repo_root/$src_rel"
    if [[ ! -f "$src" ]]; then
      rm -f "$tmp"
      echo "source file not found: $src_rel" >&2
      exit 1
    fi
    cat "$src" >> "$tmp"
    if [[ "$i" -lt "$total" ]]; then
      echo >> "$tmp"
    fi
  done

  mkdir -p "$(dirname "$dst")"
  if [[ ! -f "$dst" ]] || ! cmp -s "$tmp" "$dst"; then
    cp "$tmp" "$dst"
    echo "synced (concat): ${sources[*]} -> $dst_rel"
    sync_count=$((sync_count + 1))
  fi
  rm -f "$tmp"
}

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  line="$(trim "$raw_line")"
  if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
    continue
  fi

  IFS='|' read -r -a parts <<< "$line"
  part_count="${#parts[@]}"

  if [[ "$part_count" -eq 2 ]]; then
    src_rel="$(trim "${parts[0]}")"
    dst_rel="$(trim "${parts[1]}")"
    if [[ -z "$src_rel" || -z "$dst_rel" ]]; then
      echo "invalid legacy route: $line" >&2
      exit 1
    fi
    sync_copy "$src_rel" "$dst_rel"
    continue
  fi

  mode="$(trim "${parts[0]}")"
  if [[ "$mode" == "sync" ]]; then
    if [[ "$part_count" -ne 3 ]]; then
      echo "invalid sync route: $line" >&2
      exit 1
    fi
    src_dir="$(trim "${parts[1]}")"
    dst_dir="$(trim "${parts[2]}")"
    if [[ -z "$src_dir" || -z "$dst_dir" ]]; then
      echo "invalid sync route: $line" >&2
      exit 1
    fi
    src_abs="$repo_root/$src_dir"
    if [[ ! -d "$src_abs" ]]; then
      echo "source directory not found: $src_dir" >&2
      exit 1
    fi
    while IFS= read -r -d '' file; do
      rel="${file#"$src_abs/"}"
      sync_copy "$src_dir/$rel" "$dst_dir/$rel"
    done < <(find "$src_abs" -type f -print0)
    # Remove files in destination that no longer exist in source
    dst_abs="$repo_root/$dst_dir"
    if [[ -d "$dst_abs" ]]; then
      while IFS= read -r -d '' file; do
        rel="${file#"$dst_abs/"}"
        if [[ ! -f "$src_abs/$rel" ]]; then
          rm "$file"
          echo "removed: $dst_dir/$rel (no longer in source)"
          sync_count=$((sync_count + 1))
          # Clean up empty parent directories
          parent="$(dirname "$file")"
          while [[ "$parent" != "$dst_abs" ]] && [[ -d "$parent" ]] && [[ -z "$(ls -A "$parent")" ]]; do
            rmdir "$parent"
            echo "removed empty dir: ${parent#"$repo_root/"}"
            parent="$(dirname "$parent")"
          done
        fi
      done < <(find "$dst_abs" -type f -print0)
    fi
  elif [[ "$mode" == "copy" ]]; then
    if [[ "$part_count" -ne 3 ]]; then
      echo "invalid copy route: $line" >&2
      exit 1
    fi
    src_rel="$(trim "${parts[1]}")"
    dst_rel="$(trim "${parts[2]}")"
    if [[ -z "$src_rel" || -z "$dst_rel" ]]; then
      echo "invalid copy route: $line" >&2
      exit 1
    fi
    sync_copy "$src_rel" "$dst_rel"
  elif [[ "$mode" == "concat" ]]; then
    if [[ "$part_count" -lt 4 ]]; then
      echo "invalid concat route: $line" >&2
      exit 1
    fi
    dst_rel="$(trim "${parts[1]}")"
    if [[ -z "$dst_rel" ]]; then
      echo "invalid concat route (missing destination): $line" >&2
      exit 1
    fi

    sources=()
    for ((idx = 2; idx < part_count; idx++)); do
      src_rel="$(trim "${parts[$idx]}")"
      if [[ -z "$src_rel" ]]; then
        echo "invalid concat route (empty source): $line" >&2
        exit 1
      fi
      sources+=("$src_rel")
    done
    sync_concat "$dst_rel" "${sources[@]}"
  else
    echo "unsupported route mode: $mode" >&2
    exit 1
  fi
done < "$routes_file"

if [[ "$sync_count" -eq 0 ]]; then
  echo "AI agent config routing: no changes"
else
  # Stage all distributed changes (new, modified, and deleted files)
  git add dot_claude/ dot_codex/ dot_cursor/ 2>/dev/null || true
fi
