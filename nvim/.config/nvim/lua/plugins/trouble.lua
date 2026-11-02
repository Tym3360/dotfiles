-- LazyVim-style diagnostics/symbols panel (trouble v3).
-- ⚠️ your existing <leader>sD (snacks buffer diagnostics) and <leader>sd/etc.
-- keep working; <leader>x* is the trouble panel family.
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = { use_diagnostic_signs = true },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    { "[x", function() require("trouble").previous({ skip_groups = true, jump = true }) end, desc = "Prev Trouble" },
    { "]x", function() require("trouble").next({ skip_groups = true, jump = true }) end, desc = "Next Trouble" },
    { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
  },
}
