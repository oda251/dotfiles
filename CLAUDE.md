# chezmoi dotfiles

chezmoi で管理する dotfiles リポジトリ。

## ai-agent-configs/

AI コーディングツール（Claude Code, Codex, Cursor）の共通設定ソース。ここで一元管理し、`routes.txt` のルーティング定義に従って各ツールの設定ディレクトリ（`dot_claude/`, `dot_codex/`, `dot_cursor/`）に配布する。

### ディレクトリ構成

```
ai-agent-configs/
├── routes.txt       # 配布ルール定義（copy/sync/concat）
├── rules/           # 共通コーディングルール → 各ツールの CLAUDE.md 等に配布
├── agents/          # カスタムエージェント定義 → dot_claude/agents/ に配布
├── contexts/        # 任意のタイミングで注入するコンテキスト → dot_claude/contexts/ に配布
├── hooks/           # Hook スクリプト → dot_claude/hooks/ に配布
└── skills/          # スキル定義 → 各ツールの skills/ に配布
```

### routes.txt の書式

```
copy|<source>|<destination>           # ファイル単体コピー
sync|<source_dir>|<destination_dir>   # ディレクトリ同期
concat|<destination>|<src1>|<src2>    # 複数ファイル結合
```

### 変更時の注意
