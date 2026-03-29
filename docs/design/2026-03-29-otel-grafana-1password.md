# OTel テレメトリ + Grafana Cloud + 1Password 統合計画

## 概要

Claude Code の利用状況を OpenTelemetry で収集し、Grafana Cloud で可視化する。
シークレット管理を 1Password に一元化し、chezmoi テンプレートから参照する。

## ステップ

### Step 1: 1Password セットアップ (手動)

- 1Password アカウント作成
- `op` CLI を mise に追加
- `op signin` で認証

### Step 2: chezmoi + 1Password 連携 (実装)

- `dot_config/chezmoi/chezmoi.toml.tmpl` に 1Password 設定追加
  - `onepassword.mode = "account"` 等
- テンプレートで `{{ onepasswordRead "op://vault/item/field" }}` が使えるようになる

### Step 3: Grafana Cloud TF スタック (実装)

- `terraform/grafana/` を新設
  - `grafana/grafana` プロバイダー
  - `grafana_cloud_stack` でスタック作成 (Grafana + Mimir + Loki + Tempo)
  - `grafana_cloud_access_policy` + `grafana_cloud_access_policy_token` で OTLP 書き込みトークン生成
  - 1Password TF プロバイダーでトークンを 1Password に自動保存
  - terragrunt 管理 (GitHub TF と同様)
- 手動作業: Grafana Cloud アカウント作成 + 初回 API キー発行

### Step 4: CC の OTel 設定 (実装)

- `dot_claude/settings.json` を `.tmpl` にテンプレート化
- 追加する環境変数:
  - `CLAUDE_CODE_ENABLE_TELEMETRY=1`
  - `OTEL_METRICS_EXPORTER=otlp`
  - `OTEL_LOGS_EXPORTER=otlp`
  - `OTEL_EXPORTER_OTLP_ENDPOINT` (Grafana Cloud OTLP エンドポイント)
  - `OTEL_EXPORTER_OTLP_HEADERS` (1Password から `onepasswordRead` で注入)
  - `OTEL_LOG_USER_PROMPTS=1`
- distribute_ai_agent_configs.sh の対応確認 (テンプレート化による影響)

### Step 5: Grafana ダッシュボード TF 管理 (実装)

- `grafana_dashboard` リソースで定義
  - 日別コスト / トークン使用量
  - ツール実行頻度 / 成功率
  - セッション時間推移

## 後で詰める項目

### テレメトリ詳細設計

- CC 標準メトリクス (トークン、コスト、セッション数、コード変更行数等)
- ユーザープロンプトログ (Loki)
- skills 呼び出しトラッキング
- dispatch ツールのメトリクス (TypeScript OTel SDK で自前実装、同じ Grafana に集約)

### 既存 .env の 1Password 一元化

- 散らばっている secrets を 1Password に集約
- chezmoi テンプレートから `onepasswordRead` で参照に統一

### データエクスポート / バックアップ

- Grafana API / Prometheus API で定期エクスポート
- Cloudflare R2 に保存 (既存 TF モジュール活用)

## 技術スタック

| コンポーネント | 用途 |
|---|---|
| Grafana Cloud (Free) | 可視化基盤。メトリクス 13 ヶ月保持、ログ 50GB/月 |
| Mimir (Prometheus 互換) | メトリクス保存。PromQL クエリ |
| Loki | ログ/イベント保存。プロンプトログ含む |
| OTel (CC ネイティブ) | CC → Grafana へのデータ送信 |
| OTel SDK (TypeScript) | dispatch ツール → Grafana へのデータ送信 |
| 1Password + chezmoi | シークレット管理 |
| Terraform (grafana/grafana) | Grafana Cloud リソース管理 |

## 選定理由

- **Grafana Cloud**: 無料枠最長の 13 ヶ月メトリクス保持。OTLP 直接受信可。ダッシュボード自由度高
- **1Password**: chezmoi ネイティブ連携。TF プロバイダーあり。secrets 一元管理
- **Datadog/SigNoz は除外**: 無料枠が不十分。New Relic は 8 日保持で短すぎ
