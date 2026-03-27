# Claude Code Hooks Reference - 全イベント一覧

ソース: https://code.claude.com/docs/en/hooks

## 全24イベント

### 1. SessionStart
- **発火**: セッション開始・再開時
- **matcher**: `startup`, `resume`, `clear`, `compact`
- **固有入力**: `source`, `model`, `agent_type`
- **出力制御**: continue, stopReason, suppressOutput, systemMessage, additionalContext
- **用途**: 開発コンテキスト注入、環境変数セットアップ、compaction 後のコンテキスト再注入

### 2. InstructionsLoaded
- **発火**: CLAUDE.md / `.claude/rules/*.md` がコンテキストに読み込まれた時
- **matcher**: `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`
- **固有入力**: `file_path`, `memory_type`(User/Project/Local/Managed), `load_reason`, `globs`, `trigger_file_path`, `parent_file_path`
- **出力制御**: なし（監査ログ専用）
- **用途**: 監査ログ、コンプライアンス追跡

### 3. UserPromptSubmit
- **発火**: ユーザーがプロンプト送信時（Claude処理前）
- **matcher**: なし
- **固有入力**: `prompt`, `permission_mode`
- **出力制御**: decision("block"), reason, additionalContext, continue, stopReason
- **用途**: プロンプト検証、コンテキスト追加注入、特定プロンプトのブロック

### 4. PreToolUse
- **発火**: ツール実行前
- **matcher**: ツール名（`Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `WebFetch`, `WebSearch`, `mcp__.*`）
- **固有入力**: `tool_name`, `tool_input`（ツールごとに異なるスキーマ）, `tool_use_id`, `permission_mode`
- **出力制御**: permissionDecision("allow"/"deny"/"ask"), permissionDecisionReason, updatedInput
- **用途**: 破壊的コマンドのブロック、入力バリデーション、パラメータ変更

### 5. PermissionRequest
- **発火**: パーミッションダイアログ表示時
- **matcher**: ツール名（PreToolUseと同じ）
- **固有入力**: `tool_name`, `tool_input`, `permission_suggestions`
- **出力制御**: decision.behavior("allow"/"deny"), decision.updatedInput, decision.updatedPermissions, decision.message, decision.interrupt
- **updatedPermissions タイプ**: addRules, replaceRules, removeRules, setMode, addDirectories, removeDirectories
- **destination**: session, localSettings, projectSettings, userSettings
- **用途**: 安全な操作の自動承認、危険な操作の拒否、パーミッションルール適用
- **注意**: 非対話モード(`-p`)では発火しない

### 6. PostToolUse
- **発火**: ツール実行成功後
- **matcher**: ツール名
- **固有入力**: `tool_name`, `tool_input`, `tool_response`, `tool_use_id`, `permission_mode`
- **出力制御**: decision("block"), reason, additionalContext, updatedMCPToolOutput（MCPツール専用）
- **用途**: リント、ファイル書き込み後のバリデーション、ログ記録
- **注意**: 実行済みアクションは取り消し不可

### 7. PostToolUseFailure
- **発火**: ツール実行失敗後
- **matcher**: ツール名
- **固有入力**: `tool_name`, `tool_input`, `tool_use_id`, `error`, `is_interrupt`
- **出力制御**: additionalContext
- **用途**: エラーログ、リカバリコンテキスト提供

### 8. Notification
- **発火**: Claude Code が通知送信時
- **matcher**: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`
- **固有入力**: `message`, `title`, `notification_type`
- **出力制御**: additionalContext
- **用途**: デスクトップ通知転送、アラート、ログ記録

### 9. SubagentStart
- **発火**: サブエージェント起動時
- **matcher**: エージェントタイプ（`Bash`, `Explore`, `Plan`, カスタム）
- **固有入力**: `agent_id`, `agent_type`
- **出力制御**: additionalContext
- **用途**: コンテキスト注入、ログ、ガバナンス

### 10. SubagentStop
- **発火**: サブエージェント終了時
- **matcher**: エージェントタイプ
- **固有入力**: `agent_id`, `agent_type`, `agent_transcript_path`, `last_assistant_message`, `stop_hook_active`, `permission_mode`
- **出力制御**: decision("block"), reason
- **用途**: 品質ゲート、バリデーション、コンプライアンスチェック

### 11. Stop
- **発火**: Claude の応答完了時
- **matcher**: なし
- **固有入力**: `stop_hook_active`, `last_assistant_message`, `permission_mode`
- **出力制御**: decision("block"), reason
- **用途**: 条件付き継続強制、品質ゲート
- **注意**: ユーザー割り込み時は発火しない。APIエラー時は StopFailure が代わりに発火

### 12. StopFailure
- **発火**: APIエラーでターン終了時（Stopの代わり）
- **matcher**: エラータイプ（`rate_limit`, `authentication_failed`, `billing_error`, `invalid_request`, `server_error`, `max_output_tokens`, `unknown`）
- **固有入力**: `error`, `error_details`, `last_assistant_message`
- **出力制御**: なし（出力・終了コードは無視される）
- **用途**: エラーログ、アラート

