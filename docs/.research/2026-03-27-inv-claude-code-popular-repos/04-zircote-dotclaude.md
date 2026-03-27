---
tags:
  - investigation
  - claude-code
  - dotfiles
  - agents
  - includes
---
# zircote/.claude（Claude Code dotfiles）

- URL: https://github.com/zircote/.claude
- Stars: 16（ニッチだが構成が参考になる）
- 説明: Claude Code dotfiles: agents, skills, commands & includes for AI-assisted development

## ディレクトリ構成

```
CLAUDE.md
agents/
  01-core-development/
    api-designer.md
    backend-developer.md
    frontend-developer.md
    fullstack-developer.md
    graphql-architect.md
    microservices-architect.md
    mobile-developer.md
    ui-designer.md
    websocket-engineer.md
    ...
  02-language-specialists/
    angular-architect.md
    golang-pro.md
    python-pro.md
    react-specialist.md
    rust-engineer.md
    typescript-pro.md
    ...（約 25 言語/FW 専門エージェント）
  03-infrastructure/
    cloud-architect.md
    devops-engineer.md
    kubernetes-specialist.md
    terraform-engineer.md
    ...
  04-quality-security/
    code-reviewer.md
    debugger.md
    penetration-tester.md
    performance-engineer.md
    security-auditor.md
    ...
  05-data-ai/
    ai-engineer.md
    data-scientist.md
    llm-architect.md
    ml-engineer.md
    prompt-engineer.md
    ...
  06-developer-experience/
    cli-developer.md
    documentation-engineer.md
    git-workflow-manager.md
    mcp-developer.md
    refactoring-specialist.md
    ...
  07-specialized-domains/
    blockchain-developer.md
    fintech-engineer.md
    game-developer.md
    iot-engineer.md
    ...
  08-business-product/
    business-analyst.md
    product-manager.md
    project-manager.md
    technical-writer.md
    ux-researcher.md
    ...
  09-meta-orchestration/
    agent-organizer.md
    context-manager.md
    multi-agent-coordinator.md
    task-distributor.md
    workflow-orchestrator.md
    ...
  10-research-analysis/
    competitive-analyst.md
    market-researcher.md
    research-analyst.md
    trend-analyst.md
    ...
  templates/
    opus-4-5-template.md
commands/
  cr.md
  cr-fx.md
  deep-research.md
  explore.md
  git/
    cm.md
    cp.md
    ff.md
    fr.md
    pr.md
    prune.md
    sync.md
docs/
  architecture/
    active/
    completed/
  spec/
    completed/
  opus-4-5-migration.md
```

（[GitHub API](https://github.com/zircote/.claude) で取得したツリーから構成）

## CLAUDE.md の構成

（[CLAUDE.md 本文](https://github.com/zircote/.claude/blob/main/CLAUDE.md)）

### includes パターン

環境ごとに別ファイルを `~/.claude/includes/` に配置し、CLAUDE.md のテーブルで参照先を指示:

| Environment | Include File |
|-------------|--------------|
| Python | `~/.claude/includes/python.md` |
| React/TypeScript | `~/.claude/includes/react.md` |
| Go | `~/.claude/includes/golang.md` |
| Git/Version Control | `~/.claude/includes/git.md` |
| Testing (any language) | `~/.claude/includes/testing.md` |
| Documentation | `~/.claude/includes/documentation.md` |
| MCP Tools/Skills/Agents | `~/.claude/includes/mcp-reference.md` |
| GitHub Actions | `~/.claude/includes/github-actions.md` |
| Opus 4.5 (General) | `~/.claude/includes/opus-4-5.md` |
| Opus 4.5 (Agentic) | `~/.claude/includes/opus-4-5-agent.md` |

「環境固有タスクの開始時に該当 include ファイルを読め」という指示。

### カスタムコマンド

- `/git:cm`, `/git:cp`, `/git:pr` 等の Git ワークフロー
- `/cs:p`, `/cs:i`, `/cs:s` 等のアーキテクチャ計画（claude-spec プラグイン）

## 独自パターン

- **番号付きカテゴリ分類**: `01-core-development/`, `02-language-specialists/` 等、エージェントを 10 カテゴリに分類。100 以上のエージェントを整理
- **includes パターン**: CLAUDE.md を肥大化させず、環境ごとのガイドラインを外部ファイルに分離。Claude にタスク開始時に動的に読ませる
- **Opus 4.5 最適化**: Opus 4.5 専用の includes ファイルとエージェントテンプレートを用意
- **Architecture Decision Records**: `docs/architecture/` に active/completed で ADR を管理
- **Meta-orchestration カテゴリ**: agent-organizer, context-manager 等、エージェント自体を管理するメタエージェントを定義
