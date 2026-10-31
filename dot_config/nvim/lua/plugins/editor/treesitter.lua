return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({ "typescript", "tsx", "cpp" })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "typescript", "typescriptreact", "cpp" },
      callback = function(args)
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].syntax = ""
        end
      end,
    })
  end,
}
