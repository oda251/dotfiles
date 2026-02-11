-- Init / エントリーポイント

-- 設定ファイルの読み込み順序は重要
-- 1. options: leader キーなど基本設定（lazy より先に読む必要あり）
-- 2. lazy: プラグインマネージャー
-- 3. keymaps: キーマッピング
-- 4. autocmds: 自動コマンド

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
