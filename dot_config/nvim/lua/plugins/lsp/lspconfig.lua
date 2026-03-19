return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        once = true,
        callback = function()
          local caps = require("blink.cmp").get_lsp_capabilities()
          vim.lsp.config("*", { capabilities = caps })
        end,
      })
      local servers = { "lua_ls", "vtsls", "tailwindcss", "clangd", "rust_analyzer", "pyright" }
      for _, server in ipairs(servers) do
        vim.lsp.enable(server)
      end
      if vim.fn.executable("oxlint") == 1 then
        vim.lsp.enable("oxlint")
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    cmd = { "LspInstall" },
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = { "lua_ls", "vtsls", "tailwindcss", "clangd", "rust_analyzer", "pyright" },
    },
  },
}
