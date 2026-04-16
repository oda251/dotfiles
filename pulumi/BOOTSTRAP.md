# Pulumi 移行ブートストラップ手順

LLM が直接実行できない（infra policy: 本番影響操作禁止）ので、user が手元で順に実行する手順書。

---

## 0. 前提

- Pulumi Cloud アカウント作成済み（`https://app.pulumi.com/oda251`）
- `mise install`（pulumi + esc CLI を新規インストール）
- `cd pulumi && bun install`

---

## 1. CLI ログイン

```bash
pulumi login           # ブラウザ起動 → token 払い出し → ~/.pulumi/credentials.json
esc login              # 同上、ESC 専用
```

---

## 2. ESC env 作成 + 値投入

### 2-1. env 作成

```bash
esc env init oda251/dotfiles/prod
```

### 2-2. テンプレート流し込み

```bash
esc env edit oda251/dotfiles/prod --file pulumi/esc/dotfiles-prod.yaml
```

（ブラウザでも編集可: `https://app.pulumi.com/oda251/esc/dotfiles/prod`）

### 2-3. 機密値を投入（PLACEHOLDER を置き換え）

既存 Infisical から値を引っ張って ESC に流す:

```bash
GITHUB_PAT=$(infisical secrets get GITHUB_PAT --plain --silent --env prod --path /terraform/env)
NR_API_KEY=$(infisical secrets get NEW_RELIC_API_KEY --plain --silent --env prod --path /terraform/env)
INFI_CID=$(infisical secrets get INFISICAL_UNIVERSAL_AUTH_CLIENT_ID --plain --silent --env prod --path /terraform/env)
INFI_CSEC=$(infisical secrets get INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET --plain --silent --env prod --path /terraform/env)

esc env set oda251/dotfiles/prod --secret values.secrets.githubToken "$GITHUB_PAT"
esc env set oda251/dotfiles/prod --secret values.secrets.newrelicApiKey "$NR_API_KEY"
esc env set oda251/dotfiles/prod --secret values.secrets.infisicalClientId "$INFI_CID"
esc env set oda251/dotfiles/prod --secret values.secrets.infisicalClientSecret "$INFI_CSEC"
```

### 2-4. 確認

```bash
esc env get oda251/dotfiles/prod
esc open oda251/dotfiles/prod  # 全 placeholder が解決されること
```

---

## 3. Pulumi stack 初期化

```bash
cd pulumi
pulumi stack init oda251/dotfiles/prod
```

`Pulumi.prod.yaml` の `environment: [dotfiles/prod]` で ESC env を読む設定済み。

---

## 4. 既存リソースを state に import

**Pulumi import block 構文（TF と同じ感じ）も使えるが、CLI のほうが手軽。各 import で 1 リソースずつ取り込む。**

### 4-1. Public リポジトリ

```bash
# Repository 本体
pulumi import github:index/repository:Repository template      template
pulumi import github:index/repository:Repository dotfiles      dotfiles
pulumi import github:index/repository:Repository garden        garden
pulumi import github:index/repository:Repository onegai        onegai

# gate.yml workflow file（visibility=public のみ）
pulumi import github:index/repositoryFile:RepositoryFile dotfiles/gate "dotfiles/.github/workflows/gate.yml:main"
pulumi import github:index/repositoryFile:RepositoryFile garden/gate   "garden/.github/workflows/gate.yml:main"
pulumi import github:index/repositoryFile:RepositoryFile onegai/gate   "onegai/.github/workflows/gate.yml:main"
# template リポは visibility=public だが gate.yml がないので除外

# terraform.yml workflow file（hasTerraform=true のみ：garden）
pulumi import github:index/repositoryFile:RepositoryFile garden/terraform "garden/.github/workflows/terraform.yml:main"

# RepositoryRuleset（visibility=public のみ）
# 事前に ruleset ID 取得が必要:
#   gh api repos/oda251/dotfiles/rulesets --jq '.[].id'
pulumi import github:index/repositoryRuleset:RepositoryRuleset dotfiles/main "dotfiles:<RULESET_ID>"
pulumi import github:index/repositoryRuleset:RepositoryRuleset garden/main   "garden:<RULESET_ID>"
pulumi import github:index/repositoryRuleset:RepositoryRuleset onegai/main   "onegai:<RULESET_ID>"
pulumi import github:index/repositoryRuleset:RepositoryRuleset template/main "template:<RULESET_ID>"
```

### 4-2. Production environment + secrets（hasInfisical=true のみ）

dotfiles 自身は hasInfisical=false にしてあるので import 不要。garden/onegai だけ:

