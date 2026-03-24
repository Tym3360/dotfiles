return {
  "tadmccorkle/markdown.nvim",
  ft = { "markdown" },
  opts = {
    -- Keymaps for toggling formatting
    mappings = {
      inline_surround_toggle = "gs",  -- Toggle inline formatting (e.g., gsb for bold)
      inline_surround_toggle_line = "gss", -- Toggle for whole line
      inline_surround_delete = "ds",  -- Delete surrounding formatting
      inline_surround_change = "cs",  -- Change surrounding formatting
      link_add = "gl",                -- Add link
      link_follow = "gx",             -- Follow link (open in browser)
      go_curr_heading = "]c",         -- Go to current heading
      go_parent_heading = "]p",       -- Go to parent heading
      go_next_heading = "]]",         -- Go to next heading
      go_prev_heading = "[[",         -- Go to previous heading
    },

    inline_surround = {
      -- Surround mappings with gs + key
      emphasis = {
        key = "i",
        txt = "*",
      },
      strong = {
        key = "b",
        txt = "**",
      },
      strikethrough = {
        key = "s",
        txt = "~~",
      },
      code = {
        key = "c",
        txt = "`",
      },
    },

    link = {
      paste = {
        enable = true,  -- Auto-create links when pasting URLs
      },
    },

    toc = {
      -- Table of contents settings
      omit_heading = "toc omit heading",
      omit_section = "toc omit section",
      markers = { "-" },
    },

    -- Hooks - disable on_attach to avoid conflicts with obsidian.nvim keymaps
    on_attach = function(bufnr)
      local map = vim.keymap.set
      local opts = { buffer = bufnr, silent = true }

      -- Additional markdown-specific keymaps
      map("n", "<leader>mt", "<cmd>MDToc<cr>", vim.tbl_extend("force", opts, { desc = "Insert TOC" }))
      map("n", "<leader>ml", "<cmd>MDListItemBelow<cr>", vim.tbl_extend("force", opts, { desc = "Add list item below" }))
      map("n", "<leader>mL", "<cmd>MDListItemAbove<cr>", vim.tbl_extend("force", opts, { desc = "Add list item above" }))
      map("n", "<leader>mr", "<cmd>MDResetListNumbering<cr>", vim.tbl_extend("force", opts, { desc = "Reset list numbering" }))
      map("n", "<leader>mT", "<cmd>MDTaskToggle<cr>", vim.tbl_extend("force", opts, { desc = "Toggle task" }))

      -- Visual mode formatting
      map("v", "<leader>mb", "<cmd>MDToggle bold<cr>", vim.tbl_extend("force", opts, { desc = "Toggle bold" }))
      map("v", "<leader>mi", "<cmd>MDToggle italic<cr>", vim.tbl_extend("force", opts, { desc = "Toggle italic" }))
      map("v", "<leader>mc", "<cmd>MDToggle code<cr>", vim.tbl_extend("force", opts, { desc = "Toggle code" }))
      map("v", "<leader>ms", "<cmd>MDToggle strikethrough<cr>", vim.tbl_extend("force", opts, { desc = "Toggle strikethrough" }))
    end,
  },
}
