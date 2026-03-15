# エージェントオーケストレーション パターンと設計指針

## オーケストレーションパターン

### パターン一覧

| パターン | 構造 | 適用場面 |
|---------|------|---------|
| Sequential | 直列パイプライン | 定型的なステップ処理 |
| Supervisor | 中央オーケストレータ + ワーカー | 動的なタスク分解・委譲 |
| Hierarchical | 多階層の監督構造 | 大規模で複雑なワークフロー |
| Mesh / P2P | エージェント間の直接通信 | 障害耐性が必要な協調作業 |
| Concurrent | 並列実行 + 結果集約 | 独立した読み取り中心のタスク |

### Claude Code での実現手段

| 手段 | 通信 | コンテキスト | 適用 |
|------|------|-------------|------|
| サブエージェント | 親への報告のみ | メインと共有（独立実行） | 焦点を絞ったタスク、コスト抑制 |
| エージェントチーム（実験的） | 相互メッセージ可能 | 各自独立 | 複雑な並列協調作業 |

## オーケストレータは必要か

- **サブエージェント構成**: メインセッションがオーケストレータを兼ねる。専用エージェント不要
- **エージェントチーム構成**: チームリード（起動元セッション）がオーケストレータを兼ねる
- **結論**: Claude Codeではメインセッション自体がオーケストレータなので、最高意思決定者を別途定義する必要はない

## 設計原則

1. **シンプルに始める** — 単一エージェント+良いツール > 設計の甘いマルチエージェント
2. **複雑さは成果で正当化する** — エージェント追加は計測可能な改善がある場合のみ
3. **読み取りは並列化、書き込みは直列化** — 調査・レビューはマルチエージェント向き、実装は単一エージェント向き
4. **コンテキスト設計 > プロンプト設計** — エージェント間の情報フローの設計が最重要
5. **3〜5エージェントが最適** — それ以上は調整コストが支配的になる

## アンチパターン

| アンチパターン | 問題 |
|--------------|------|
| 過剰なエージェント数 | 遅延・コスト・調整コスト増大 |
| プロンプトで構造的問題を解決 | アーキテクチャの問題はプロンプトでは直らない |
| 非構造的なエージェント間通信 | 型付きスキーマ・契約を強制すべき |
| メモリの肥大化 | 古いコンテキストによる幻覚・不整合 |
| 並列書き込み | ファイル競合。各エージェントが担当ファイルを分離すべき |
| 早すぎる階層化 | フラット構成で不足を確認してから階層化する |
| 観測性の欠如 | トレース・ログなしではデバッグ不可能 |

## 宣言的定義のトレンド

エージェント定義をコード（YAML/Markdown）としてバージョン管理する方式が主流：

- **Claude Code**: Markdown + YAMLフロントマター（`.claude/agents/`）
- **CrewAI**: `config/agents.yaml`（役割・目標・背景を定義）
- **Microsoft Agent Framework**: 宣言的JSON/YAML
- **Open Agent Specification**: フレームワーク非依存の移植可能な定義

## 参考資料

- [Anthropic - Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Claude Code - Sub-Agents](https://code.claude.com/docs/en/sub-agents)
- [Claude Code - Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [GitHub Blog - Multi-Agent Workflows Often Fail](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/)
- [LangChain - How and When to Build Multi-Agent Systems](https://blog.langchain.com/how-and-when-to-build-multi-agent-systems/)
- [Microsoft Azure - AI Agent Design Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
