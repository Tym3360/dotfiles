-- LazyVim-style buffer tabs: icons, LSP diagnostics counts, close-on-hover.
-- Palette comes out of the box matching tokyonight's bufferline highlights.
return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      -- show the bar only when more than one buffer is open (LazyVim style)
      always_show_bufferline = false,
      diagnostics = "nvim_lsp",
      diagnostics_indicator = function(_, level, diagnostics_dict, context)
        if not context.buffer:current() then
          return ""
        end
        local icon = level:match("error") and " " or " "
        local s = " "
        for e, n in pairs(diagnostics_dict) do
          local sym = e:match("error") and " " or (e:match("warning") and " " or " ")
          s = s .. sym .. n
        end
        return icon .. s
      end,
      indicator = { style = "underline" },
      separator_style = "thin",
      modified_icon = "●",
      left_trunc_marker = "",
      right_trunc_marker = "",
      hover = {
        enabled = true,
        reveal = { "close" },
      },
    },
  },
  keys = {
    -- <S-h>/<S-l> cycle (LazyVim muscle memory)
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    -- <leader><tab> group (free in your config; <leader>bd/bd stays with snacks)
    { "<leader><tab>l", "<cmd>BufferLineCycleLast<cr>", desc = "Last Buffer" },
    { "<leader><tab>p", "<cmd>BufferLinePin<cr>", desc = "Pin Buffer" },
    { "<leader><tab>d", "<cmd>BufferLinePickClose<cr>", desc = "Pick to Delete" },
    { "<leader><tab>f", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
  },
}
