-- Noice: the "modern UI" layer — floating/captured cmdline, lsp progress,
-- message popups. notifications keep coming from snacks.notifier.
-- (bottom_search = true keeps your classic bottom search bar, not a takeover.)
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    lsp = {
      progress = { enabled = true, view = "mini" },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    notify = { enabled = false }, -- snacks.notifier owns toasts
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      inc_rename = false,
    },
  },
}
