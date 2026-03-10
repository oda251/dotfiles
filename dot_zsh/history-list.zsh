# 常時履歴リスト表示 + 矢印キー選択プラグイン
# 補完システムに触れないため Tab/fzf-tab と衝突しない

typeset -g __hl_prev_buffer=""
typeset -g __hl_max_lines=8
typeset -ga __hl_matches=()
typeset -g __hl_index=0
typeset -g __hl_query=""
typeset -g __hl_navigating=0
# ナビゲーション中に矢印キー操作で設定した BUFFER を記憶
typeset -g __hl_nav_buffer=""

__hl_search() {
  local query="$1"
  __hl_matches=()
  local -A seen=()
  local line

  if [[ -z "$query" ]]; then
    for line in "${(@)history}"; do
      [[ -n "${seen[$line]+x}" ]] && continue
      seen[$line]=1
      __hl_matches+=( "$line" )
      (( ${#__hl_matches} >= __hl_max_lines )) && break
    done
  else
    for line in "${(@)history}"; do
      [[ "$line" != "${query}"* ]] && continue
      [[ "$line" == "$query" ]] && continue
      [[ -n "${seen[$line]+x}" ]] && continue
      seen[$line]=1
      __hl_matches+=( "$line" )
      (( ${#__hl_matches} >= __hl_max_lines )) && break
    done
  fi
}

__hl_render() {
  if (( ${#__hl_matches} == 0 )); then
    zle -M ""
    return
  fi

  local display="" idx=${#__hl_matches}
  while (( idx >= 1 )); do
    local line="${__hl_matches[$idx]}"
    if (( __hl_navigating && idx == __hl_index )); then
      display+="▸ ${line}"$'\n'
    else
      display+="  ${line}"$'\n'
    fi
    (( idx-- ))
  done
  zle -M "${display%$'\n'}"
}

__hl_show() {
  # ナビゲーション中にバッファが矢印操作以外で変わったらナビ解除
  if (( __hl_navigating )); then
    if [[ "$BUFFER" != "$__hl_nav_buffer" ]]; then
      __hl_navigating=0
      __hl_index=0
      __hl_nav_buffer=""
    else
      return
    fi
  fi

  [[ "$BUFFER" == "$__hl_prev_buffer" ]] && return
  __hl_prev_buffer="$BUFFER"

  __hl_query="$BUFFER"
  __hl_index=0
  __hl_search "$__hl_query"
  __hl_render
}

# 上矢印: リスト上方向（古い履歴へ）、初回は一番下からスタート
__hl_up() {
  if (( ! __hl_navigating )); then
    __hl_query="$BUFFER"
    __hl_search "$__hl_query"
    (( ${#__hl_matches} == 0 )) && return
    __hl_navigating=1
    __hl_index=1
  else
    if (( __hl_index < ${#__hl_matches} )); then
      (( __hl_index++ ))
    fi
  fi
  BUFFER="${__hl_matches[$__hl_index]}"
  CURSOR=${#BUFFER}
  __hl_prev_buffer="$BUFFER"
  __hl_nav_buffer="$BUFFER"
  __hl_render
}

# 下矢印: リスト下方向（新しい履歴へ / 元の入力に戻る）、初回は一番上からスタート
__hl_down() {
  if (( ! __hl_navigating )); then
    __hl_query="$BUFFER"
    __hl_search "$__hl_query"
    (( ${#__hl_matches} == 0 )) && return
    __hl_navigating=1
    __hl_index=${#__hl_matches}
    BUFFER="${__hl_matches[$__hl_index]}"
    CURSOR=${#BUFFER}
    __hl_prev_buffer="$BUFFER"
    __hl_nav_buffer="$BUFFER"
    __hl_render
    return
  fi

  if (( __hl_index > 1 )); then
    (( __hl_index-- ))
    BUFFER="${__hl_matches[$__hl_index]}"
    CURSOR=${#BUFFER}
    __hl_prev_buffer="$BUFFER"
    __hl_nav_buffer="$BUFFER"
  else
    __hl_navigating=0
    __hl_index=0
    __hl_nav_buffer=""
    BUFFER="$__hl_query"
    CURSOR=${#BUFFER}
    __hl_prev_buffer="$BUFFER"
  fi
  __hl_render
}

__hl_init() {
  __hl_prev_buffer="__hl_unset__"
  __hl_show
}
zle -N zle-line-init __hl_init
zle -N zle-line-pre-redraw __hl_show
zle -N __hl_up
zle -N __hl_down

bindkey '\e[A'  __hl_up
bindkey '\eOA'  __hl_up
bindkey '\e[B'  __hl_down
bindkey '\eOB'  __hl_down

__hl_reset() {
  __hl_prev_buffer="__hl_unset__"
  __hl_navigating=0
  __hl_index=0
  __hl_matches=()
  __hl_nav_buffer=""
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd __hl_reset
