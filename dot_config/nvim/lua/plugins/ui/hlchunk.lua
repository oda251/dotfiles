return {
  "shellRaining/hlchunk.nvim",
  event = "BufReadPost",
  config = function()
    require("hlchunk").setup({})
  end,
}
