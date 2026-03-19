# パターンマッチ fzf 補完
# マッチしたら fzf で選択、しなければ fzf-tab に委譲

typeset -ga __fc_rules=()

# 登録: __fc_add <パターン> <sourceCommand> <fzf opts> [callback]
__fc_add() {
  __fc_rules+=("$1"$'\x1f'"$2"$'\x1f'"$3"$'\x1f'"${4:-cat}")
}

# --- 補完定義 ---

__fc_add '^claude( --dangerously-skip-permissions)? $' \
  "claude --help 2>&1 | sed -n '/^Commands:/,/^\$/p' | tail -n +2 | awk 'NF{printf \"%-20s\\t%s\\n\", \$1, substr(\$0, index(\$0,\$2))}'" \
  "--prompt 'Claude> '" \
  "awk -F'\\t' '{print \$1}' | tr -d ' '"

__fc_add '^git switch $|^gsw $' \
  "git branch --format='%(refname:short)' --sort=-committerdate" \
  "--prompt 'Branch> ' --preview 'git log --oneline -20 {}'"

__fc_add '^git checkout $|^gco $' \
  "git branch -a --format='%(refname:short)' --sort=-committerdate" \
  "--prompt 'Branch> ' --preview 'git log --oneline -20 {}'"

__fc_add '^git add $|^ga $' \
  "git status --short | awk '{print \$2}'" \
  "--multi --prompt 'Git Add> ' --preview 'git diff --color=always -- {}'"

__fc_add '^git diff $|^gd $' \
  "git diff --name-only" \
  "--multi --prompt 'Git Diff> ' --preview 'git diff --color=always -- {}'"

__fc_add '^git stash (pop|apply|drop|show) $' \
  "git stash list" \
  "--prompt 'Stash> ' --preview 'git stash show -p {1}'" \
  "awk -F: '{print \$1}'"

__fc_add '^docker (stop|restart|logs|exec|rm|inspect) $' \
  "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | sed 1d" \
  "--prompt 'Container> '" \
  "awk '{print \$1}'"

__fc_add '^docker rmi $|^docker image (rm|inspect) $' \
  "docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}' | sed 1d" \
  "--multi --prompt 'Image> '" \
  "awk '{print \$1}'"

__fc_add '^kubectl (-n|--namespace) $' \
  "kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{\"\\n\"}{end}'" \
  "--prompt 'Namespace> '"

__fc_add '^kubectl (-n \S+ )?(logs|exec|describe|delete|port-forward) (pod/)?$' \
  "kubectl get pods --no-headers" \
  "--prompt 'Pod> '" \
  "awk '{print \$1}'"

__fc_add '^kill [^-]' \
  "LANG=C ps -ef | sed 1d" \
  "--multi --prompt 'Kill> '" \
  "awk '{print \$2}'"

__fc_add '^(npm|bun) run $' \
  "cat package.json 2>/dev/null | jq -r '.scripts | keys[]'" \
  "--prompt 'Script> '"

__fc_add '^mise (use|install|uninstall) $' \
  "mise ls --json 2>/dev/null | jq -r 'to_entries[] | \"\\(.key)@\\(.value[0].version)\"'" \
  "--prompt 'Tool> '"

# --- widget ---

__fc_widget() {
  local rule pattern source_cmd fzf_opts callback result
  for rule in "${__fc_rules[@]}"; do
    pattern="${rule%%$'\x1f'*}"; rule="${rule#*$'\x1f'}"
    source_cmd="${rule%%$'\x1f'*}"; rule="${rule#*$'\x1f'}"
    fzf_opts="${rule%%$'\x1f'*}"
    callback="${rule#*$'\x1f'}"

    if [[ "$BUFFER" =~ $pattern ]]; then
      result="$(eval "$source_cmd" 2>/dev/null \
        | eval "fzf --height=40% --reverse --border $fzf_opts" </dev/tty \
        | eval "$callback")"
      [[ -n "$result" ]] && LBUFFER+="$result"
      zle reset-prompt
      return 0
    fi
  done

  # パターン未マッチ → 元の ^I に委譲
  zle "${__fc_fallback_widget:-expand-or-complete}"
}

# fzf-tab が ^I をバインドした後に呼ばれる前提
# 現在の ^I (= fzf-tab-complete) を保存してからラップ
__fc_fallback_widget="${${$(bindkey '^I')##* }:-expand-or-complete}"
zle -N __fc_widget
bindkey '^I' __fc_widget
