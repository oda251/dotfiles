# 技術スタック: インフラ

## IaC: Terraform + Terragrunt

- インフラは全て Terraform で管理する。手動構築しない
- 環境間の DRY には Terragrunt を使う

## クラウド: Cloudflare 優先

- 運用コスト最小化を至上命題とする
- 基本は Cloudflare に閉じる（Workers, Pages, D1, R2, KV, Queues 等）
- Cloudflare で満たせない、または有料になる場合に他クラウドを検討する
