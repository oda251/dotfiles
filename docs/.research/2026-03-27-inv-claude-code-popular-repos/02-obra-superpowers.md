---
tags:
  - investigation
  - claude-code
  - skills
  - superpowers
  - tdd
  - debugging
  - workflow
---
# obra/superpowers（スキルフレームワーク & 開発方法論）

- URL: https://github.com/obra/superpowers
- Stars: 約 117,600
- 作者: Jesse Vincent
- ライセンス: 記載あり（LICENSE）

## ディレクトリ構成

```
skills/
  brainstorming/
    SKILL.md
    visual-companion.md
    spec-document-reviewer-prompt.md
    scripts/           # ビジュアルブレスト用 HTML/JS サーバ
  dispatching-parallel-agents/
    SKILL.md
  executing-plans/
    SKILL.md
  finishing-a-development-branch/
    SKILL.md
  receiving-code-review/
    SKILL.md
  requesting-code-review/
    SKILL.md
  subagent-driven-development/
    SKILL.md
    implementer-prompt.md
    spec-reviewer-prompt.md
    code-quality-reviewer-prompt.md
  systematic-debugging/
    SKILL.md
    testing-anti-patterns.md
  test-driven-development/
    SKILL.md
    testing-anti-patterns.md
  using-git-worktrees/
    SKILL.md
  using-superpowers/
    SKILL.md
    references/
      codex-tools.md
      gemini-tools.md
  verification-before-completion/
    SKILL.md
  writing-plans/
    SKILL.md
    plan-document-reviewer-prompt.md
  writing-skills/
    SKILL.md
    anthropic-best-practices.md
    persuasion-principles.md
    examples/
    testing-skills-with-subagents.md
agents/
  code-reviewer.md
commands/
  brainstorm.md
  execute-plan.md
  write-plan.md
hooks/
  hooks.json
  hooks-cursor.json
  session-start/
docs/
  superpowers/
    plans/     # 日付付き計画書
    specs/     # 日付付き設計書
tests/
  claude-code/
  skill-triggering/
  explicit-skill-requests/
  subagent-driven-dev/
  brainstorm-server/
```

（[GitHub API](https://github.com/obra/superpowers) で取得したツリーから構成）

## スキルの詳細

### using-superpowers（メタスキル / エントリポイント）

会話開始時にロードされ、他スキルの発動ルールを統制する（[SKILL.md 本文](https://github.com/obra/superpowers/blob/main/skills/using-superpowers/SKILL.md)）。

- **1% ルール**: 「スキルが適用される可能性が 1% でもあれば、必ず Skill tool を invoke せよ」
- **優先順位**: ユーザー指示 > Superpowers スキル > デフォルトシステムプロンプト
- **Red Flags テーブル**: 「これは簡単な質問だから」等の合理化パターンを列挙し、それらが出たら STOP するよう指示
- **スキル優先度**: プロセススキル（brainstorming, debugging）→ 実装スキル の順
- **Rigid vs Flexible**: TDD/debugging は厳密遵守、パターン系は柔軟適用

### test-driven-development

Red-Green-Refactor サイクルの厳格な遵守を要求する（[SKILL.md 本文](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)）。

- **Iron Law**: `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`
- テスト前にコードを書いたら「削除して最初からやり直せ」
- Good/Bad の具体的コード例を含む
- `testing-anti-patterns.md` を参照ファイルとして同梱

### systematic-debugging

4 フェーズのデバッグ方法論（[SKILL.md 本文](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md)）:

1. **Root Cause Investigation**: エラーメッセージの精読、再現、仮説立て
2. **Fix Implementation**（未調査）
3. **Verification**（未調査）
4. **Documentation**（未調査）

- **Iron Law**: `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`
- 「時間がないとき」「簡単そうなとき」こそ使えと強調

### brainstorming

アイデアを設計に変換するための対話的プロセス（[SKILL.md 本文](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md)）。

- **HARD-GATE**: 設計提示 + ユーザー承認前の実装行為を禁止
- **Anti-Pattern**: 「これは単純すぎてデザイン不要」を明示的に否定
- チェックリスト 9 ステップ: コンテキスト調査 → ビジュアルコンパニオン提示 → 質問 → アプローチ提案 → 設計提示 → 設計書保存 → セルフレビュー → ユーザーレビュー → writing-plans 起動
- 設計書を `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` に保存

### writing-plans

設計書からタスク分解した実装計画を作成する（[SKILL.md 本文](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md)）。

- 「実装者はコードベースの知識ゼロ」と仮定してドキュメント化
- **Bite-Sized Task**: 1 ステップ 2-5 分（テスト書く / 失敗確認 / 実装 / 成功確認 / コミット）
- 保存先: `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

### subagent-driven-development

計画をサブエージェントに分配して実行するパターン（[SKILL.md 本文](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md)）。

- タスクごとにフレッシュなサブエージェントを生成（コンテキスト汚染防止）
- **2段階レビュー**: spec compliance reviewer → code quality reviewer
- 各サブエージェント用のプロンプトテンプレートを同梱（implementer-prompt.md, spec-reviewer-prompt.md, code-quality-reviewer-prompt.md）

## スキル間の連携パターン

明確なパイプラインが定義されている（[各 SKILL.md](https://github.com/obra/superpowers) から確認）:

```
brainstorming → writing-plans → subagent-driven-development（or executing-plans）
                                       ↓
                              requesting-code-review
                                       ↓
                              finishing-a-development-branch
```

- brainstorming の terminal state は writing-plans の invoke
- writing-plans の出力は subagent-driven-development の入力
- 各スキルが次のスキルを名指しで指定

## 独自パターン

- **Iron Law パターン**: 各スキルに破ってはならない鉄則を 1 行で定義し、繰り返し強調
- **Red Flags テーブル**: 「合理化」の典型パターンを列挙し「それは間違い」と即座に返す
- **Graphviz フロー図**: `.dot` 記法で判断フローを SKILL.md 内に埋め込み
- **Rigid vs Flexible 分類**: スキル自身がどの程度厳密に従うべきか自己宣言
- **マルチランタイム対応**: Codex, Gemini CLI, OpenCode 用のツールマッピングを references/ に同梱
- **スキル評価テスト**: `tests/skill-triggering/` にプロンプトファイルを用意し、スキルが正しく発動するかテスト可能
- **セッション開始フック**: `hooks/session-start/` でセッション開始時の初期化を自動化
