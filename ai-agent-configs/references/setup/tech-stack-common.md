# 技術スタック: 共通

言語非依存の技術選定。

## テスト基盤: Testcontainers

DB・キャッシュ・メッセージキュー等の外部依存をテスト時に Docker コンテナで起動する。mock ではなく本物を使う（`coding/testing-guideline.md` の「ローカルで再現できる依存は本物を立てる」に対応）。

- テストごとに使い捨てコンテナを起動 → テスト間の状態汚染がない
- CI でも同じコンテナが動く → ローカルと CI の差異がない
- 対応言語: Java, Python, Go, Node.js, .NET, Rust

### 言語別パッケージ

| 言語 | パッケージ |
|---|---|
| TypeScript | `testcontainers` |
| Python | `testcontainers` (`uv add --dev testcontainers`) |
| Go | `testcontainers-go` |
| Java | `org.testcontainers:testcontainers` |

### 使いどころ

| 依存 | 使う |
|---|---|
| RDB (PostgreSQL, MySQL 等) | ✅ |
| Redis, Memcached | ✅ |
| Kafka, RabbitMQ | ✅ |
| S3 互換 (MinIO) | ✅ |
| SQLite | 不要（インメモリで十分） |
| 外部 API | 不要（プロトコルレベル mock で対応） |
