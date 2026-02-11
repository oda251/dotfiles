return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- カラースキームは最優先で読み込む
  opts = {
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    transparent_background = false,
    integrations = {
      treesitter = true,
      telescope = {
        enabled = true,
      },
      render_markdown = true,
      mini = {
        enabled = true,
      },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
