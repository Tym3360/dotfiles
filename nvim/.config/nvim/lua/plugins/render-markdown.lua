return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    -- Keep markdown rendering active in insert mode too.
    render_modes = { "n", "i", "c", "t" },

    -- Plugin responsibilities:
    -- obsidian.nvim: checkboxes, wiki links, tags, block IDs, highlights
    -- render-markdown.nvim: headings, code blocks, tables, bullets, quotes, callouts
    -- markdown.nvim: editing keymaps and utilities

    heading = {
      enabled = true,
      sign = true,
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    },

    code = {
      enabled = true,
      sign = true,
      style = "full",
      position = "left",
      width = "full",
      border = "thin",
      language_icon = true,
    },

    dash = {
      enabled = true,
      icon = "─",
      width = "full",
    },

    bullet = {
      enabled = true,
      icons = { "•", "◦", "▪", "▫" },
    },

    checkbox = {
      -- Render task checkboxes separately from list bullets to avoid dot-only tasks.
      enabled = true,
      bullet = false,
      unchecked = {
        icon = "☐ ",
      },
      checked = {
        icon = "✔ ",
      },
      custom = {
        in_progress = { raw = "[>]", rendered = "➜ ", highlight = "RenderMarkdownTodo" },
        cancelled = { raw = "[~]", rendered = "~ ", highlight = "RenderMarkdownError" },
        important = { raw = "[!]", rendered = "! ", highlight = "RenderMarkdownWarn" },
      },
    },

    quote = {
      enabled = true,
      icon = "▋",
    },

    pipe_table = {
      enabled = true,
      preset = "round",
      style = "full",
      cell = "padded",
    },

    callout = {
      -- Use default callouts (includes both GitHub and Obsidian callouts)
    },

    link = {
      -- Disable link rendering - obsidian.nvim handles wiki links
      enabled = false,
    },

    latex = {
      enabled = true,
      converter = "latex2text",
      highlight = "RenderMarkdownMath",
    },

    win_options = {
      conceallevel = {
        default = vim.api.nvim_get_option_value("conceallevel", {}),
        rendered = 2,
      },
      concealcursor = {
        default = vim.api.nvim_get_option_value("concealcursor", {}),
        rendered = "",
      },
    },
  },
}
