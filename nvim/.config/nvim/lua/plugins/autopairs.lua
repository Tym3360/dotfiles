-- File: ~/.config/nvim/lua/plugins/autopairs.lua
-- VSCode/PyCharm-style bracket pairing: typing ( [ { " ' ` inserts the pair
-- with the cursor in the middle. To move past the closing character, just
-- press <Right> (nothing is remapped on the arrow keys).

return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
      local npairs = require("nvim-autopairs")
      local cond = require("nvim-autopairs.conds")

      npairs.setup({
        -- <CR> stays owned by nvim-cmp (see nvim_cmp.lua): no auto-line-break
        -- / indent expansion from autopairs.
        map_cr = false,
        disable_filetype = {
          -- plugin defaults:
          "TelescopePrompt", "spectre_panel", "snacks_picker_input",
          -- do not pair in markup/TeX: Obsidian [[link]] typing and the LaTeX
          -- snippet workflow manage their own brackets
          "markdown", "tex", "plaintex", "bib",
        },
        -- treesitter-aware checks; disabled explicitly for rust so pairing
        -- still works inside string literals like format!("{}")
        check_ts = true,
        ts_config = { rust = false },
      })

      -- Rust lifetimes: 'a is not string quoting, so never pair the single
      -- quote in rust buffers (documented workaround, same as scheme/lisp).
      npairs.get_rules("'")[1].not_filetypes = { "rust" }
      npairs.get_rules("'")[1]:with_pair(cond.not_filetypes({ "rust" }))

      -- nvim-cmp integration: confirming a function/method completion inside
      -- an existing '(' inserts (), confirming one without '(' adds a pair.
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

      -- Escape hatch
      vim.keymap.set("n", "<leader>ap", function()
        npairs.toggle()
      end, { desc = "Toggle autopairs" })
    end,
  },
}
