# 技術スタック: インフラ

## IaC: Terraform + Terragrunt

- インフラは全て Terraform で管理する
- 環境間の DRY には Terragrunt を使う
- tfstate は Terraform Cloud（local 実行モード）で管理

## GitHub 管理: Terraform GitHub Provider

- リポジトリ設定、ブランチ保護、Actions Secrets を Terraform で管理する
- main 直プッシュ禁止、CI 通過を PR マージの必須条件にする
- Terraform コードは `terraform/github/` に配置

## Terraform CI/CD

- 共通 composite actions（`oda251/dotfiles/.github/actions/terraform-*`）をステップとして呼ぶ
  - `terraform-setup`: Terraform/Terragrunt インストール、init、TFC local 実行モード設定
  - `terraform-plan`: plan 実行、出力キャプチャ、変更検知
  - `terraform-apply`: apply 実行、出力キャプチャ
  - `terraform-comment`: PR に plan/apply 結果を投稿（diff ハイライト、切り詰め対応）
- ワークフローは個別リポジトリで定義（パスフィルタ等はリポジトリ固有）
- PR 作成時に自動 plan、`/apply` コメントで apply（OWNER のみ）、main マージ時に自動 apply

## クラウド: Cloudflare 優先

- 基本は Cloudflare に閉じる（Workers, Pages, D1, R2, KV, Queues 等）
- Cloudflare で満たせない、または有料になる場合に他クラウドを検討する
