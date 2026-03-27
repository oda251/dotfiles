---
tags:
  - investigation
  - claude-code
  - best-practice
  - orchestration
  - skill-definition
---
# shanraisshan/claude-code-best-practice（リファレンス実装）

- URL: https://github.com/shanraisshan/claude-code-best-practice
- 説明: Practice made claude perfect. Claude Code 設定パターンのリファレンス実装

## CLAUDE.md の内容

（[CLAUDE.md 本文](https://github.com/shanraisshan/claude-code-best-practice/blob/main/CLAUDE.md)）

### Command → Agent → Skill アーキテクチャ

Weather System を例に 3 層アーキテクチャを実演:

1. `/weather-orchestrator` コマンド: エントリポイント。ユーザーに C/F を聞き、エージェント起動、SVG スキル起動
2. `weather-agent` エージェント: `weather-fetcher` スキルをプリロードして温度取得
3. `weather-fetcher` スキル: エージェントにプリロード（agent skill パターン）
4. `weather-svg-creator` スキル: Skill tool で invoke（skill パターン）

### 2 種類のスキルパターン

- **Agent Skills**: `skills:` フィールドでエージェントにプリロード
- **Skills**: `Skill` tool で動的に invoke

### Skill Definition Structure

`SKILL.md` の YAML frontmatter フィールド一覧:

| フィールド | 説明 |
|-----------|------|
| `name` | 表示名 & `/slash-command` |
| `description` | 自動発見用の発動条件 |
| `argument-hint` | オートコンプリートヒント |
| `disable-model-invocation` | `true` で自動発動を抑制 |
| `user-invocable` | `false` で `/` メニューから非表示（バックグラウンドスキル） |
| `allowed-tools` | スキル活性時に許可プロンプトなしで使えるツール |
| `model` | スキル活性時のモデル指定 |
| `context` | `fork` でサブエージェントコンテキストで実行 |
| `agent` | `context: fork` 時のサブエージェントタイプ |
| `hooks` | スキルスコープのライフサイクルフック |

### Subagent Definition Structure

`agents/*.md` の YAML frontmatter フィールド一覧:

| フィールド | 説明 |
|-----------|------|
| `name` | 識別子 |
| `description` | 発動条件（"PROACTIVELY" で自動発動） |
| `tools` | ツールの許可リスト |
| `disallowedTools` | ツールの拒否リスト |
| `model` | `haiku`, `sonnet`, `opus`, `inherit` |
| `permissionMode` | `acceptEdits`, `plan`, `bypassPermissions` |
| `maxTurns` | 最大ターン数 |
| `skills` | プリロードするスキル名リスト |
| `mcpServers` | MCP サーバー設定 |
| `hooks` | ライフサイクルフック |
| `memory` | `user`, `project`, `local` |
| `background` | `true` でバックグラウンドタスク |
| `effort` | `low`, `medium`, `high`, `max` |
| `isolation` | `worktree` で Git worktree 分離 |
| `color` | CLI 出力カラー |

### Configuration Hierarchy

1. **Managed**: Organization 強制（MDM plist / Registry）
2. Command line arguments
3. `.claude/settings.local.json`: 個人プロジェクト設定（git-ignored）
4. `.claude/settings.json`: チーム共有設定
5. `~/.claude/settings.json`: グローバル個人設定

### Hooks System

クロスプラットフォーム音声通知:
- `scripts/hooks.py`: メインハンドラー
- `config/hooks-config.json`: チーム共有設定
- `config/hooks-config.local.json`: 個人オーバーライド
- `sounds/`: ElevenLabs TTS で生成した音声ファイル
- 対応イベント: PreToolUse, PostToolUse, UserPromptSubmit, Notification, Stop, SubagentStart, SubagentStop, PreCompact, SessionStart, SessionEnd, Setup, PermissionRequest, TeammateIdle, TaskCompleted, ConfigChange

### サブエージェント制約

サブエージェントは bash 経由で他のサブエージェントを起動できない。Agent tool を使用する必要がある:
```
Agent(subagent_type="agent-name", description="...", prompt="...", model="haiku")
```

## 独自パターン

- **全 frontmatter フィールドの網羅的ドキュメント**: SKILL.md と agents/*.md の全パラメータをテーブル形式で整理。Claude Code の公式ドキュメントより詳細（[CLAUDE.md](https://github.com/shanraisshan/claude-code-best-practice/blob/main/CLAUDE.md)）
- **音声フック**: 各イベントに音声通知を紐付け（ElevenLabs TTS 生成）
- **Orchestration パターン実演**: Weather System で Command → Agent → Skill の 3 層パターンを具体的に実演
- **プレゼンテーション委譲**: `.claude/rules/presentation.md` でプレゼンテーション関連を `presentation-curator` エージェントに委譲
