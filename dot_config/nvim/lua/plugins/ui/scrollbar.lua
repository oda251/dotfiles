return {
  "petertriho/nvim-scrollbar",
  branch = "refactor/v2",
  event = "BufReadPost",
  dependencies = {
    "lewis6991/gitsigns.nvim",
  },
  opts = {
    providers = {
      gitsigns = true,
    },
    scrollbar = {
      visibility = "active",
    },
  },
}
