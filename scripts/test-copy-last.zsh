#!/usr/bin/env zsh
# dot_zsh/copy-last.zsh のユニットテスト
# 実行: zsh scripts/test-copy-last.zsh

typeset -g REPO_ROOT="${0:A:h:h}"
source "$REPO_ROOT/dot_zsh/copy-last.zsh"

typeset -gi passed=0 failed=0

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    (( ++passed ))
    print -r -- "ok   - $name"
  else
    (( ++failed ))
    print -r -- "NG   - $name"
    print -r -- "  expected: ${(qqq)expected}"
    print -r -- "  actual:   ${(qqq)actual}"
  fi
}

# starship のプロンプトブロック（空行 / パワーライン行 / コマンド行）
prompt_block() {
  print -r -- ""
  print -r -- "░▒▓ 🐾 …/chezmoi   main   20:27 "
  print -r -- "❯ $1"
}

# R1 基本形: コマンド行 + 出力2行
() {
  local text expected actual
  text="$(
    prompt_block 'echo hello; echo world'
    print -r -- "hello"
    print -r -- "world"
    prompt_block 'cpl'
  )"
  expected=$'$ echo hello; echo world\nhello\nworld'
  actual="$(print -r -- "$text" | __cpl_extract 'echo hello; echo world')"
  assert_eq "R1 コマンド行と出力を切り出す" "$expected" "$actual"
}

print -r -- "---"
print -r -- "passed: $passed, failed: $failed"
(( failed == 0 ))
