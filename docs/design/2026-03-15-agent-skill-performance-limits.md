# スキル・エージェント定義のサイズとパフォーマンス影響

## 推奨サイズ上限

| 対象 | 推奨上限 | 根拠 |
|------|---------|------|
| CLAUDE.md | **200行以下** | 公式ドキュメント。超えると遵守率低下 |
| SKILL.md | **500行以下** | 公式ドキュメント。詳細は別ファイルに分離 |
| スキルdescription | **130文字以下**（50+スキル時） | コミュニティ検証 |
| description合計バジェット | コンテキストの2%（fallback 16,000文字） | 公式ドキュメント |

## 遵守率の劣化

- LLMが確実に従える指示数は**150〜200個**程度（SFEIR Institute分析）
- Claude Codeの組み込みシステムプロンプトで既に約50個消費 → 残り**100〜150個**
- 劣化は崖型ではなく**緩やかに進行**する
- 「Lost in the Middle」現象：コンテキスト中央の情報は**20%以上**精度低下する場合がある

## スキル数の実測値

63スキルをインストールした場合：
- **42スキルのみ表示**（67%）、21スキルは完全に非表示
- descriptionの平均文字数別の収容数：
  - 263文字 → 約42スキル
  - 130文字 → 約67スキル
  - 100文字 → 約75スキル
- 各スキルに約109文字の固定オーバーヘッド（XMLタグ、名前、パス）

## サブエージェントのトークンコスト

| 項目 | トークン数 |
|------|-----------|
| 未最適化時の1ターン | 約**50,000トークン** |
| コンテキスト初期化（役割・ツール・CLAUDE.md等） | 5,000〜15,000トークン |
| 最適化後（必要なツール・スキルのみ） | 約**5,000トークン** |
| Claude Codeシステムプロンプト | 約23,000トークン |
| エージェントチーム（planモード） | 通常の約**7倍** |

## 軽減策

1. **`disable-model-invocation: true`** — descriptionをバジェットから除外（コンテキストコストゼロ）
2. **`tools`で制限** — 必要なツールのみ指定し、MCP等の不要なツール定義をロードしない
3. **`model: haiku`** — 単純タスクには軽量モデルを指定
4. **スキルの3層ロード** — description（初期）→ SKILL.md本文（呼び出し時）→ 参照ファイル（Read時）
5. **`/context`で監視** — 除外されたスキルや大きなメモリファイルの警告を確認
6. **`SLASH_COMMAND_TOOL_CHAR_BUDGET`** — 環境変数でバジェットを上書き可能

## LLM一般のプロンプト長に関する知見

- **重要な情報はプロンプトの先頭か末尾に置く**（中央は精度低下）
- クエリは末尾に置くと最大**30%品質向上**
- 長文ドキュメントはプロンプトの先頭に配置する
- 関連箇所を引用させてから推論させると精度向上

## 参考資料

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Claude Code Memory Documentation](https://code.claude.com/docs/en/memory)
- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/long-context-tips)
- [Skill Budget Research (Pelykh)](https://gist.github.com/alexey-pelykh/faa3c304f731d6a962efc5fa2a43abe1)
- [Lost in the Middle (Liu et al., 2024)](https://arxiv.org/abs/2307.03172)
- [SFEIR Institute: CLAUDE.md Optimization](https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/optimization/)
