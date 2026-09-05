# cpl: 直前のコマンドと出力をクリップボードへコピーする
# herdr ペイン内でのみ動作する。抽出ロジックは __cpl_extract として純関数に分離しユニットテストする

: ${CPL_PROMPT_MARK:=❯}
: ${CPL_SCAN_LINES:=2000}
# 自分自身のコマンド名。cpl 実行時は funcstack から実際の関数名で上書きする
typeset -g __cpl_self_name="cpl"

# herdr ペインのテキスト（starship プロンプト付き）を stdin で受け取り、
# 直前コマンド文字列（$1）に一致するプロンプト行を境界として、
# "$ <コマンド>" 行 + そのコマンドの出力を stdout へ出す。
# 一致するプロンプト行が無い場合や、直前コマンド文字列が自分自身（cpl）の
# 場合は、末尾側の cpl の実行行を読み飛ばし、直近の非 cpl・非空コマンド行を
# 対象にする（cpl 連投時に cpl 自身の実行行を対象にしてしまうのを防ぐ）。
# 出力の終端は、対象行より後で最も近い自分自身（cpl）の実行行とする
# （出力中に偶然 "❯ " で始まる行があっても、cpl の実行行でなければ終端にしない）。
__cpl_extract() {
  emulate -L zsh
  local target_cmd="$1"
  local -a lines
  lines=("${(@f)"$(<&0)"}")

  local -a prompt_idx
  local i
  for (( i = 1; i <= ${#lines}; i++ )); do
    [[ "${lines[i]}" == "${CPL_PROMPT_MARK} "* ]] && prompt_idx+=("$i")
  done

  # 対象行: 直前コマンド文字列に一致する末尾側のプロンプト行
  local match_idx=0
  if [[ "$target_cmd" != "$__cpl_self_name" ]]; then
    for (( i = ${#prompt_idx}; i >= 1; i-- )); do
      if [[ "${lines[${prompt_idx[i]}]#${CPL_PROMPT_MARK} }" == "$target_cmd" ]]; then
        match_idx=${prompt_idx[i]}
        break
      fi
    done
  fi
  # フォールバック: 末尾側の cpl 実行行を読み飛ばし、直近の非 cpl・非空コマンド行を使う
  if (( match_idx == 0 )); then
    local cmd
    for (( i = ${#prompt_idx}; i >= 1; i-- )); do
      cmd="${lines[${prompt_idx[i]}]#${CPL_PROMPT_MARK} }"
      if [[ -n "$cmd" && "$cmd" != "$__cpl_self_name" ]]; then
        match_idx=${prompt_idx[i]}
        break
      fi
    done
  fi
  (( match_idx == 0 )) && return 1
  local matched_cmd="${lines[match_idx]#${CPL_PROMPT_MARK} }"

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

  # 終端の直前にあるプロンプトブロックの装飾行（空行 + パワーライン行）を出力範囲から除く
  local -i prompt_trailer_lines=2
  local out_end=$(( term_idx - 1 ))
  (( out_end >= match_idx + prompt_trailer_lines )) && (( out_end -= prompt_trailer_lines ))

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

# 直前のコマンドと出力をクリップボードへコピーする（herdr ペイン内限定）
cpl() {
  emulate -L zsh
  # 関数名を単一の情報源にする（リネームしても抽出側の判定が追従する）
  local __cpl_self_name="${funcstack[1]}"

  if [[ "${HERDR_ENV:-}" != 1 || -z "${HERDR_PANE_ID:-}" ]]; then
    print -ru2 -- "cpl: herdr のペイン内でのみ使えます"
    return 1
  fi

  # 直前に実行したコマンド文字列（前後の空白をトリム）
  # 実行中の cpl 自身はまだ履歴リストに入らないため -1 が直前のコマンドになる
  local prev_cmd
  prev_cmd="$(fc -ln -1 -1 2>/dev/null)"
  prev_cmd="${prev_cmd#"${prev_cmd%%[^[:space:]]*}"}"
  prev_cmd="${prev_cmd%"${prev_cmd##*[^[:space:]]}"}"

  local pane_text
  if ! pane_text="$(herdr pane read "$HERDR_PANE_ID" --source recent-unwrapped --lines "$CPL_SCAN_LINES" --format text)"; then
    print -ru2 -- "cpl: herdr pane read に失敗しました"
    return 1
  fi

  local result
  if ! result="$(__cpl_extract "$prev_cmd" <<< "$pane_text")"; then
    print -ru2 -- "cpl: 直前のコマンドを特定できませんでした"
    return 1
  fi

  local -a result_lines
  result_lines=("${(@f)result}")
  local summary_cmd="${result_lines[1]#\$ }"
  (( ${#summary_cmd} > 40 )) && summary_cmd="${summary_cmd[1,40]}…"

  # クリップボードへの書き込みは alias.zsh の copy 関数に任せる
  # （どのコマンドを使うかの判定はそちらが単一の情報源）
  if (( $+functions[copy] )); then
    print -r -- "$result" | copy
    print -ru2 -- "cpl: ${#result_lines} 行コピーしました（${summary_cmd}）"
  else
    print -r -- "$result"
    print -ru2 -- "cpl: copy が定義されていないため stdout に出力しました"
  fi
}
