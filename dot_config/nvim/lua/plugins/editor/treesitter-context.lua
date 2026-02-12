return {
  "nvim-treesitter/nvim-treesitter-context",
  event = "BufReadPost",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    enable = true,
  },
}
