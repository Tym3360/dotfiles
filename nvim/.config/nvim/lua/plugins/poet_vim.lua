return {
  'petobens/poet-v',
  enabled = false,  -- Disabled: Neovim lacks python3 host support on this system
  ft = 'python',  -- Lazy load only for Python files

  config = function()
    -- Auto-activate poetry environment when opening Python files
    vim.g.poetv_auto_activate = 1

    -- Executables to search for (in order of preference)
    vim.g.poetv_executables = {'poetry'}

    -- Set the statusline symbol (optional)
    vim.g.poetv_statusline_symbol = ' 🐍'
  end,
}
