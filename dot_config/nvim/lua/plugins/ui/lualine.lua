return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "catppuccin",
      component_separators = "|",
      section_separators = "",
    },
  },
}
