---
tags:
  - investigation
  - claude-code
  - awesome-list
  - ecosystem
---
# hesreallyhim/awesome-claude-code（エコシステムカタログ）

- URL: https://github.com/hesreallyhim/awesome-claude-code
- Stars: 約 33,200
- 説明: A curated list of awesome skills, hooks, slash-commands, agent orchestrators, applications, and plugins for Claude Code

## カテゴリ構成

（[README.md 本文](https://github.com/hesreallyhim/awesome-claude-code)）

1. **Agent Skills**: スキルプラグイン
2. **Workflows & Knowledge Guides**: ワークフロー・知識ガイド
   - General
   - Ralph Wiggum（自律ループパターン）
3. **Tooling**: アプリケーション
   - IDE Integrations
   - Usage Monitors
   - Orchestrators
   - Config Managers
4. **Status Lines**: ステータスライン表示
5. **Hooks**: フックスクリプト
6. **Slash-Commands**: カスタムコマンド
   - Version Control & Git
   - Code Analysis & Testing
   - Context Loading & Priming
   - Documentation & Changelogs
   - CI / Deployment
   - Project & Task Management
7. **CLAUDE.md Files**: 設定ファイル集
   - Language-Specific
   - Domain-Specific
   - Project Scaffolding & MCP
8. **Alternative Clients**: 代替クライアント
9. **Official Documentation**: 公式ドキュメント

## 注目プロジェクト（README 本文の説明から）

### Agent Skills 部門

- **Superpowers**（obra/superpowers）: SDLC をカバーする開発方法論バンドル（[README](https://github.com/hesreallyhim/awesome-claude-code)）
- **Trail of Bits Security Skills**: CodeQL/Semgrep を使った静的解析、脆弱性検出、差分レビュー等のセキュリティ特化スキル（[README](https://github.com/hesreallyhim/awesome-claude-code)）
- **Claude Scientific Skills**（K-Dense-AI）: 研究・科学・工学・分析・金融・ライティングのスキル（[README](https://github.com/hesreallyhim/awesome-claude-code)）
- **Compound Engineering Plugin**（EveryInc）: 過去の失敗をレッスンに変換し将来の改善に活かす仕組み（[README](https://github.com/hesreallyhim/awesome-claude-code)）
- **Context Engineering Kit**（NeoLabHQ）: 最小トークンフットプリントでコンテキストエンジニアリングを最適化（[README](https://github.com/hesreallyhim/awesome-claude-code)）

### Workflow 部門

- **RIPER Workflow**: Research → Innovate → Plan → Execute → Review の 5 フェーズ。ブランチ対応メモリバンク付き（[README](https://github.com/hesreallyhim/awesome-claude-code)）
- **Simone**（claude-simone）: ドキュメント・ガイドライン・プロセスを含むプロジェクト管理ワークフロー（[README](https://github.com/hesreallyhim/awesome-claude-code)）
- **AB Method**: 大きな問題を集中的なミッションに分解するスペック駆動ワークフロー（[README](https://github.com/hesreallyhim/awesome-claude-code)）

### Ralph Wiggum パターン

自律ループで AI エージェントを仕様完了まで繰り返し実行するパターン（[README](https://github.com/hesreallyhim/awesome-claude-code)）:

- **ralph-orchestrator**: tmux 統合、安全ガードレール付き
- **ralph-wiggum-bdd**: BDD（振る舞い駆動開発）との組み合わせ

### CLAUDE.md Files 部門

- 言語特化: Go, Rust, Python, TypeScript 等
- ドメイン特化: セキュリティ、インフラ、データ
- プロジェクトスキャフォールディング & MCP

## 独自パターン

- **厳選キュレーション**: 各プロジェクトに編集者の率直なコメントを付与（「modest, simple. That's how you can tell this is really one of the best」等）
- **複数 README スタイル**: Awesome / Extra / Classic / Flat の 4 スタイルで同じ内容を提供
- **Ralph Wiggum 専用セクション**: 自律ループパターンを独立カテゴリとして扱う
- **セキュリティ警告**: 「Skills can execute arbitrary code. Only install skills from trusted sources」を明記
