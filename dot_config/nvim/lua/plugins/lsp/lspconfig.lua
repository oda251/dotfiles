return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "LspInfo", "LspInstall", "LspStart", "LspStop", "Mason", "MasonInstall", "MasonUpdate" },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "mason-org/mason-lspconfig.nvim",
    "saghen/blink.cmp",
  },
  config = function()
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })

    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "vtsls", "tailwindcss", "clangd", "rust_analyzer", "pyright" },
    })

    -- oxlint LSP (mise管理、mason外)
    if vim.fn.executable("oxlint") == 1 then
      vim.lsp.enable("oxlint")
    end
  end,
}
