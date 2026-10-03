return {
  "nvim-treesitter/nvim-treesitter",
  -- The old `master` branch is archived and does NOT support Neovim 0.12+.
  -- `main` is the rewritten plugin with a new API (setup/highlight/indent
  -- modules are gone; features are enabled via Neovim built-ins).
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    -- Install parsers (no-op for ones already installed).
    -- Sync wait so render-markdown.nvim has parsers available on first open.
    pcall(function()
      local task = ts.install({
        "lua", "markdown", "markdown_inline", "python", "bash",
        "c_sharp", "latex", "c", "cpp", "html",
      })
      if task then
        task:wait(300000)
      end
    end)

    -- Enable treesitter highlighting + indentation per filetype.
    -- (Replaces the legacy `highlight = { enable = true }` / `indent = { enable = true }` setup.)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "lua", "markdown", "python", "bash", "cs", "c", "cpp", "html", "tex", "latex" },
      callback = function(args)
        local buf = args.buf
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        -- Skip if parser isn't installed (e.g. during first-run download).
        if not (lang and vim.treesitter.language.add(lang)) then
          return
        end
        pcall(vim.treesitter.start, buf)
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
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