### 13. TeammateIdle
- **発火**: Agent Team のチームメイトがアイドル状態になる直前
- **matcher**: なし
- **固有入力**: `teammate_name`, `team_name`, `permission_mode`
- **出力制御**: exit code 2 でフィードバック送信＆作業継続、continue: false で停止
- **用途**: 品質ゲート、リントチェック、成果物検証

### 14. TaskCompleted
- **発火**: タスクが完了としてマークされた時
- **matcher**: なし
- **固有入力**: `task_id`, `task_subject`, `task_description`, `teammate_name`, `team_name`, `permission_mode`
- **出力制御**: exit code 2 でフィードバック（タスク未完了扱い）、continue: false で停止
- **用途**: 完了基準の強制、テストバリデーション

### 15. ConfigChange
- **発火**: セッション中に設定ファイルが変更された時
- **matcher**: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`
- **固有入力**: `source`, `file_path`
- **出力制御**: decision("block"), reason
- **用途**: 監査ログ、セキュリティポリシー強制
- **注意**: policy_settings はブロック不可

### 16. CwdChanged
- **発火**: 作業ディレクトリ変更時（cd コマンド実行時など）
- **matcher**: なし
- **固有入力**: `old_cwd`, `new_cwd`
- **出力制御**: watchPaths（監視パス配列）
- **特殊機能**: `CLAUDE_ENV_FILE` で環境変数永続化可能
- **フックタイプ**: command のみ
- **用途**: プロジェクトツールチェーン切替、環境リロード、direnv 連携

### 17. FileChanged
- **発火**: 監視ファイルがディスク上で変更された時
- **matcher**: ファイル名（basename。例: `.envrc|.env`）
- **固有入力**: `file_path`, `event`("change"/"add"/"unlink")
- **出力制御**: watchPaths
- **特殊機能**: `CLAUDE_ENV_FILE` アクセス可能
- **フックタイプ**: command のみ
- **用途**: 環境変数リロード、動的パス監視

### 18. WorktreeCreate
- **発火**: `--worktree` またはサブエージェント分離でワーキングコピー作成時
- **matcher**: なし
- **固有入力**: `name`（worktree slug）
- **出力制御**: stdout にパスを出力（command hook）、または JSON で worktreePath を返却（HTTP hook）
- **用途**: SVN/Perforce/Mercurial 統合（git 以外の VCS 対応）

### 19. WorktreeRemove
- **発火**: セッション終了時またはサブエージェント完了時にワークツリー削除
- **matcher**: なし
- **固有入力**: `name`, `path`
- **出力制御**: なし（失敗はデバッグモードでのみログ出力）
- **用途**: クリーンアップ、VCS クリーンアップ

### 20. PreCompact
- **発火**: コンテキスト圧縮前
- **matcher**: `manual`, `auto`
- **固有入力**: なし（共通フィールドのみ）
- **出力制御**: なし
- **用途**: ログ、可観測性

### 21. PostCompact
- **発火**: コンテキスト圧縮完了後
- **matcher**: `manual`, `auto`
- **固有入力**: なし（共通フィールドのみ）
- **出力制御**: なし
- **用途**: ログ、可観測性

### 22. Elicitation
- **発火**: MCP サーバーがツールコール中にユーザー入力を要求した時
- **matcher**: MCP サーバー名
- **固有入力**: MCP サーバー名、elicitation 詳細
- **出力制御**: action("accept"/"decline"/"cancel"), content（フォーム入力値）
- **用途**: フォーム入力の自動補完、elicitation のブロック

### 23. ElicitationResult
- **発火**: MCP elicitation にユーザーが応答した後、サーバーに送信される前
- **matcher**: MCP サーバー名
- **固有入力**: ユーザーの応答詳細
- **出力制御**: action("accept"/"decline"/"cancel"), content（上書き値）
- **用途**: ユーザー応答の変更、入力バリデーション

### 24. SessionEnd
- **発火**: セッション終了時
- **matcher**: `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`
- **固有入力**: なし（共通フィールドのみ）
- **出力制御**: なし
- **用途**: クリーンアップ、ログ、最終レポート

## 共通入力フィールド（全イベント）
- `session_id` (string)
- `transcript_path` (string)
- `cwd` (string)
- `hook_event_name` (string)
- `agent_id` (string, optional - サブエージェント内)
- `agent_type` (string, optional - サブエージェント内)

## 汎用出力フィールド（全イベント）
- `continue` (boolean, default: true)
- `stopReason` (string, optional)
- `suppressOutput` (boolean, default: false)
- `systemMessage` (string, optional)

## フックタイプ
- `command`: シェルコマンド実行（デフォルト）
- `http`: HTTP エンドポイントに POST
- `prompt`: 単一ターン LLM 評価（Haiku デフォルト）
- `agent`: マルチターン検証（ツールアクセス付き）

## 終了コード
- **0**: アクション続行。stdout はコンテキストに追加（SessionStart, UserPromptSubmit）
- **2**: アクションブロック。stderr がフィードバックとして Claude に渡される
- **その他**: アクション続行。stderr はログのみ
