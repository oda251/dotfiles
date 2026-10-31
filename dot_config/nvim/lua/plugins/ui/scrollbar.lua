return {
  "petertriho/nvim-scrollbar",
  branch = "v1",
  event = "BufReadPost",
  dependencies = {
    "kevinhwang91/nvim-hlslens",
  },
  opts = {
    show_in_active_only = true,
  },
  config = function(_, opts)
    local scrollbar = require("scrollbar")
    scrollbar.setup(opts)
    pcall(require("scrollbar.handlers.gitsigns").setup)
  end,
}
