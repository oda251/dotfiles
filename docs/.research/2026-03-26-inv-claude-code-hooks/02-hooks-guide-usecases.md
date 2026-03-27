# Claude Code Hooks Guide - ユースケース・設定例

ソース: https://code.claude.com/docs/en/hooks-guide

## 公式ドキュメント掲載のユースケース

### 1. デスクトップ通知（Notification）
- イベント: Notification
- 目的: Claude が入力待ちの時にデスクトップ通知を送る
- macOS: `osascript -e 'display notification ...'`
- Linux: `notify-send`
- Windows: PowerShell MessageBox

### 2. コード自動フォーマット（PostToolUse + Edit|Write）
- イベント: PostToolUse, matcher: "Edit|Write"
- 目的: ファイル編集後に Prettier を自動実行
- コマンド: `jq -r '.tool_input.file_path' | xargs npx prettier --write`

### 3. 保護ファイルの編集ブロック（PreToolUse + Edit|Write）
- イベント: PreToolUse, matcher: "Edit|Write"
- 目的: .env, package-lock.json, .git/ への編集を防止
- 方式: スクリプトファイル + exit 2 でブロック

### 4. compaction 後のコンテキスト再注入（SessionStart + compact）
- イベント: SessionStart, matcher: "compact"
- 目的: コンテキスト圧縮で失われる重要情報を再注入
- 例: `echo 'Reminder: use Bun, not npm.'`

### 5. 設定変更の監査ログ（ConfigChange）
- イベント: ConfigChange
- 目的: 設定ファイル変更の追跡・コンプライアンス
- コマンド: jq でタイムスタンプ・ソース・ファイルパスをログファイルに追記

### 6. ディレクトリ変更時の環境リロード（CwdChanged + FileChanged）
- イベント: CwdChanged / FileChanged (.envrc|.env)
- 目的: direnv 連携で環境変数を自動リロード
- コマンド: `direnv export bash >> "$CLAUDE_ENV_FILE"`

### 7. パーミッションプロンプトの自動承認（PermissionRequest）
- イベント: PermissionRequest, matcher: "ExitPlanMode"
- 目的: 特定操作（ExitPlanMode等）の承認ダイアログをスキップ
- 方式: JSON 出力で `decision.behavior: "allow"` を返す

### 8. Bash コマンドのログ記録（PostToolUse + Bash）
- イベント: PostToolUse, matcher: "Bash"
- コマンド: `jq -r '.tool_input.command' >> ~/.claude/command-log.txt`

### 9. MCP ツールの監視（PreToolUse + mcp__.*）
- イベント: PreToolUse, matcher: "mcp__github__.*"
- MCP ツール名形式: `mcp__<server>__<tool>`

### 10. セッション終了時のクリーンアップ（SessionEnd + clear）
- イベント: SessionEnd, matcher: "clear"
- 目的: /clear 実行時に一時ファイルを削除

### 11. タスク完了チェック（Stop + prompt）
- イベント: Stop, type: "prompt"
- 目的: LLM でタスク完了を判定し、未完了なら継続
- prompt hook: `ok: false` + reason で Claude に継続指示

### 12. テスト検証（Stop + agent）
- イベント: Stop, type: "agent"
- 目的: サブエージェントでテストスイートを実行して検証

## フック設定の配置場所

| 場所 | スコープ | 共有可能 |
|------|---------|---------|
| `~/.claude/settings.json` | 全プロジェクト | No |
| `.claude/settings.json` | 単一プロジェクト | Yes（コミット可） |
| `.claude/settings.local.json` | 単一プロジェクト | No（gitignore） |
| マネージドポリシー | 組織全体 | Yes（管理者制御） |
| プラグイン `hooks/hooks.json` | プラグイン有効時 | Yes |
| スキル/エージェント frontmatter | スキル/エージェント実行中 | Yes |

## ローカル設定の実例

ソース: dot_claude/settings.json（chezmoi ソースディレクトリ）

- SessionStart フック（matcher: "startup|clear|compact"）で `$HOME/.claude/hooks/session-start` を実行
- async: false（同期実行）
