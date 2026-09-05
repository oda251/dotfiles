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

# R2 出力なし: コマンド行のみを返す
() {
  local text expected actual
  text="$(
    prompt_block 'true'
    prompt_block 'cpl'
  )"
  expected='$ true'
  actual="$(print -r -- "$text" | __cpl_extract 'true')"
  assert_eq "R2 出力なしならコマンド行のみ" "$expected" "$actual"
}

# R3 履歴不一致: cpl 行を読み飛ばし、直近の非 cpl コマンド行を対象にする
() {
  local text expected actual
  text="$(
    prompt_block 'echo hi'
    print -r -- "hi"
    prompt_block 'cpl'
    print -r -- "cpl: 2 行コピーしました"
    prompt_block 'cpl'
  )"
  expected=$'$ echo hi\nhi'
  actual="$(print -r -- "$text" | __cpl_extract '')"
  assert_eq "R3 履歴不一致なら直近の非 cpl コマンドを対象にする" "$expected" "$actual"
}

# R4 出力中の偽プロンプト: 終端は自分自身(cpl)の実行行。偽プロンプト行は出力に含める
() {
  local text expected actual
  text="$(
    prompt_block 'git log --oneline'
    print -r -- "abc feat: 追加"
    print -r -- "❯ これはプロンプトではなく出力の一部"
    print -r -- "def fix: 修正"
    prompt_block 'cpl'
  )"
  expected=$'$ git log --oneline\nabc feat: 追加\n❯ これはプロンプトではなく出力の一部\ndef fix: 修正'
  actual="$(print -r -- "$text" | __cpl_extract 'git log --oneline')"
  assert_eq "R4 出力中の偽プロンプト行で切り詰めない" "$expected" "$actual"
}

# R5 プロンプト行なし: 非0終了し、何も出力しない
() {
  local text actual rc
  text=$'ただのテキスト\n出力っぽい行\nプロンプトはない'
  actual="$(print -r -- "$text" | __cpl_extract 'echo hi')"
  rc=$?
  assert_eq "R5 プロンプト行が無ければ何も出力しない" "" "$actual"
  assert_eq "R5 プロンプト行が無ければ非0終了" "1" "$rc"
}

# R8 直前コマンドが cpl 自身: 一致行として採用せずフォールバックする
() {
  local text expected actual
  text="$(
    prompt_block 'echo CCC'
    print -r -- "CCC"
    prompt_block 'cpl'
    print -r -- "cpl: 2 行コピーしました（echo CCC）"
    prompt_block 'cpl'
  )"
  expected=$'$ echo CCC\nCCC'
  actual="$(print -r -- "$text" | __cpl_extract 'cpl')"
  assert_eq "R8 直前コマンドが cpl 自身ならフォールバックする" "$expected" "$actual"
}

print -r -- "---"
print -r -- "passed: $passed, failed: $failed"
(( failed == 0 ))
