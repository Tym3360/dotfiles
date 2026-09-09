return {
  'anurag3301/nvim-platformio.lua',
  dependencies = {
    { 'akinsho/toggleterm.nvim' },
  },
  config = function()
    vim.g.pioConfig = {
      lsp = 'clangd',
      clangd_source = 'compiledb',  -- Use compiledb to generate compile_commands.json
      picker_backend = 'auto',
      menu_key = '<leader>\\',
      debug = false,
    }
    local pok, platformio = pcall(require, 'platformio')
    if pok then platformio.setup(vim.g.pioConfig) end
    
    -- Auto-generate compile_commands.json for clangd when opening PlatformIO files
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      pattern = { "platformio.ini", "*.cpp", "*.c", "*.h", "*.hpp", "*.ino" },
      callback = function()
        local pio_ini = vim.fn.getcwd() .. "/platformio.ini"
        if vim.fn.filereadable(pio_ini) == 1 then
          local compile_db = vim.fn.getcwd() .. "/compile_commands.json"
          
          -- Always generate/refresh compile_commands.json
          vim.fn.jobstart("pio run -t compiledb", {
            on_exit = function(_, exit_code)
              if exit_code == 0 and vim.fn.filereadable(compile_db) == 1 then
                vim.schedule(function()
                  vim.notify("Generated compile_commands.json for clangd", vim.log.levels.INFO)
                  -- clangd will auto-detect compile_commands.json changes
                  -- No need to restart - just notify the user
                end)
              end
            end,
          })
        end
      end,
    })
  end,
}
