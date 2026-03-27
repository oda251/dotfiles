---
tags:
  - investigation
  - claude-code
  - skills
  - references
  - guidelines
  - ecosystem
---
# Claude Code Skills / References / Guidelines 構成の人気リポジトリ調査

## 調査リポジトリ一覧

| # | リポジトリ | Stars | 特徴 | ファイル |
|---|-----------|-------|------|---------|
| 1 | [anthropics/skills](https://github.com/anthropics/skills) | ~104K | 公式スキルリポジトリ。SKILL.md パターンの正規定義 | [01](./01-anthropics-skills.md) |
| 2 | [obra/superpowers](https://github.com/obra/superpowers) | ~118K | スキルフレームワーク & TDD/デバッグ方法論 | [02](./02-obra-superpowers.md) |
| 3 | [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) | ~43K | メタプロンプティング & スペック駆動開発 | [03](./03-gsd-build-get-shit-done.md) |
| 4 | [zircote/.claude](https://github.com/zircote/.claude) | 16 | Claude Code dotfiles（agents/includes パターン） | [04](./04-zircote-dotclaude.md) |
| 5 | [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | ~33K | エコシステムカタログ | [05](./05-hesreallyhim-awesome-claude-code.md) |
| 6 | [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) | （未確認） | 設定パターンのリファレンス実装 | [06](./06-shanraisshan-claude-code-best-practice.md) |
| 7 | 公式 & ガイド記事 | - | 公式ベストプラクティス + HumanLayer ブログ | [07](./07-official-best-practices-and-guides.md) |

## ディレクトリ構成パターンの比較

### 公式（anthropics/skills）

```
skills/<name>/SKILL.md     # スキル定義（YAML frontmatter + Markdown）
skills/<name>/templates/   # テンプレート・リソース
spec/                      # Agent Skills 仕様
template/                  # スキル作成テンプレート
```

（[01](./01-anthropics-skills.md)）

### Superpowers（obra/superpowers）

```
skills/<name>/SKILL.md          # スキル定義
skills/<name>/references/       # 参照ドキュメント
skills/<name>/<prompt>.md       # サブエージェントプロンプト
agents/<name>.md                # エージェント定義
commands/<name>.md              # スラッシュコマンド
hooks/                          # フック設定
docs/superpowers/specs/         # 設計書（日付付き）
docs/superpowers/plans/         # 実装計画書（日付付き）
tests/                          # スキル発動テスト
```

（[02](./02-obra-superpowers.md)）

### GSD（gsd-build/get-shit-done）

```
agents/<name>.md                # エージェント定義
commands/gsd/<name>.md          # コマンド定義
get-shit-done/
  references/<name>.md          # ガイドライン・参照
  templates/<name>.md           # テンプレート群
  templates/codebase/           # コードベーステンプレート
  workflows/<name>.md           # ワークフロー定義
  bin/gsd-tools.cjs             # CLI ツール
sdk/                            # TypeScript SDK
```

（[03](./03-gsd-build-get-shit-done.md)）

### dotfiles パターン（zircote/.claude）

```
CLAUDE.md                       # エントリポイント（includes テーブル）
agents/
  01-core-development/          # 番号付きカテゴリ分類
  02-language-specialists/
  ...
commands/
  git/<name>.md                 # サブカテゴリ
includes/                       # 環境別ガイドライン（別リポ）
```

（[04](./04-zircote-dotclaude.md)）

## 主要パターンの横断比較

### スキル間連携

| リポジトリ | パターン |
|-----------|---------|
| anthropics/skills | 連携なし。各スキル独立 |
| superpowers | 明示的パイプライン: brainstorming → writing-plans → subagent-driven-development → code-review → finishing |
| GSD | 3 層分離: command → workflow → agent。状態は .planning/ で受け渡し |

### ガイドライン / references の使い方

| リポジトリ | パターン |
|-----------|---------|
| anthropics/skills | SKILL.md 内にインライン |
| superpowers | SKILL.md 内 + 同ディレクトリに補助 .md（testing-anti-patterns.md 等） |
| GSD | `references/` ディレクトリに分離（tdd.md, questioning.md, verification-patterns.md 等） |
| zircote | `includes/` に環境別ファイル分離 |

### コンテキスト管理戦略

| リポジトリ | 戦略 |
|-----------|------|
| superpowers | サブエージェントごとにフレッシュコンテキスト。2 段階レビュー（spec + quality） |
| GSD | 全エージェントにクリーンコンテキスト（最大 200K）。Thin Orchestrator パターン |
| 公式 | `/clear` 頻用、サブエージェントで調査分離、`/compact` でカスタム要約 |

## 採用検討に値するパターン

### 1. Iron Law パターン（superpowers）
スキルに「破ってはならない鉄則」を 1 行で定義。合理化を防ぐ Red Flags テーブルと組み合わせる。

### 2. References ディレクトリ分離（GSD）
ガイドラインをスキル本体から分離し、複数スキルから参照可能に。

### 3. Includes パターン（zircote）
CLAUDE.md を薄く保ち、環境別の詳細ガイドラインを外部ファイルに配置。タスク開始時に動的ロード。

### 4. Progressive Disclosure（HumanLayer）
ルート CLAUDE.md は最小限（60 行未満推奨）。詳細は `agent_docs/` 等に分散し、Claude が必要に応じて読む。

### 5. スキル発動テスト（superpowers）
`tests/skill-triggering/prompts/` にプロンプトファイルを用意し、スキルが正しく発動するか自動テスト。

### 6. Verification Patterns（GSD）
Exists → Substantive → Wired → Functional の 4 レベル検証。スタブ検出の具体的 grep パターン付き。

### 7. Command → Agent → Skill 3 層アーキテクチャ（shanraisshan）
コマンドがエントリポイント、エージェントがスキルをプリロードまたは invoke して実行。

### 8. docs/specs/ + docs/plans/ の日付管理（superpowers）
設計書と実装計画をタイムスタンプ付きで管理し、トレーサビリティを確保。
