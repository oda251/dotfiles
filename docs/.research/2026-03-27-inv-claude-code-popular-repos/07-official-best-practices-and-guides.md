---
tags:
  - investigation
  - claude-code
  - best-practice
  - official
  - claude-md
---
# 公式ベストプラクティス & ガイド記事

## Anthropic 公式: Best Practices for Claude Code

- URL: https://code.claude.com/docs/en/best-practices

### CLAUDE.md のベストプラクティス

（[公式ベストプラクティス](https://code.claude.com/docs/en/best-practices)）

**含めるべきもの**:
- Claude が推測できない Bash コマンド
- デフォルトと異なるコードスタイルルール
- テスト手順とテストランナー
- リポジトリ作法（ブランチ命名、PR 規約）
- プロジェクト固有のアーキテクチャ決定
- 環境の癖（必須 env vars）
- 非自明な落とし穴

**除外すべきもの**:
- コードを読めば分かること
- Claude が既知の標準的な言語規約
- 詳細な API ドキュメント（リンクで代替）
- 頻繁に変わる情報
- ファイルごとのコードベース説明
- 自明な慣行（「clean code を書け」等）

**運用指針**:
- `/init` で初期生成 → 継続的に改善
- 各行に「これを消したら Claude が間違うか？」と問う
- 長すぎると指示が無視される
- `IMPORTANT` や `YOU MUST` で強調して遵守率向上
- git にコミットしてチーム全体で貢献
- `@path/to/import` で外部ファイルをインポート可能

**配置場所**:
- `~/.claude/CLAUDE.md`: 全セッションに適用
- `./CLAUDE.md`: プロジェクトルート（git 管理）
- 親ディレクトリ: モノレポ用
- 子ディレクトリ: Claude が作業時にオンデマンドでロード

### スキルの使い分け

CLAUDE.md は全セッションでロードされるため、広く適用される指示のみ含める。ドメイン知識や特定ワークフローは skills を使い、オンデマンドロードで会話を膨張させない（[公式](https://code.claude.com/docs/en/best-practices)）。

### 推奨ワークフロー: Explore → Plan → Implement → Commit

（[公式](https://code.claude.com/docs/en/best-practices)）

1. Plan Mode で探索（ファイル読み・質問、変更なし）
2. Plan Mode で計画（実装計画作成、Ctrl+G でエディタ編集）
3. Normal Mode で実装（計画に基づきコード、テスト実行）
4. コミット & PR 作成

### コンテキスト管理

（[公式](https://code.claude.com/docs/en/best-practices)）

- `/clear` をタスク間で頻繁に使用
- `/compact <instructions>` でカスタム要約
- `/btw` で会話履歴に残さないクイック質問
- サブエージェントで調査を分離（メインコンテキストを汚さない）

### 避けるべきパターン

（[公式](https://code.claude.com/docs/en/best-practices)）

- **Kitchen sink session**: 無関係なタスクを 1 セッションに詰め込む
- **過度の修正ループ**: 2 回失敗したら `/clear` してプロンプトを改善
- **肥大化 CLAUDE.md**: 重要なルールがノイズに埋もれる
- **検証なしの信頼**: テスト・スクリプト・スクリーンショットで検証
- **無限探索**: スコープを絞るかサブエージェントに委任

## HumanLayer: Writing a Good CLAUDE.md

- URL: https://www.humanlayer.dev/blog/writing-a-good-claude-md

### WHY-WHAT-HOW フレームワーク

（[HumanLayer ブログ](https://www.humanlayer.dev/blog/writing-a-good-claude-md)）

- **WHAT**: テクスタック、プロジェクト構造、コードベース組織
- **WHY**: プロジェクトの目的、各コンポーネントの機能
- **HOW**: ワークフロー、ツール要件、テスト手順、検証方法

### Progressive Disclosure パターン

（[HumanLayer ブログ](https://www.humanlayer.dev/blog/writing-a-good-claude-md)）

- ルート CLAUDE.md は 60 行未満に抑える
- `agent_docs/` に個別ファイルを配置（building_the_project.md, running_tests.md, code_conventions.md 等）
- コードスニペットではなくファイル参照を使う（古くなるのを防ぐ）
- Claude にどのドキュメントが関連するか判断させる

### アンチパターン

（[HumanLayer ブログ](https://www.humanlayer.dev/blog/writing-a-good-claude-md)）

- コードスタイルガイドラインを CLAUDE.md に入れるな（「LLM にリンターの仕事をさせるな」）
- 包括的なコマンドライブラリ
- セッションによっては無関係な長いコンテキスト
- `/init` の自動生成コンテンツをそのまま使う

**代替アプローチ**: リンター/フォーマッターを deterministic ツールとして設定し、Stop hook でフォーマッタを実行してエラーを Claude に提示する。
