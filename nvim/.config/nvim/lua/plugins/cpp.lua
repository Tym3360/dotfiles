return {
  {
    "nvim-telescope/telescope.nvim",
    config = function()
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
}
