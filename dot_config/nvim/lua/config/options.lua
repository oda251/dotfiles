-- Options / 基本設定

-- Leader キー設定
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 見た目と操作性
vim.opt.number = true -- 行番号を表示
vim.opt.relativenumber = true -- カーソル位置からの相対行番号
vim.opt.cursorline = true -- 現在の行をハイライト
vim.opt.termguicolors = true -- 真の色（24-bit color）を有効化
vim.opt.laststatus = 3 -- ステータスラインを一本化

-- 編集補助
vim.opt.expandtab = true -- タブをスペースに変換
vim.opt.shiftwidth = 2 -- インデント幅
vim.opt.tabstop = 2 -- タブの幅
vim.opt.smartindent = true -- 賢い自動インデント

-- 検索
vim.opt.ignorecase = true -- 検索時に大文字小文字を区別しない
vim.opt.smartcase = true -- 大文字を含めて検索したら区別する

-- クリップボード
vim.opt.clipboard = "unnamedplus" -- システムのクリップボードと同期
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
elseif vim.fn.has("mac") == 1 then
  vim.g.clipboard = {
    name = "macOS",
    copy = {
      ["+"] = "pbcopy",
      ["*"] = "pbcopy",
    },
    paste = {
      ["+"] = "pbpaste",
      ["*"] = "pbpaste",
    },
    cache_enabled = 0,
  }
end

-- ファイル
vim.opt.autoread = true -- ファイルが外部で変更されたら自動で読み直す
