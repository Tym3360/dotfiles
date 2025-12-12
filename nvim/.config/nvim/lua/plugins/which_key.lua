return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    delay = 0,
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = true,
        suggestions = 20,
      },
      presets = {
        operators = true,
        motions = true,
        text_objects = true,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
    },
    show_help = true,
    show_keys = true,
    layout = {
      spacing = 6,
      align = "left",
    },
    sort = { "local", "order", "group", "alphanum", "mod" },
    expand = 0,
    filter = function(_)
      return true
    end,
    replace = {
      ["<Space>"] = "SPC",
      ["<leader>"] = "SPC",
      ["<LocalLeader>"] = "SPC",
      ["<Tab>"] = "TAB",
      ["<CR>"] = "RET",
      ["<Esc>"] = "ESC",
      ["<C-"] = "C-",
      ["<M-"] = "M-",
      ["<D-"] = "D-",
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
