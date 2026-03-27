---
tags:
  - investigation
  - backend
  - language-trends
  - startup
  - go
  - rust
  - kotlin
  - typescript
---
# スタートアップ・Web開発でのバックエンド言語動向 2025-2026

## 全体像: Stack Overflow Developer Survey 2025

- JavaScript: プロフェッショナル開発者の 68.8% が使用（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）
- Python: プロフェッショナル開発者の 54.8% が使用。前年から 7 ポイント増加し、AI・データサイエンス・バックエンドの需要が牽引（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）
- TypeScript: プロフェッショナル開発者の 48.8% が使用（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）
- Go: プロフェッショナル開発者の 17.4% が使用（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）
- Rust: プロフェッショナル開発者の 14.5% が使用（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）
- Kotlin: プロフェッショナル開発者の 11.5% が使用（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）

### Admired / Desired

- Rust は 9 年連続で最も「admired」な言語（72%）（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）
- TypeScript は「desired」で 56.4%、Rust は 52.8%（[Stack Overflow Developer Survey 2025 - Technology](https://survey.stackoverflow.co/2025/technology)）

## GitHub Octoverse 2025

- TypeScript が 2025 年 8 月に GitHub 月間コントリビュータ数で 1 位に。月間コントリビュータ 2,636,006 人、前年比 +66.63%（約 105 万人増）。Python・JavaScript を抜き、10 年以上で最大の言語シフト（[GitHub Blog - Octoverse 2025](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)）
- GitHub 全体で開発者 1 億 8,000 万人超、過去 1 年で 3,600 万人が新規参加（[GitHub Blog - Octoverse 2025](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)）
- LLM SDK をインポートする公開リポジトリが 110 万超（前年比 +178%）（[GitHub Blog - Octoverse 2025](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)）

## TypeScript

- GitHub で 1 位になった背景として、型付き言語が AI コード生成との親和性が高い点、主要フレームワーク（Next.js 等）がデフォルトで TypeScript を採用している点が挙げられている（[GitHub Blog - Octoverse 2025](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)）
- フルスタックエコシステム（Next.js, Node.js, TypeScript ベース ORM）が Ruby on Rails や Go と MVP・SaaS 開発領域で直接競合している（[Rubyroid Labs - Best Programming Languages 2025-2030](https://rubyroidlabs.com/blog/2025/10/most-popular-programming-languages/)）

## Go

### 開発者人口・ランキング

- プライマリ言語として Go を使うプロフェッショナル開発者は約 220 万人（5 年前の 2 倍）。プライマリまたはセカンダリとして使う開発者は 500 万人超（[JetBrains GoLand Blog - Go Ecosystem 2025](https://blog.jetbrains.com/go/2025/11/10/go-language-trends-ecosystem-2025/)）
- TIOBE Index で 2024 年 1 月の 13 位から 2025 年 1 月に 7 位へ急上昇（[JetBrains GoLand Blog - Go Ecosystem 2025](https://blog.jetbrains.com/go/2025/11/10/go-language-trends-ecosystem-2025/)）
- JetBrains Language Promise Index で 4 位（TypeScript, Rust, Python に次ぐ）（[JetBrains GoLand Blog - Go Ecosystem 2025](https://blog.jetbrains.com/go/2025/11/10/go-language-trends-ecosystem-2025/)）
- 全ソフトウェア開発者の 11% が今後 12 か月以内に Go の採用を計画（[JetBrains GoLand Blog - Go Ecosystem 2025](https://blog.jetbrains.com/go/2025/11/10/go-language-trends-ecosystem-2025/)）

### バックエンド採用率と企業規模

- バックエンド開発者の 11% が Go を使用。この比率は過去 2.5 年間安定しているが、バックエンド開発者の母数が 70 万人以上増加したため、Go コミュニティの絶対数は成長（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）
- 企業規模が大きいほど Go 採用率が高い: フリーランス 7% → 大企業（1,000人超）13%（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）
- 西ヨーロッパで最も採用率が高く 15%、中国で最も低く 5%（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）

### フレームワーク

- Gin: Go 開発者の 48%（2020 年の 41% から増加）。Echo: 16%。Fiber: 11%（[JetBrains GoLand Blog - Go Ecosystem 2025](https://blog.jetbrains.com/go/2025/11/10/go-language-trends-ecosystem-2025/)）

### クラウドネイティブ

- CNCF の主要プロジェクト（Kubernetes, Docker, CoreDNS, Prometheus）は Go で構築されている（未検証 — 検索スニペットに記載あるが該当ページの本文確認不可）
- クラウドネイティブ開発者は全世界で 1,990 万人（全開発者の約 39%）。バックエンド開発者の 52% がクラウドネイティブに分類される（2025 Q1 の 49% から増加）（[CNCF and SlashData Report Q1 2026](https://www.cncf.io/announcements/2026/03/24/cncf-and-slashdata-report-finds-cloud-native-community-reaches-nearly-20-million-developers/)）

### ユースケース

- マイクロサービス、バックエンド API、インフラツール、CLI ツールが主要ユースケース（[Rubyroid Labs - Best Programming Languages 2025-2030](https://rubyroidlabs.com/blog/2025/10/most-popular-programming-languages/)）
- スタートアップや高速開発環境では Go のプラグマティズムが Rust の厳密さより好まれる傾向（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）

## Rust

### 組織導入

- 45.5% の組織が Rust を「非自明な形で」使用（2024 年の 38.7% から増加、前年比 +17.6%）（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）
- 商用 Rust 利用は 2021〜2025 年で 68.75% 成長（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）
- Rust を本番で運用中の組織のうち、84.8% が「目標達成に役立った」、78.5% が「コストに見合った」、65.4% が「再び採用する」と回答（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）

### バックエンド採用率

- バックエンド開発者の 5% が Rust を使用（過去 2.5 年間横ばい）（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）
- エンタープライズ Rust デプロイの用途: サーバーサイド/バックエンド 51.7%、クラウドコンピューティング 25.3%、分散システム約 22%（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）
- 開発者の 38.2% が Rust をコーディングの大半に使用（2023 年の 34% から増加）（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）

### 企業規模との関係

- Go とは逆に、企業規模が大きいほど Rust 採用率は低下: フリーランス 6% → 大企業 3%（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）
- スタートアップやニッチ企業はブロックチェーン、セキュリティ、パフォーマンスクリティカル領域で Rust を選択する傾向（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）

### 求人・給与

- Rust 求人は前年比 +35% 増加。過去 2 年間で 2 倍以上（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）
- 平均年収 $130,292、スタートアップ平均より 15.5% のプレミアム（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）
- 経験豊富な Rust 開発者は依然として希少（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）

### 2025 State of Rust Survey

- 回答者 7,156 人（2024 年の 7,310 人から微減）。調査期間: 2025 年 11 月 17 日〜12 月 17 日（[Rust Blog - 2025 State of Rust Survey Results](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)）
- 30% が 1 か月以内に Rust を使い始めた（新規参入が増加）（[JetBrains RustRover Blog - State of Rust 2025](https://blog.jetbrains.com/rust/2026/02/11/state-of-rust-2025/)）
- 78% が AI コーディングアシスタントを積極的に使用（[JetBrains RustRover Blog - State of Rust 2025](https://blog.jetbrains.com/rust/2026/02/11/state-of-rust-2025/)）
- 41.6% が言語の複雑性増加を懸念（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）
- 生産性到達に 3〜6 か月（Go は 1〜2 週間）（[byteiota - Rust 2025 Survey](https://byteiota.com/rust-2025-survey-45-5-adoption-41-6-worry-complexity/)）

## Kotlin

### バックエンド採用の全体像

- Kotlin ユーザーの半数がバックエンド開発に使用（KotlinConf 2025 キーノートで発表）（[JetBrains Kotlin Blog - Kotlin on the Backend](https://blog.jetbrains.com/kotlin/2025/08/kotlin-on-the-backend-what-s-new-from-kotlinconf-2025/)）
- Spring 開発者の 27% が Kotlin を使用したことがある（KotlinConf 2025 で発表）（[JetBrains Kotlin Blog - Strategic Partnership with Spring](https://blog.jetbrains.com/kotlin/2025/05/strategic-partnership-with-spring/)）

### 開発者人口

- アクティブ開発者は全世界で 190 万人超（未検証 — 検索スニペットに記載あるが該当ページの本文で直接確認できず）

### エンタープライズ採用事例

以下は Kotlin 公式サイトのケーススタディページから確認（[Kotlin Case Studies](https://kotlinlang.org/lp/server-side/case-studies/)）:

- **Google**: サーバー・Android を合わせて 1,100 万行超の Kotlin コード。サーバーサイド JVM 開発の推奨言語として採用
- **Amazon Fashion**: Java から Kotlin へ 1 万行のバックエンドサービスを移行。19 ロケールで数億人の顧客にサービス提供
- **ING**: 600 万モバイルユーザー、年間 45 億件の決済を処理。Java から Kotlin へ移行
- **Mercedes-Benz.io**: 日間 350 万ユーザー超。Java から Kotlin + Spring Boot へ移行
- **Worldline**: 月間 100 万アクティブユーザー超。会話プラットフォームを Kotlin でフルスクラッチ構築
- **DoorDash**: レガシーモノリスを Kotlin で複数バックエンドサービスに分割
- **Kingfisher（B&Q, Castorama）**: バックエンドサービスのデフォルト言語として Kotlin を採用
- **AWS QLDB**: Amazon Quantum Ledger Database が Kotlin を使用
- **その他**: Expedia, Atlassian (Jira), Adobe, Faire, Allegro, Shazam, Intuit, N26, Memo Bank, OLX

### フレームワーク

- **Spring**: JetBrains と Spring チームが戦略的パートナーシップを発表。null 安全性の強化、Kotlin 中心のドキュメント、kotlinx.reflect による高速リフレクション（[JetBrains Kotlin Blog - Strategic Partnership with Spring](https://blog.jetbrains.com/kotlin/2025/05/strategic-partnership-with-spring/)）
- **Ktor**: 採用が前年比 +37% 増加。Ktor 3 では I/O パフォーマンスが最大 3 倍向上（[JetBrains Kotlin Blog - Kotlin on the Backend](https://blog.jetbrains.com/kotlin/2025/08/kotlin-on-the-backend-what-s-new-from-kotlinconf-2025/)）
- **Exposed**: 1.0 Beta に到達。R2DBC 完全対応でノンブロッキング操作を実現（[JetBrains Kotlin Blog - Kotlin on the Backend](https://blog.jetbrains.com/kotlin/2025/08/kotlin-on-the-backend-what-s-new-from-kotlinconf-2025/)）

## ユースケース別の使い分け

| ユースケース | 主要言語 | 根拠 |
|---|---|---|
| MVP・SaaS 高速開発 | TypeScript (Node.js/Next.js) | フルスタック統一、フレームワーク充実（[Rubyroid Labs](https://rubyroidlabs.com/blog/2025/10/most-popular-programming-languages/)） |
| クラウドインフラ・マイクロサービス | Go | 並行処理モデル、CNCF エコシステム（[JetBrains GoLand Blog](https://blog.jetbrains.com/go/2025/11/10/go-language-trends-ecosystem-2025/)） |
| パフォーマンスクリティカル・セキュリティ | Rust | メモリ安全性、高パフォーマンス（[Developer Nation](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)） |
| Java 既存資産の近代化 | Kotlin | Java 完全互換、null 安全、Spring 連携（[Kotlin Case Studies](https://kotlinlang.org/lp/server-side/case-studies/)） |
| AI・データパイプライン | Python | AI/ML エコシステム、前年比 7pt 増（[Stack Overflow Survey 2025](https://survey.stackoverflow.co/2025/technology)） |

## スタートアップ固有の傾向

- スタートアップや高速開発環境では Go のプラグマティズムが好まれ、Rust の厳密さは専門領域（ブロックチェーン、セキュリティ等）に限定される傾向（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）
- Rust はフリーランス（6%）でのほうが大企業（3%）より採用率が高く、ニッチ・スタートアップ向けの性格が強い（[Developer Nation - Go and Rust Among Backend Developers](https://www.developernation.net/blog/exploring-the-adoption-of-go-and-rust-among-backend-developers/)）
- TypeScript のフルスタックエコシステムが Rails や Go と MVP 開発で直接競合（[Rubyroid Labs - Best Programming Languages 2025-2030](https://rubyroidlabs.com/blog/2025/10/most-popular-programming-languages/)）
- Kotlin はバックエンドで急速に存在感を増しているが、スタートアップでの新規採用よりも Java 既存資産を持つ企業での移行が中心（[Kotlin Case Studies](https://kotlinlang.org/lp/server-side/case-studies/)）
