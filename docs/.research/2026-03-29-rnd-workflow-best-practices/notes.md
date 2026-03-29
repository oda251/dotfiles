# R&D Workflow Best Practices - Research Notes

## Sources

### Spec-Driven Development (SDD)
- ThoughtWorks Technology Radar Vol.33: "Assess" ring
  - https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices
- Martin Fowler: SDD Tools (Kiro, spec-kit, Tessl)
  - https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- Amazon Kiro: Requirements(EARS) -> Design -> Tasks の3フェーズ。25万+開発者が採用
  - https://kiro.dev/
  - https://www.infoq.com/news/2025/08/aws-kiro-spec-driven-agent/
  - https://www.augmentcode.com/guides/what-is-spec-driven-development

### Agentic Workflow Architecture
- Anthropic 2026 Agentic Coding Trends Report: 明示的なワークフローステートマシン推奨
  - INTENT -> SPEC -> PLAN -> IMPLEMENT -> VERIFY -> DOCS -> REVIEW -> RELEASE -> MONITOR -> ITERATE
  - https://resources.anthropic.com/2026-agentic-coding-trends-report
- QuantumBlack (McKinsey): オーケストレーションは決定論的に、エージェントの仕事は境界付きに
  - 2層モデル: Layer1(決定論的ワークフロー) + Layer2(境界付きエージェント実行)
  - エージェントに自己オーケストレーションさせると大規模コードベースで失敗
  - https://medium.com/quantumblack/agentic-workflows-for-software-development-dc8e64f4a79d

### Plan-Execute-Verify Pattern
- SAP: Plan-then-Execute パターン
  - https://community.sap.com/t5/security-and-compliance-blog-posts/plan-then-execute-an-architectural-pattern-for-responsible-agentic-ai/ba-p/14239753
- LangChain: Planning Agents
  - https://blog.langchain.com/planning-agents/
- Google Cloud: Agentic AI Design Patterns
  - https://docs.google.com/architecture/choose-design-pattern-agentic-ai-system
- Microsoft: AI Agent Design Patterns
  - https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns

### Task Decomposition
- 縦切り(vertical slicing)が横切り(horizontal)より成果が良いという研究結果
  - https://link.springer.com/chapter/10.1007/978-3-319-57633-6_5
- EmergentMind: Task Decomposition Strategies
  - https://www.emergentmind.com/topics/task-decomposition-strategies
- SAFe: Epic -> Capability -> Feature -> Story -> Task の階層
  - https://scaledagileframework.com/epic/

### Decision Timing
- Last Responsible Moment: 決定を遅らせすぎるより早すぎる方が危険
  - https://blog.codinghorror.com/the-last-responsible-moment/
  - https://www.101ways.com/lean-principles-4-defer-commitment/
- Shape Up: appetite(予算)でスコープを制約、不確実性の高いものから着手
  - https://basecamp.com/shapeup

## Key Findings

### 1. Kiro の3フェーズが requirements -> plan -> exec に最も近い
- Requirements: 自然言語 -> EARS記法で構造化した要件+受入基準
- Design: コードベース分析 + 要件 -> アーキテクチャ・技術選定
- Tasks: 依存関係付き実装タスクリスト
- 計画と実行を分離することでコストの高い手戻りを防止

### 2. オーケストレーションは決定論的であるべき
- QuantumBlack の経験: エージェントにワークフロー順序を判断させると失敗する
- 各フェーズに決定論的な pre-event(コンテキスト設定) と post-event(検証ゲート) を設ける
- 前に進む唯一の方法は post-gate を通過すること

### 3. タスク分解は縦切り優先
- 機能スライス(縦)がレイヤー別(横)より成果が良い
- 不確実性が高いものから先に着手(Shape Up Hill Chart)
- アーキテクチャ制約は plan で決める、実装詳細は exec に委ねる(Last Responsible Moment)

### 4. AI エージェントの現実
- 複雑タスクの成功率は約50%(SWE-bench)、2026末に70-80%予測
- エンジニアはAIを60%の作業で使うが、完全委譲は0-20%のタスクのみ
- エージェントは約20アクションで人間の介入が必要になる
