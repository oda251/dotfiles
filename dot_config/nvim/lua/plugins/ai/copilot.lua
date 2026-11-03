return {
  "zbirenbaum/copilot.lua",
  dependencies = { "copilotlsp-nvim/copilot-lsp" },
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      copilot_node_command = vim.fn.expand("~/.local/share/mise/installs/node/latest/bin/node"),
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 50,
      },
      nes = {
        enabled = false,
        auto_trigger = true,
        keymap = {
          accept_and_goto = "<leader>p",
          accept = false,
          dismiss = "<Esc>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    })
  end,
}
