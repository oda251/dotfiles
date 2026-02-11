return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = function()
    local function has_prettier_config(bufnr)
      return vim.fs.find({
        ".prettierrc",
        ".prettierrc.json",
        ".prettierrc.yml",
        ".prettierrc.yaml",
        ".prettierrc.json5",
        ".prettierrc.js",
        ".prettierrc.cjs",
        "prettier.config.js",
        "prettier.config.cjs",
        "package.json",
      }, { upward = true, path = vim.api.nvim_buf_get_name(bufnr) })[1]
    end

    local function get_formatter(bufnr)
      if has_prettier_config(bufnr) then
        return { "prettier" }
      end
      return { "biome" }
    end

    return {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = get_formatter,
        typescript = get_formatter,
        javascriptreact = get_formatter,
        typescriptreact = get_formatter,
        css = get_formatter,
        html = get_formatter,
        json = get_formatter,
        markdown = { "prettier" },
        ["*"] = { "codespell" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    }
  end,
}
