return {
  "numToStr/Comment.nvim",
  keys = {
    { "gc", mode = { "n", "v" } },
    { "gb", mode = { "n", "v" } },
    { "<C-_>", "<Plug>(comment_toggle_linewise_current)", mode = "n", desc = "Toggle line comment" },
    { "<C-_>", "<Plug>(comment_toggle_linewise_visual)", mode = "v", desc = "Toggle selection comment" },
  },
  opts = {},
}
