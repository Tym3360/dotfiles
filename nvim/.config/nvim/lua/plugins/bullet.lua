return {
  "dkarter/bullets.vim",
  ft = { "markdown", "text", "gitcommit" },
  config = function()
    -- Enable for markdown and text files
    vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit" }

    -- Customize bullet types
    vim.g.bullets_outline_levels = { "ROM", "ABC", "num", "abc", "rom", "std-" }

    -- Enable auto-wrapping
    vim.g.bullets_set_mappings = 1

    -- Renumber on insert/delete
    vim.g.bullets_renumber_on_change = 1

    -- Custom key mappings
    vim.g.bullets_custom_mappings = {
      {"imap", "<cr>", "<Plug>(bullets-newline)"},
      {"nmap", "o", "<Plug>(bullets-newline)"},
      {"vmap", "gN", "<Plug>(bullets-renumber)"},
      {"nmap", "gN", "<Plug>(bullets-renumber)"},
      {"imap", "<C-t>", "<Plug>(bullets-demote)"},
      {"nmap", ">>", "<Plug>(bullets-demote)"},
      {"imap", "<C-d>", "<Plug>(bullets-promote)"},
      {"nmap", "<<", "<Plug>(bullets-promote)"},
      {"nmap", "<leader>x", "<Plug>(bullets-toggle-checkbox)"},
    }
  end,
}
