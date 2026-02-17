-- Init / エントリーポイント

-- 起動高速化のため未使用の標準プラグインを早期に無効化
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1

-- 設定ファイルの読み込み順序は重要
-- 1. options: leader キーなど基本設定（lazy より先に読む必要あり）
-- 2. lazy: プラグインマネージャー
-- 3. keymaps: キーマッピング
-- 4. autocmds: 自動コマンド

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
