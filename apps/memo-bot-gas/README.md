# memo-bot-gas

Discord DM → Google Apps Script (time-based trigger) → GitHub (obsidian-vault Inbox) のパイプライン。

## アーキテクチャ

```
iPhone Discord → Bot に DM
  ↓ (Discord 側に保管)
GAS time-based trigger (15min)
  ↓ Discord REST (UrlFetchApp)
  ↓ GitHub REST (UrlFetchApp)
obsidian-vault/Inbox/YYYY-MM-DD.md (JST)
```

- 秘匿値は GCP Secret Manager（`dotfiles-oda251` プロジェクト）に保管
- GAS は `ScriptApp.getOAuthToken()` + `roles/secretmanager.secretAccessor` で取得
- Pulumi ESC が唯一のソース → pulumi up で Secret Manager に反映

## 初回セットアップ

### 1. Discord Bot（手動）
- [Developer Portal](https://discord.com/developers/applications) で App 作成 → Bot 追加
- `MESSAGE CONTENT INTENT` を ON
- Bot Token 取得
- 個人サーバー作成 → OAuth2 URL Generator で招待 (scope: bot, perms: Read Messages/Read History)
- 自分の Discord User ID を取得（設定→詳細設定→開発者モード ON → 自分のアイコン右クリック）

### 2. GitHub Fine-grained PAT（手動）
- [Settings → Developer settings → Fine-grained tokens](https://github.com/settings/tokens?type=beta)
- Repository: `obsidian-vault` のみ
- Permissions: Contents: Read and write

### 3. ESC に secrets 投入

```bash
esc env set oda251/dotfiles/prod values.secrets.memoBotDiscordToken --secret "$DISCORD_BOT_TOKEN"
esc env set oda251/dotfiles/prod values.secrets.memoBotGithubPat --secret "$GITHUB_PAT"
esc env set oda251/dotfiles/prod values.memoBot.allowedDiscordUserId "$DISCORD_USER_ID"
esc env set oda251/dotfiles/prod values.gcp.projectId "dotfiles-oda251"
esc env set oda251/dotfiles/prod values.gcp.userEmail "pgwyaueu@gmail.com"
```

### 4. Pulumi up（Secret Manager にシークレット投入）

```bash
cd pulumi
pulumi up
```

### 5. GAS プロジェクト作成（初回のみ）

```bash
cd apps/memo-bot-gas
clasp login                              # OAuth 1回
clasp create --type standalone --title "memo-bot" --rootDir ./src
# 生成された .clasp.json から scriptId を取得
SCRIPT_ID=$(jq -r .scriptId .clasp.json)
esc env set oda251/dotfiles/prod values.memoBot.gasScriptId "$SCRIPT_ID"
rm .clasp.json                           # ESC 経由で再生成するため削除
```

### 6. GAS を `dotfiles-oda251` GCP プロジェクトに紐付け

`clasp open-script` で Apps Script エディタを開き、Project Settings → Google Cloud Platform (GCP) Project → Change project → `dotfiles-oda251` のプロジェクト番号を入力。

## デプロイ

```bash
cd apps/memo-bot-gas
bun run deploy   # esc run で env 展開 → deploy.sh → clasp push
```

## 初回の trigger インストール

デプロイ後、GAS エディタで `installTrigger` 関数を1回実行すると 15分毎の時間ベーストリガーが登録される。OAuth の同意画面が初回に出るので承認。

## 動作確認

1. Discord で Bot に DM を送る
2. 最大15分で `obsidian-vault/Inbox/YYYY-MM-DD.md` に `- HH:MM 💬 <内容>` が追加
3. PC で `git pull` すると反映

## トラブルシューティング

- ログ: GAS エディタ → 実行履歴 もしくは Cloud Logging（`dotfiles-oda251`）
- Secret Manager アクセスエラー: `roles/secretmanager.secretAccessor` が `pgwyaueu@gmail.com` に付与されているか確認
- 初回 `pollDMs` 実行時に OAuth 同意が必要（Secret Manager + 外部 URL fetch）
