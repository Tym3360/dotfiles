return {
  "nvim-treesitter/nvim-treesitter",
  branch = 'master',
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      ensure_installed = {"lua", "markdown", "markdown_inline", "python",  "bash", "c_sharp", "latex"},
      highlight = { enable = true },
      indent = { enable = true },
    })

    -- Autocmd belongs inside the config function
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function()
        vim.cmd("normal! gg=G``")
      end,
    })
  end,
}
