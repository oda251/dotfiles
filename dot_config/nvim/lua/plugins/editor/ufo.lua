return {
  "kevinhwang91/nvim-ufo",
  ft = { "typescript", "typescriptreact", "cpp" },
  dependencies = { "kevinhwang91/promise-async" },
  opts = {
    provider_selector = function()
      return { "treesitter", "indent" }
    end,
  },
}