```bash
pulumi import github:index/repositoryEnvironment:RepositoryEnvironment garden/production "garden:production"
pulumi import github:index/actionsEnvironmentSecret:ActionsEnvironmentSecret garden/production/INFISICAL_CLIENT_ID     "garden:production:INFISICAL_CLIENT_ID"
pulumi import github:index/actionsEnvironmentSecret:ActionsEnvironmentSecret garden/production/INFISICAL_CLIENT_SECRET "garden:production:INFISICAL_CLIENT_SECRET"
pulumi import github:index/actionsEnvironmentVariable:ActionsEnvironmentVariable garden/production/INFISICAL_PROJECT_SLUG "garden:production:INFISICAL_PROJECT_SLUG"

pulumi import github:index/repositoryEnvironment:RepositoryEnvironment onegai/production "onegai:production"
pulumi import github:index/actionsEnvironmentSecret:ActionsEnvironmentSecret onegai/production/INFISICAL_CLIENT_ID     "onegai:production:INFISICAL_CLIENT_ID"
pulumi import github:index/actionsEnvironmentSecret:ActionsEnvironmentSecret onegai/production/INFISICAL_CLIENT_SECRET "onegai:production:INFISICAL_CLIENT_SECRET"
pulumi import github:index/actionsEnvironmentVariable:ActionsEnvironmentVariable onegai/production/INFISICAL_PROJECT_SLUG "onegai:production:INFISICAL_PROJECT_SLUG"
```

### 4-3. Private リポジトリ（career, obsidian-vault）

```bash
pulumi import github:index/repository:Repository career         career
pulumi import github:index/repository:Repository obsidian-vault obsidian-vault
```

### 4-4. NewRelic

```bash
# Dashboard GUID 取得:
#   newrelic dashboards --account-id 7893158 list | grep "Claude Code Overview"
pulumi import newrelic:index/oneDashboard:OneDashboard claude_code_overview <DASHBOARD_GUID>

# API access key ID 取得:
#   newrelic apiaccesskey list --filter '{"keyTypes":["INGEST"]}'
pulumi import newrelic:index/apiAccessKey:ApiAccessKey ingest "<KEY_ID>:INGEST"
```

---

## 5. preview で diff ゼロ確認

```bash
cd pulumi
pulumi preview
```

**期待結果**: すべて `~ no changes` または ignore_changes 設定で suppressed。差分が出る場合は import が漏れているか、コード側の値が現状とズレてる。

差分が許容できるレベルになったら次へ。

---

## 6. dotfiles リポの GHA 環境を Pulumi 用に切り替え

dotfiles の `production` env は既存（reviewers=oda251, protected_branches=true）を流用。Pulumi CD 用に secret を入れ替え:

```bash
# 旧 Infisical 関連を削除
gh secret   delete INFISICAL_CLIENT_ID     --env production --repo oda251/dotfiles
gh secret   delete INFISICAL_CLIENT_SECRET --env production --repo oda251/dotfiles
gh variable delete INFISICAL_PROJECT_ID    --env production --repo oda251/dotfiles  # まだ残ってたら
gh variable delete INFISICAL_PROJECT_SLUG  --env production --repo oda251/dotfiles

# 新 Pulumi 用 token を投入（Pulumi Cloud → Account settings → Access Tokens で発行）
gh secret set PULUMI_ACCESS_TOKEN --env production --repo oda251/dotfiles
```

---

## 7. 動作確認

```bash
# ローカルから本番への適用 (LLM はやらない、user がやる)
pulumi up
```

実害なければ commit + push して CD 経由で apply されるか確認:

```bash
git add pulumi/ .github/workflows/pulumi.yml
git commit -m "feat: introduce Pulumi-based IaC, parallel to terraform/"
git push origin main
```

→ GHA で Pulumi workflow が走り、environment: production の承認待ちになる。承認すると `pulumi up` 実行。

---

## 8. ESC の stackRefs 復活 (first apply 後)

最初の `pulumi up` で stack outputs (`newrelicLicenseKey`, `otlpEndpoint`) が
生成されたら、`pulumi/esc/dotfiles-prod.yaml` の `stackRefs:` ブロックと
`NEWRELIC_LICENSE_KEY` / `NEWRELIC_OTLP_ENDPOINT` 環境変数のコメントを外して再投入:

```bash
esc env edit oda251/dotfiles/prod -f pulumi/esc/dotfiles-prod.yaml
# secrets は再注入が必要 (esc env edit -f は full replace)
GH=$(infisical secrets get GITHUB_PAT --plain --silent --env prod --path /terraform/env)
NR=$(infisical secrets get NEW_RELIC_API_KEY --plain --silent --env prod --path /terraform/env)
IC=$(infisical secrets get INFISICAL_UNIVERSAL_AUTH_CLIENT_ID --plain --silent --env prod --path /terraform/env)
IS=$(infisical secrets get INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET --plain --silent --env prod --path /terraform/env)
esc env set oda251/dotfiles/prod secrets.githubToken           "$GH" --secret --string
esc env set oda251/dotfiles/prod secrets.newrelicApiKey        "$NR" --secret --string
esc env set oda251/dotfiles/prod secrets.infisicalClientId     "$IC" --secret --string
esc env set oda251/dotfiles/prod secrets.infisicalClientSecret "$IS" --secret --string
```

## 9. Terraform 廃止（並行運用 OK と判断したら）

別 PR でやる。task #9 の手順は別途。

---

## ロールバック

何かおかしくなったら:

```bash
cd pulumi
pulumi stack rm oda251/dotfiles/prod  # state 削除（リソース自体は触らない）
```

ESC env も削除可:

```bash
esc env rm oda251/dotfiles/prod
```

terraform は触ってないので、Pulumi state 消すだけで戻る。
