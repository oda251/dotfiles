return {
  "zbirenbaum/copilot.lua",
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
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    })
  end,
}
