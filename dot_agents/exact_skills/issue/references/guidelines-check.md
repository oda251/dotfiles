# community guidelines の確認項目

投稿前に以下を確認:

- `CONTRIBUTING.md`: issue起票の手順、必須情報、ラベル運用
- `CODE_OF_CONDUCT.md`: 表現や対応の禁止事項
- `SUPPORT.md` / `.github/SUPPORT.md`: 質問は Discussions や Stack Overflow へ誘導されていないか
- `README` の contributing 節

```bash
gh api repos/{repo}/contents/CONTRIBUTING.md --jq .content | base64 -d
```

APIで取れない場合（大きなrepo・branchデフォルト違い等）は `/tmp/{repo-slug}/` に `gh repo clone` してローカルで読む。
