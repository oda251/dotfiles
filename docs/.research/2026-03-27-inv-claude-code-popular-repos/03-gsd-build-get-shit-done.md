---
tags:
  - investigation
  - claude-code
  - skills
  - gsd
  - meta-prompting
  - context-engineering
  - spec-driven
---
# gsd-build/get-shit-done（メタプロンプティング & スペック駆動開発）

- URL: https://github.com/gsd-build/get-shit-done
- Stars: 約 43,200
- 作者: TACHES
- ライセンス: MIT
- npm: `get-shit-done-cc`

## ディレクトリ構成

```
agents/
  gsd-advisor-researcher.md
  gsd-assumptions-analyzer.md
  gsd-codebase-mapper.md
  gsd-debugger.md
  gsd-executor.md
  gsd-integration-checker.md
  gsd-nyquist-auditor.md
  gsd-phase-researcher.md
  gsd-plan-checker.md
  gsd-planner.md
  gsd-project-researcher.md
  gsd-research-synthesizer.md
  gsd-roadmapper.md
  gsd-ui-auditor.md
  gsd-ui-checker.md
  gsd-ui-researcher.md
  gsd-user-profiler.md
  gsd-verifier.md
commands/
  gsd/
    new-project.md
    new-milestone.md
    execute-phase.md
    plan-phase.md
    research-phase.md
    discuss-phase.md
    validate-phase.md
    verify-work.md
    debug.md
    autonomous.md
    fast.md
    quick.md
    do.md
    ship.md
    review.md
    progress.md
    health.md
    ...（約 40 コマンド）
get-shit-done/
  bin/
    gsd-tools.cjs          # CLI ツール（state, config, phase, roadmap, verify, templates）
    lib/
      commands.cjs
      config.cjs
      core.cjs
      phase.cjs
      state.cjs
      ...
  references/
    checkpoints.md
    continuation-format.md
    decimal-phase-calculation.md
    git-integration.md
    git-planning-commit.md
    model-profile-resolution.md
    model-profiles.md
    phase-argument-parsing.md
    planning-config.md
    questioning.md
    tdd.md
    ui-brand.md
    user-profiling.md
    verification-patterns.md
    workstream-flag.md
  templates/
    DEBUG.md
    UAT.md
    UI-SPEC.md
    VALIDATION.md
    claude-md.md
    config.json
    context.md
    continue-here.md
    dev-preferences.md
    discovery.md
    user-profile.md
    ...
    codebase/
      architecture.md
      concerns.md
      conventions.md
      integrations.md
      stack.md
      structure.md
      testing.md
  workflows/
    new-project.md
    execute-phase.md
    plan-phase.md
    research-phase.md
    discuss-phase.md
    verify-phase.md
    autonomous.md
    fast.md
    quick.md
    do.md
    ship.md
    ...（約 40 ワークフロー）
sdk/
  prompts/
    agents/           # エージェントプロンプト（SDK 用）
    templates/        # プロジェクトテンプレート
    workflows/        # ワークフロープロンプト（SDK 用）
  src/                # TypeScript 実装
docs/
  AGENTS.md
  ARCHITECTURE.md
  CLI-TOOLS.md
  COMMANDS.md
  CONFIGURATION.md
  FEATURES.md
  USER-GUIDE.md
tests/
  ...（約 40 テストファイル）
```

