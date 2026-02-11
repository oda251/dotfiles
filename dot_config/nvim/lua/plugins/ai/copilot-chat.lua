return {
  "CopilotC-Nvim/CopilotChat.nvim",
  dependencies = {
    { "zbirenbaum/copilot.lua" },
    { "nvim-lua/plenary.nvim" },
  },
  build = "make install", -- macOS/Linux
  opts = {
    debug = false,
  },
  keys = {
    { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat" },
  },
}
