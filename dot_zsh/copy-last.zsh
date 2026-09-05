# cpl: 直前のコマンドと出力をクリップボードへコピーする
# herdr ペイン内でのみ動作する。抽出ロジックは __cpl_extract として純関数に分離しユニットテストする

: ${CPL_PROMPT_MARK:=❯}
: ${CPL_SCAN_LINES:=2000}
typeset -g __cpl_self_name="cpl"

# herdr ペインのテキスト（starship プロンプト付き）を stdin で受け取り、
# 直前コマンド文字列（$1）に一致するプロンプト行を境界として、
# "$ <コマンド>" 行 + そのコマンドの出力を stdout へ出す。
# 一致するプロンプト行が無い場合は、末尾側の自分自身（cpl）の実行行を
# 読み飛ばし、直近の非 cpl・非空コマンド行を対象にする。
# 出力の終端は、対象行より後で最も近い自分自身（cpl）の実行行とする
# （出力中に偶然 "❯ " で始まる行があっても、cpl の実行行でなければ終端にしない）。
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

  local matched_cmd="$target_cmd"
  if (( match_idx == 0 )); then
    for (( i = ${#prompt_idx}; i >= 1; i-- )); do
      local idx=${prompt_idx[i]}
      local cmd="${lines[idx]#${CPL_PROMPT_MARK} }"
      if [[ -n "$cmd" && "$cmd" != "$__cpl_self_name" ]]; then
        match_idx=$idx
        matched_cmd="$cmd"
        break
      fi
    done
  fi
  (( match_idx == 0 )) && return 1

  # 終端: 対象行より後で最も近い自分自身（cpl）の実行行
  local term_idx=0
  for i in "${prompt_idx[@]}"; do
    if (( i > match_idx )); then
      [[ "${lines[i]#${CPL_PROMPT_MARK} }" == "$__cpl_self_name" ]] && { term_idx=$i; break }
    fi
  done
  if (( term_idx == 0 )); then
    local last_prompt=0
    (( ${#prompt_idx} > 0 )) && last_prompt=${prompt_idx[-1]}
    if (( last_prompt > match_idx )); then
      term_idx=$last_prompt
    else
      term_idx=$(( ${#lines} + 1 ))
    fi
  fi

  # 次のプロンプトブロック（空行 + パワーライン行）を出力範囲から除く
  local out_end=$(( term_idx - 1 ))
  (( out_end >= match_idx + 2 )) && (( out_end -= 2 ))

  local -a body
  for (( i = match_idx + 1; i <= out_end; i++ )); do
    body+=("${lines[i]}")
  done
  while (( ${#body} > 0 )) && [[ -z "${body[-1]}" ]]; do
    body[-1]=()
  done

  print -r -- "\$ ${matched_cmd}"
  (( ${#body} > 0 )) && print -rl -- "${body[@]}"
}
