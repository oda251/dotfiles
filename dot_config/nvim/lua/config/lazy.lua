-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins.lsp" },
    { import = "plugins.ui" },
    { import = "plugins.ai" },
    { import = "plugins.editor" },
    { import = "plugins.completion" },
  },
  defaults = {
    lazy = true,
  },
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = false },
  change_detection = { enabled = false, notify = false },
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if #vim.api.nvim_list_uis() == 0 then
        return
      end

      if vim.fn.executable("flock") ~= 1 then
        vim.notify("Automatic plugin updates require the `flock` command", vim.log.levels.WARN)
        return
      end

      local state_dir = vim.fn.stdpath("state")
      vim.fn.mkdir(state_dir, "p")
      local stamp = state_dir .. "/lazy-auto-update"
      local function last_update_time()
        if vim.fn.filereadable(stamp) ~= 1 then
          return nil
        end
        return tonumber(vim.fn.readfile(stamp)[1] or "")
      end

      local last_update = last_update_time()
      if last_update and os.time() - last_update < 86400 then
        return
      end

      local lock = state_dir .. "/lazy-auto-update.lock"
      local acquired = false
      local job
      job = vim.fn.jobstart({
        "flock",
        "-n",
        lock,
        "sh",
        "-c",
        "printf 'locked\\n'; cat",
      }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if acquired or not data or data[1] ~= "locked" then
            return
          end
          acquired = true

          local current_update = last_update_time()
          if current_update and os.time() - current_update < 86400 then
            vim.fn.chanclose(job, "stdin")
            return
          end

          require("lazy").update({ show = false }):wait(function()
            vim.fn.writefile({ tostring(os.time()) }, stamp)
            vim.fn.chanclose(job, "stdin")
          end)
        end,
      })

      if job <= 0 then
        vim.notify("Failed to start automatic plugin update lock", vim.log.levels.ERROR)
      end
    end, 10000)
  end,
})
