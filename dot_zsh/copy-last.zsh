# cpl: 直前のコマンドと出力をクリップボードへコピーする
# herdr ペイン内でのみ動作する。抽出ロジックは __cpl_extract として純関数に分離しユニットテストする

: ${CPL_PROMPT_MARK:=❯}
: ${CPL_SCAN_LINES:=2000}

# herdr ペインのテキスト（starship プロンプト付き）を stdin で受け取り、
# 直前コマンド文字列（$1）に一致するプロンプト行を境界として、
# "$ <コマンド>" 行 + そのコマンドの出力を stdout へ出す。
__cpl_extract() {
  emulate -L zsh
  local target_cmd="$1"
  local -a lines
  lines=("${(@f)"$(cat)"}")

  local -a prompt_idx
  local i
  for (( i = 1; i <= ${#lines}; i++ )); do
    [[ "${lines[i]}" == "${CPL_PROMPT_MARK} "* ]] && prompt_idx+=("$i")
  done

  local match_idx=0
  for i in "${prompt_idx[@]}"; do
    [[ "${lines[i]#${CPL_PROMPT_MARK} }" == "$target_cmd" ]] && match_idx=$i
  done
  (( match_idx == 0 )) && return 1

  local next_idx=$(( ${#lines} + 1 ))
  for i in "${prompt_idx[@]}"; do
    if (( i > match_idx )); then
      next_idx=$i
      break
    fi
  done

  # 次のプロンプトブロック（空行 + パワーライン行）を出力範囲から除く
  local out_end=$(( next_idx - 1 ))
  (( out_end >= match_idx + 2 )) && (( out_end -= 2 ))

  local -a body
  for (( i = match_idx + 1; i <= out_end; i++ )); do
    body+=("${lines[i]}")
  done
  while (( ${#body} > 0 )) && [[ -z "${body[-1]}" ]]; do
    body[-1]=()
  done

  print -r -- "\$ ${target_cmd}"
  (( ${#body} > 0 )) && print -rl -- "${body[@]}"
}
