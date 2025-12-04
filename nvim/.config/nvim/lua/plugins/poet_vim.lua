return {
  'petobens/poet-v',
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
