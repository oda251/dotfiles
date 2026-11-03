-- Autocmds / 自動コマンド

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

vim.opt.viewoptions:append("folds")

augroup("PersistViews", { clear = true })
autocmd("BufWinLeave", {
  group = "PersistViews",
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].buftype == "" and vim.api.nvim_buf_get_name(args.buf) ~= "" then
      vim.cmd("silent! mkview")
    end
  end,
})
autocmd("BufWinEnter", {
  group = "PersistViews",
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].buftype == "" and vim.api.nvim_buf_get_name(args.buf) ~= "" then
      vim.cmd("silent! loadview")
    end
  end,
})

augroup("CopilotBlinkMenu", { clear = true })
autocmd("User", {
  group = "CopilotBlinkMenu",
  pattern = "BlinkCmpMenuOpen",
  callback = function()
    vim.b.copilot_suggestion_hidden = true
  end,
})
autocmd("User", {
  group = "CopilotBlinkMenu",
  pattern = "BlinkCmpMenuClose",
  callback = function()
    vim.b.copilot_suggestion_hidden = false
  end,
})

-- ファイルが外部で変更されたら自動でリロード
augroup("AutoReload", { clear = true })
autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  group = "AutoReload",
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
})

-- ヤンク時にハイライト
augroup("HighlightYank", { clear = true })
autocmd("TextYankPost", {
  group = "HighlightYank",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ファイルタイプ別設定
augroup("FileTypeSettings", { clear = true })
autocmd("FileType", {
  group = "FileTypeSettings",
  pattern = { "lua" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

-- 最後のカーソル位置を復元
autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
