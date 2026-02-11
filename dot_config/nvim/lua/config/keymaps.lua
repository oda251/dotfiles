-- Keymaps / キーマッピング

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- より良いウィンドウ移動
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- バッファ操作
keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- 検索ハイライトをクリア
keymap("n", "<Esc>", ":nohlsearch<CR>", opts)

-- ビジュアルモードでインデント調整後も選択を維持
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- ビジュアルモードで行を上下に移動
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- ファイル保存
keymap("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- インサートモードでの通常のTab入力（Alt+Tab）
keymap("i", "<M-Tab>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n", true)
end, { desc = "Insert tab" })
