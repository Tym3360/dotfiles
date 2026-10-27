return {
  "mfussenegger/nvim-dap-python",
  config = function()
    -- uv-native setup: the debug adapter is launched via `uv run --with debugpy`,
    -- so debugpy is always available on demand even if it's not in the project venv.
    -- The program being debugged uses the project's .venv automatically
    -- (nvim-dap-python resolves pythonPath from VIRTUAL_ENV / .venv next to the root).
    if vim.fn.executable("uv") == 1 then
      require("dap-python").setup("uv")
    else
      -- Fallback to a dedicated venv that has debugpy pre-installed
      local debugpy_path = vim.fn.expand("~/.virtualenvs/debugpy/bin/python")
      if vim.fn.filereadable(debugpy_path) == 1 then
        require("dap-python").setup(debugpy_path)
      else
        vim.notify("nvim-dap-python: no `uv` and no debugpy venv found", vim.log.levels.WARN)
      end
    end
  end,
}
