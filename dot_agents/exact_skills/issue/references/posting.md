# 投稿・sub-issue 紐付けコマンド

## 投稿

```bash
gh issue create --repo {repo} \
  --title "..." \
  --body-file <(obsidian read vault=obsidian-vault path="{org}/note/{date}-{title}.md" | sed '/^---$/,/^---$/d') \
  --label "..."
```

投稿後、draft 末尾に投稿URLを追記:

```bash
obsidian append vault=obsidian-vault \
  path="{org}/note/{date}-{title}.md" \
  content="\n\n---\nPosted: {issue-url}"
```

## sub-issue 紐付け（該当時）

GitHub のsub-issue APIで紐付ける。`gh issue --help` で最新のサブコマンド対応を確認。

一般的には `POST /repos/{owner}/{repo}/issues/{parent}/sub_issues` で `sub_issue_id` を渡す。`sub_issue_id` は issue の **database id**（`gh api repos/{repo}/issues/{num} --jq .id`）で、node_id や issue number とは別物。

APIが想定どおり動かない場合は、親issue本文の Tasklist に `- [ ] #{child}` を追記する案をユーザーに提示する（自動編集はしない）。
