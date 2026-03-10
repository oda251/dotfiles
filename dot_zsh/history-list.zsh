# 常時履歴リスト表示 + 矢印キー選択プラグイン
# 補完システムに触れないため Tab/fzf-tab と衝突しない

typeset -g __hl_prev_buffer=""
typeset -g __hl_max_lines=8
typeset -ga __hl_matches=()
typeset -g __hl_index=0
typeset -g __hl_query=""
typeset -g __hl_navigating=0
typeset -g __hl_nav_buffer=""

__hl_search() {
  __hl_matches=()
  local -A seen=()
  local line
  for line in "${(@)history}"; do
    if [[ -n "$1" ]]; then
      [[ "$line" != "$1"* || "$line" == "$1" ]] && continue
    fi
    [[ -n "${seen[$line]+x}" ]] && continue
    seen[$line]=1
    __hl_matches+=( "$line" )
    (( ${#__hl_matches} >= __hl_max_lines )) && break
  done
}

__hl_render() {
  if (( ${#__hl_matches} == 0 )); then
    zle -M ""
    return
  fi
  local display="" idx=1
  while (( idx <= ${#__hl_matches} )); do
    if (( __hl_navigating && idx == __hl_index )); then
      display+="▸ ${__hl_matches[$idx]}"$'\n'
    else
      display+="  ${__hl_matches[$idx]}"$'\n'
    fi
    (( idx++ ))
  done
  zle -M "${display%$'\n'}"
}

# ナビゲーション解除して元の入力に戻す
__hl_exit_nav() {
  __hl_navigating=0
  __hl_index=0
  __hl_nav_buffer=""
  BUFFER="$__hl_query"
  CURSOR=${#BUFFER}
  __hl_prev_buffer="$BUFFER"
}

# 現在の index のマッチを BUFFER に反映
__hl_select_match() {
  BUFFER="${__hl_matches[$__hl_index]}"
  CURSOR=${#BUFFER}
  __hl_prev_buffer="$BUFFER"
  __hl_nav_buffer="$BUFFER"
}

__hl_show() {
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
  __hl_search "$__hl_query"
  __hl_render
}

__hl_up() {
  if (( ! __hl_navigating )); then
    __hl_query="$BUFFER"
    __hl_search "$__hl_query"
    (( ${#__hl_matches} == 0 )) && return
    __hl_navigating=1
    __hl_index=1
  elif (( __hl_index < ${#__hl_matches} )); then
    (( __hl_index++ ))
  else
    __hl_exit_nav
    __hl_render
    return
  fi
  __hl_select_match
  __hl_render
}

__hl_down() {
  if (( ! __hl_navigating )); then
    __hl_query="$BUFFER"
    __hl_search "$__hl_query"
    (( ${#__hl_matches} == 0 )) && return
    __hl_navigating=1
    __hl_index=${#__hl_matches}
  elif (( __hl_index > 1 )); then
    (( __hl_index-- ))
  else
    __hl_exit_nav
    __hl_render
    return
  fi
  __hl_select_match
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

bindkey '\e[A'  __hl_down
bindkey '\eOA'  __hl_down
bindkey '\e[B'  __hl_up
bindkey '\eOB'  __hl_up

__hl_reset() {
  __hl_prev_buffer="__hl_unset__"
  __hl_navigating=0
  __hl_index=0
  __hl_matches=()
  __hl_nav_buffer=""
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd __hl_reset
