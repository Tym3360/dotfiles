return {
  "nvim-treesitter/nvim-treesitter",
  branch = 'master',
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      ensure_installed = {"lua", "markdown", "markdown_inline", "python", "bash", "c_sharp", "latex", "c", "cpp"},
      highlight = { enable = true },
      indent = { enable = true },
    })

    -- Auto-indent on save for treesitter-supported filetypes.
    -- (Avoids running on every file, which is slow for large buffers.)
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.lua", "*.py", "*.c", "*.cpp", "*.h", "*.hpp", "*.cxx", "*.hxx", "*.tex", "*.bib", "*.md" },
      callback = function()
        vim.cmd("normal! gg=G``")
      end,
    })
  end,
}
