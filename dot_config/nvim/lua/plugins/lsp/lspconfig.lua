return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "LspInfo", "LspInstall", "LspStart", "LspStop", "Mason", "MasonInstall", "MasonUpdate" },
  dependencies = {
    { "williamboman/mason.nvim", config = true },
    "williamboman/mason-lspconfig.nvim",
    "saghen/blink.cmp",
  },
  config = function()
    local capabilities = require("blink.cmp").get_lsp_capabilities()
    local lspconfig = require("lspconfig")

    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "vtsls", "tailwindcss", "clangd", "rust_analyzer", "pyright" },
      handlers = {
        function(server_name)
          lspconfig[server_name].setup({ capabilities = capabilities })
        end,
      },
    })
  end,
}
