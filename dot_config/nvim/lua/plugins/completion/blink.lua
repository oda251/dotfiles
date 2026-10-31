local manual_selection = false

local function accept_and_replay(cmp, key)
  if not manual_selection or not cmp.get_selected_item() then
    return
  end

  local accepted = cmp.accept({
    callback = function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "i", false)
    end,
  })

  if accepted then
    manual_selection = false
    return true
  end
end

vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    local char = vim.v.char
    if not manual_selection or char == "" or char:find("%c") then
      return
    end

    local ok, cmp = pcall(require, "blink.cmp")
    if ok and accept_and_replay(cmp, char) then
      vim.v.char = ""
    end
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    manual_selection = false
  end,
})

local escape = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
vim.on_key(function(key)
  if key == escape then
    manual_selection = false
  end
end, vim.api.nvim_create_namespace("blink_completion_manual_selection"))

return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  -- optional: provides snippets for the snippet source
  dependencies = {
    "rafamadriz/friendly-snippets",
    "giuxtaposition/blink-cmp-copilot",
  },

  version = "*",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = {
      preset = "default",
      ["<C-l>"] = {
        function(cmp)
          manual_selection = false
          if cmp.get_selected_item() then
            return cmp.accept()
          elseif require("copilot.suggestion").is_visible() then
            require("copilot.suggestion").accept()
            return true
          end
        end,
        "fallback",
      },
      ["<M-l>"] = {
        function(cmp)
          manual_selection = false
          if cmp.get_selected_item() then
            return cmp.accept()
          elseif require("copilot.suggestion").is_visible() then
            require("copilot.suggestion").accept()
            return true
          end
        end,
        "fallback",
      },
      ["<Tab>"] = {
        function(cmp)
          if cmp.get_selected_item() then
            return cmp.select_next()
          end
        end,
        "fallback",
      },
      ["<S-Tab>"] = {
        function(cmp)
          local selected
          if cmp.is_menu_visible() then
            if cmp.get_selected_item() then
              selected = cmp.select_prev()
            else
              selected = cmp.select_next()
            end
          else
            selected = cmp.show({ initial_selected_item_idx = -1 })
          end

          manual_selection = selected ~= nil
          return selected
        end,
        "snippet_backward",
        "fallback",
      },
      ["<Up>"] = {
        function(cmp)
          if cmp.get_selected_item() then
            return cmp.select_prev()
          end
        end,
        "fallback",
      },
      ["<Down>"] = {
        function(cmp)
          if cmp.get_selected_item() then
            return cmp.select_next()
          end
        end,
        "fallback",
      },
      ["<BS>"] = {
        function(cmp)
          return accept_and_replay(cmp, "<BS>")
        end,
        "fallback",
      },
      ["<Del>"] = {
        function(cmp)
          return accept_and_replay(cmp, "<Del>")
        end,
        "fallback",
      },
      ["<C-w>"] = {
        function(cmp)
          return accept_and_replay(cmp, "<C-w>")
        end,
        "fallback",
      },
      ["<C-u>"] = {
        function(cmp)
          return accept_and_replay(cmp, "<C-u>")
        end,
        "fallback",
      },
      ["<CR>"] = {
        function(cmp)
          manual_selection = false
          if cmp.get_selected_item() then
            return cmp.accept()
          end
        end,
        "fallback",
      },
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    completion = {
      menu = { auto_show = true },
      ghost_text = { enabled = false },
      documentation = { auto_show = false },
      list = {
        cycle = { from_top = true, from_bottom = true },
        selection = { preselect = false, auto_insert = false },
      },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-cmp-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
