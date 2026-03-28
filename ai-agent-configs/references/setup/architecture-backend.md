# バックエンドアーキテクチャ

## FC/IS (Functional Core / Imperative Shell)

- ビジネスロジック（Core）は純粋関数で書く。副作用・I/O を持たない
- 副作用（DB, API, ファイル等）は外殻（Shell）に押し出す
- Shell が入力を受け取り、Core を呼び、結果に基づいて副作用を実行する
- Core はテスト容易。Shell はテスト時に実際の依存が必要