（[GitHub API](https://github.com/gsd-build/get-shit-done) で取得したツリーから構成）

## アーキテクチャ

3 層構造（[ARCHITECTURE.md 本文](https://github.com/gsd-build/get-shit-done/blob/main/docs/ARCHITECTURE.md)）:

```
COMMAND LAYER（commands/gsd/*.md）
    ↓
WORKFLOW LAYER（get-shit-done/workflows/*.md）
  読み込み: references/, templates/
  生成: サブエージェント
    ↓
AGENT LAYER（各エージェントがフレッシュなコンテキストで実行）
    ↓
CLI TOOLS LAYER（gsd-tools.cjs）
    ↓
FILE SYSTEM（.planning/）
```

## 設計原則

（[ARCHITECTURE.md 本文](https://github.com/gsd-build/get-shit-done/blob/main/docs/ARCHITECTURE.md)）

1. **Fresh Context Per Agent**: サブエージェントはクリーンなコンテキストウィンドウ（最大 200K トークン）で起動。コンテキスト腐敗を排除
2. **Thin Orchestrators**: ワークフローは重い処理をせず、コンテキスト読み込み → エージェント生成 → 結果ルーティング → ステート更新のみ
3. **File-Based State**: `.planning/` に Markdown + JSON で状態管理。DB 不要、git コミット可能
4. **Absent = Enabled**: 機能フラグは未設定 = 有効。ユーザーが明示的に無効化
5. **Defense in Depth**: 計画検証 → 実行（atomic commit） → 事後検証

## ガイドライン / references の内容

### questioning.md

プロジェクト初期化時の質問方法論（[questioning.md 本文](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/questioning.md)）:

- 「要件定義ではなく夢の抽出」という哲学
- 「インタビュアーではなく思考パートナー」
- Start open → Follow energy → Challenge vagueness → Make the abstract concrete → Know when to stop
- 質問タイプ: Motivation, Scope, Users, Technical, Success criteria

### tdd.md

TDD の適用判断とプラン構造（[tdd.md 本文](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/tdd.md)）:

- **ヒューリスティック**: `expect(fn(input)).toBe(output)` をテスト前に書けるか？ → Yes: TDD, No: 標準プラン
- TDD 候補: ビジネスロジック、API、データ変換、バリデーション、アルゴリズム
- Skip TDD: UI レイアウト、設定変更、CRUD

### verification-patterns.md

成果物検証の 4 レベル（[verification-patterns.md 本文](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/verification-patterns.md)）:

1. **Exists**: ファイルが存在する
2. **Substantive**: プレースホルダーではなく実装がある
3. **Wired**: システムの残りと接続されている
4. **Functional**: 実際に動作する

- スタブ検出パターン（TODO/FIXME/placeholder の grep）を具体的に列挙

### その他 references

- `checkpoints.md`: チェックポイントの定義（未詳細調査）
- `git-integration.md`: Git 統合パターン（未詳細調査）
- `model-profiles.md`: モデルプロファイル設定（未詳細調査）
- `ui-brand.md`: UI ブランドガイドライン（未詳細調査）
- `user-profiling.md`: ユーザープロファイリング（未詳細調査）

## スキル間の連携パターン

（[ARCHITECTURE.md](https://github.com/gsd-build/get-shit-done/blob/main/docs/ARCHITECTURE.md) および [README](https://github.com/gsd-build/get-shit-done) から）

```
/gsd:new-project → discovery（質問） → research → plan → execute → verify
```

- コマンド → ワークフロー → エージェント の 3 層分離
- ワークフローが `gsd-tools.cjs init <workflow>` で必要なコンテキストをロード
- 各フェーズ間の状態は `.planning/STATE.md` で受け渡し

## 独自パターン

- **マルチランタイム対応**: Claude Code, OpenCode, Gemini CLI, Codex, Copilot, Cursor, Windsurf, Antigravity の 8 ランタイムに対応（[README](https://github.com/gsd-build/get-shit-done)）
- **npx インストーラー**: `npx get-shit-done-cc@latest` で対話的にランタイム選択・インストール
- **CLI ツール層**: `gsd-tools.cjs` が状態管理・テンプレート展開・検証を JavaScript で実行。プロンプトだけでなくプログラマティックな処理を併用
- **codebase/ テンプレート群**: architecture, conventions, stack, testing 等のプロジェクト構造テンプレートを templates/codebase/ に集約
- **SDK 同梱**: `sdk/` に TypeScript 実装を含み、プログラマティックな利用も可能
- **テスト充実**: 約 40 の `.test.cjs` ファイルでコマンド・設定・セキュリティ等を検証
