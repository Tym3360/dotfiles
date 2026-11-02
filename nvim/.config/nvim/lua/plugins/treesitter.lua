return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- Install/update parsers. Using :wait() guarantees parsers are ready before
    -- the first buffer is opened. On subsequent startups this is a fast no-op.
    local langs = {
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "bash",
      "c_sharp",
      "c",
      "cpp",
      "rust",
    }

    local ok, err = pcall(function()
      require("nvim-treesitter").install(langs):wait(300000)
    end)
    if not ok then
      vim.notify("nvim-treesitter parser install failed: " .. tostring(err), vim.log.levels.WARN)
    end

    -- Enable treesitter highlighting for supported filetypes.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "lua", "markdown", "python", "bash", "sh", "cs", "c", "cpp", "rust" },
      callback = function()
        vim.treesitter.start()
      end,
    })

    -- Enable treesitter-based indentation for supported filetypes.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "lua", "python", "c", "cpp", "cs", "rust" },
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    -- Auto-indent code on save for treesitter-supported filetypes.
    -- NOTE: *.rs is deliberately excluded - Rust buffers are formatted with
    -- rustfmt on save instead (see lua/plugins/rust.lua).
    -- NOTE: *.md, *.tex and *.bib are deliberately excluded: `gg=G` reindents
    -- prose, and markdown has no indentexpr here, so it inherits indentation
    -- and turns a normal README into hundreds of leading spaces on every line.
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.lua", "*.py", "*.c", "*.cpp", "*.h", "*.hpp", "*.cxx", "*.hxx" },
      callback = function()
        vim.cmd("normal! gg=G``")
      end,
    })
  end,
}
