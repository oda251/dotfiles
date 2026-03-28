# 技術スタック: インフラ

## IaC: Terraform + Terragrunt

- インフラは全て Terraform で管理する
- 環境間の DRY には Terragrunt を使う

## GitHub 管理: Terraform GitHub Provider

- リポジトリ設定、ブランチ保護、Actions 設定を Terraform で管理する
- main 直プッシュ禁止、CI 通過を PR マージの必須条件にする
- CI は GitHub Reusable Workflows で共通化し、各リポジトリから `uses:` で呼ぶ
- tfstate はローカル管理（リモートバックエンド不要）。`.gitignore` で除外
- Terraform コードは `terraform/github/` に配置

## クラウド: Cloudflare 優先

- 基本は Cloudflare に閉じる（Workers, Pages, D1, R2, KV, Queues 等）
- Cloudflare で満たせない、または有料になる場合に他クラウドを検討する
