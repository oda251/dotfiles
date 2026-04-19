# memo-bot

Discord DM → Cloudflare Workers (cron) → GitHub (obsidian-vault Inbox) のパイプライン。

## アーキテクチャ

```
iPhone Discord → Bot に DM
  ↓
Cloudflare Workers Cron (15min)
  ↓ Discord REST API で新着DM取得 (polling)
  ↓ GitHub API で vault に append
obsidian-vault/Inbox/YYYY-MM-DD.md (JST)
```

- Bot は常駐不要（DMはDiscord側に保管される）
- 許可ユーザー (ALLOWED_DISCORD_USER_ID) の DM のみ処理
- 最終処理メッセージ ID は KV に保存

## デプロイ前の事前セットアップ（手動）

### 1. Discord Bot

1. [Discord Developer Portal](https://discord.com/developers/applications) で New Application
2. 左メニュー「Bot」 → 「Add Bot」
3. **Privileged Gateway Intents**: `MESSAGE CONTENT INTENT` を **ON**
4. 「Reset Token」で Bot Token 取得 → `DISCORD_BOT_TOKEN`
5. 左メニュー「OAuth2」→「URL Generator」:
   - Scopes: `bot`
   - Bot Permissions: `Read Messages/View Channels`, `Read Message History`
6. 生成URLで個人サーバーに招待（サーバーが無ければ1つ作る）
7. 自分の Discord User ID をコピー（設定→詳細設定→開発者モード ON にしてから自分のアイコンを右クリック）→ `ALLOWED_DISCORD_USER_ID`

### 2. GitHub Fine-grained PAT

1. [GitHub Settings → Developer settings → Personal access tokens → Fine-grained](https://github.com/settings/tokens?type=beta) で Generate new token
2. Repository access: Only select repositories → `obsidian-vault`
3. Permissions: Contents → **Read and write**
4. トークン値を `GITHUB_PAT_VAULT_WRITE` として控える

### 3. Cloudflare

1. [Cloudflare dashboard](https://dash.cloudflare.com) でアカウント作成（未登録なら）
2. 右下「Account ID」をコピー → `CLOUDFLARE_ACCOUNT_ID`
3. My Profile → API Tokens → Create Token → "Edit Cloudflare Workers" テンプレート
4. トークン値を `CLOUDFLARE_API_TOKEN` として控える

### 4. Pulumi ESC にシークレット投入

```bash
cd pulumi
esc env set oda251/dotfiles/prod values.secrets.cloudflareApiToken --secret "$CLOUDFLARE_API_TOKEN"
esc env set oda251/dotfiles/prod values.secrets.memoBotDiscordToken --secret "$DISCORD_BOT_TOKEN"
esc env set oda251/dotfiles/prod values.secrets.memoBotGithubPat --secret "$GITHUB_PAT_VAULT_WRITE"
esc env set oda251/dotfiles/prod values.cloudflare.accountId "$CLOUDFLARE_ACCOUNT_ID"
esc env set oda251/dotfiles/prod values.memoBot.allowedDiscordUserId "$ALLOWED_DISCORD_USER_ID"
```

## ビルド & デプロイ

```bash
# 1. Worker バンドル作成
cd apps/memo-bot
bun install
bun run build

# 2. Pulumi で Cloudflare リソースをデプロイ
cd ../../pulumi
bun install
pulumi up
```

## 動作確認

1. Discord で Bot に DM を送る
2. 最大15分で `obsidian-vault/Inbox/YYYY-MM-DD.md` に `- HH:MM 💬 <内容>` が追加される（Daily note から transclusion で表示される）
3. PC で `cd ~/obsidian-vault && git pull` するとメモが反映される

## トラブルシューティング

- **最初の DM が反映されない**: 初回実行時はベースライン設定のみ行い、その時点で Discord に残っている過去メッセージは処理しない。2通目から動く。
- **Cloudflare ログ確認**: `wrangler tail memo-bot`
- **KV reset**: `wrangler kv:key delete --namespace-id=<id> "last_msg:<channel_id>"`

## ローカル開発

```bash
cp .dev.vars.example .dev.vars  # 値を埋める
wrangler dev
```
