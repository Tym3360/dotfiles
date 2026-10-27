return {
  {
    'nvim-telescope/telescope.nvim', branch = 'master', -- was pinned to tag 0.1.8, too old for nvim-treesitter main-branch rewrite
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

      -- Toggle between header and source file
      vim.keymap.set("n", "<leader>oh", function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local ext = bufname:match("%.([^.]+)$")
        local other
        if ext == "cpp" or ext == "cc" or ext == "cxx" or ext == "c" then
          other = bufname:gsub("%." .. ext .. "$", ".hpp")
          if not vim.loop.fs_stat(other) then
            other = bufname:gsub("%." .. ext .. "$", ".h")
          end
          if not vim.loop.fs_stat(other) then
            other = bufname:gsub("%." .. ext .. "$", ".hxx")
          end
        elseif ext == "hpp" or ext == "h" or ext == "hxx" then
          other = bufname:gsub("%." .. ext .. "$", ".cpp")
          if not vim.loop.fs_stat(other) then
            other = bufname:gsub("%." .. ext .. "$", ".cc")
          end
          if not vim.loop.fs_stat(other) then
            other = bufname:gsub("%." .. ext .. "$", ".cxx")
          end
          if not vim.loop.fs_stat(other) then
            other = bufname:gsub("%." .. ext .. "$", ".c")
          end
        else
          return
        end
        if vim.loop.fs_stat(other) then
          vim.cmd("edit " .. other)
        end
      end, { desc = "Toggle header/source" })
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
            }
          }
        }
      })
      require("telescope").load_extension("ui-select")
    end
  },
}
