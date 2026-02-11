return {
  "stevearc/oil.nvim",
  opts = {
    default_file_explorer = true,
    columns = { "icon" },
    view_options = {
      show_hidden = true,
    },
  },
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
  },
}
