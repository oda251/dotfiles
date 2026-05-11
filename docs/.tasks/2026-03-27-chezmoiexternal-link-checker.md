---
背景: chezmoi の .chezmoiexternal.toml には外部リポジトリやアーカイブへの URL が含まれる。リンク切れを放置するとapply時に失敗する。
ゴール:
  - .chezmoiexternal.toml 内の全 URL を検証する Bash スクリプト
  - CI で使える exit code ベースの結果報告（0=全て正常, 1=壊れたリンクあり）
制約:
  - 純 Bash（curl + toml パース）
  - GitHub Actions 等の CI で動作すること
  - タイムアウト・リトライの考慮
---

## Phase 1: plan-dev
- ✅ a. [ゴールの達成](docs/.tasks/2026-03-27-dev-chezmoiexternal-link-checker.md)
