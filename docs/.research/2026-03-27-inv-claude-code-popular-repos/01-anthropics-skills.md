---
tags:
  - investigation
  - claude-code
  - skills
  - anthropic
  - official
---
# anthropics/skills（公式スキルリポジトリ）

- URL: https://github.com/anthropics/skills
- Stars: 約 104,000
- ライセンス: Apache 2.0（一部スキルは source-available）

## ディレクトリ構成

```
skills/
  algorithmic-art/
    SKILL.md
    templates/
  brand-guidelines/
    SKILL.md
  canvas-design/
    SKILL.md
    canvas-fonts/
  claude-api/
    SKILL.md
    python/
    typescript/
    java/
    go/
    ruby/
    csharp/
    php/
    curl/
  doc-coauthoring/
  docx/
  frontend-design/
  internal-comms/
  mcp-builder/
  pdf/
  pptx/
  skill-creator/
  slack-gif-creator/
  theme-factory/
  web-artifacts-builder/
  webapp-testing/
  xlsx/
spec/          # Agent Skills 仕様
template/      # スキルテンプレート
.claude-plugin/
  marketplace.json
```

（[リポジトリ README](https://github.com/anthropics/skills) および GitHub API から取得した構造）

## スキルの構造パターン

各スキルは `skills/<name>/SKILL.md` に YAML frontmatter + Markdown 本文で定義される（[README](https://github.com/anthropics/skills)）。

```markdown
---
name: my-skill-name
description: A clear description of what this skill does and when to use it
---

# My Skill Name

[Instructions, examples, guidelines]
```

frontmatter の必須フィールドは `name` と `description` のみ（[README](https://github.com/anthropics/skills)）。

## ガイドライン / references の内容

### claude-api スキルの例

`claude-api/SKILL.md` は以下を含む（[SKILL.md 本文](https://github.com/anthropics/skills/blob/main/skills/claude-api/SKILL.md)）:

- **Defaults セクション**: モデルバージョン（claude-opus-4-6）、adaptive thinking のデフォルト、streaming 推奨
- **Language Detection**: プロジェクトファイルから言語を推論し、対応するサブディレクトリのドキュメントを読む
- **Language-Specific Feature Support テーブル**: 言語ごとの Tool Runner / Agent SDK サポート状況
- **曖昧な場合のフォールバック**: AskUserQuestion で選択肢を提示

### ドキュメントスキル（docx, pdf, pptx, xlsx）

Claude のドキュメント作成機能を裏で支えている production スキル。source-available として公開されている（[README](https://github.com/anthropics/skills)）。

## スキル間の連携パターン

公式リポジトリ自体にはスキル間連携の仕組みは見られない。各スキルは独立・自己完結型で、Claude が文脈に応じて動的にロードする設計（[README](https://github.com/anthropics/skills)）。

## 独自パターン

- **Plugin Marketplace 対応**: `.claude-plugin/marketplace.json` を通じて Claude Code の `/plugin` コマンドからインストール可能（[README](https://github.com/anthropics/skills)）
- **Agent Skills 仕様**: `spec/` ディレクトリに [agentskills.io](http://agentskills.io) のオープン仕様を同梱
- **テンプレート**: `template/` にスキル作成の雛形
- **リソースバンドル**: canvas-design スキルはフォントファイル群を同梱し、Claude がオフラインで利用可能
