return {
  "stevearc/conform.nvim",
  event = { "BufWritePre", "InsertEnter" },
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
      }, { upward = true, path = vim.api.nvim_buf_get_name(bufnr) })[1]
    end

    local function get_web_formatter(bufnr)
      if has_prettier_config(bufnr) then
        return { "prettier" }
      end
      return { "oxfmt" }
    end

    -- oxfmt は conform 組み込みの定義を使う。node_modules/.bin を優先解決し
    -- .oxfmtrc.json を cwd の基準にするため、プロジェクト固定版と揃う
    local format_on_insert_leave = {
      cpp = true,
      python = true,
      typescript = true,
      typescriptreact = true,
    }

    vim.api.nvim_create_autocmd("InsertLeave", {
      callback = function(args)
        if not format_on_insert_leave[vim.bo[args.buf].filetype] then
          return
        end
        require("conform").format({ bufnr = args.buf, async = false, lsp_fallback = true })
      end,
    })

    return {
      formatters_by_ft = {
        cpp = {},
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = get_web_formatter,
        typescript = get_web_formatter,
        javascriptreact = get_web_formatter,
        typescriptreact = get_web_formatter,
        css = get_web_formatter,
        html = get_web_formatter,
        json = get_web_formatter,
        vue = get_web_formatter,
        markdown = { "prettier" },
        ["*"] = { "codespell" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    }
  end,
}
