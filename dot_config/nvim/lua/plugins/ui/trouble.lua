return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "Trouble", "TroubleToggle", "TroubleClose" },
  keys = {
    { "<leader>xx", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble" },
    { "<leader>xw", "<cmd>Trouble workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
    { "<leader>xl", "<cmd>Trouble loclist<cr>", desc = "Location List" },
    { "<leader>xq", "<cmd>Trouble quickfix<cr>", desc = "Quickfix" },
  },
  opts = {
    use_diagnostic_signs = true,
  },
}
