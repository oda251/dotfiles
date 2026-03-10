# 常時履歴リスト表示 + 矢印キー選択プラグイン
# 補完システムに触れないため Tab/fzf-tab と衝突しない

typeset -g __hl_prev_buffer=""
typeset -g __hl_max_lines=8
typeset -ga __hl_matches=()
typeset -g __hl_index=0
typeset -g __hl_query=""
typeset -g __hl_navigating=0
typeset -g __hl_nav_buffer=""

__hl_clear_nav() {
  __hl_navigating=0
  __hl_index=0
  __hl_nav_buffer=""
}

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
  local display="" idx=1 entry
  while (( idx <= ${#__hl_matches} )); do
    entry="${__hl_matches[$idx]//$'\n'/↵}"
    if (( __hl_navigating && idx == __hl_index )); then
      display+="❯ ${entry}"$'\n'
    else
      display+="  ${entry}"$'\n'
    fi
    (( idx++ ))
  done
  zle -M "${display%$'\n'}"
}

# ナビゲーション開始（検索 + 初期カーソル位置設定）
__hl_begin_nav() {
  __hl_query="$BUFFER"
  __hl_search "$__hl_query"
  (( ${#__hl_matches} == 0 )) && return 1
  __hl_navigating=1
  __hl_index=$1
  return 0
}

__hl_exit_nav() {
  __hl_clear_nav
  BUFFER="$__hl_query"
  CURSOR=${#BUFFER}
  __hl_prev_buffer="$BUFFER"
  __hl_render
}

__hl_select_match() {
  BUFFER="${__hl_matches[$__hl_index]}"
  CURSOR=${#BUFFER}
  __hl_prev_buffer="$BUFFER"
  __hl_nav_buffer="$BUFFER"
}

__hl_show() {
  if (( __hl_navigating )); then
    if [[ "$BUFFER" != "$__hl_nav_buffer" ]]; then
      __hl_clear_nav
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

# ↓キー: 新しい方へ
__hl_up() {
  if (( ! __hl_navigating )); then
    __hl_begin_nav 1 || return
  elif (( __hl_index < ${#__hl_matches} )); then
    (( __hl_index++ ))
  else
    __hl_exit_nav
    return
  fi
  __hl_select_match
  __hl_render
}

# ↑キー: 古い方へ
__hl_down() {
  if (( ! __hl_navigating )); then
    __hl_begin_nav ${#__hl_matches} || return
  elif (( __hl_index > 1 )); then
    (( __hl_index-- ))
  else
    __hl_exit_nav
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
  __hl_clear_nav
  __hl_matches=()
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd __hl_reset
