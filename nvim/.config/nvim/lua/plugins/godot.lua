-- File: ~/.config/nvim/lua/plugins/godot.lua

return {
  -- Godot project detection, C# LSP, and utilities
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Check if we're in a Godot project
      local function is_godot_project()
        local paths_to_check = { "", "..", "../..", "../../.." }
        for _, path in ipairs(paths_to_check) do
          local godot_project = vim.fn.getcwd() .. "/" .. path .. "/project.godot"
          if vim.fn.filereadable(godot_project) == 1 then
            return true, vim.fn.fnamemodify(godot_project, ":h")
          end
        end
        return false, ""
      end

      local is_godot, godot_path = is_godot_project()

      -- Start Neovim server for Godot if in a Godot project
      if is_godot then
        local pipe_path = godot_path .. "/godot.pipe"

        -- Check if server is already running
        local servers = vim.fn.serverlist()
        local server_running = false
        for _, server in ipairs(servers) do
          if server == pipe_path then
            server_running = true
            break
          end
        end

        -- Start server if not running
        if not server_running then
          vim.fn.serverstart(pipe_path)
        end

        -- Make is_godot available globally for other configs
        vim.g.is_godot_project = true
        vim.g.godot_project_path = godot_path
      end

      -- Only set up Godot commands if in a Godot project
      if vim.g.is_godot_project then
        -- Add C# breakpoint
        vim.api.nvim_create_user_command("GodotBreakpoint", function()
          local line = vim.fn.line(".")
          local indent = vim.fn.indent(line)
          local spaces = string.rep(" ", indent)
          vim.fn.append(line, spaces .. "System.Diagnostics.Debugger.Break();")
        end, { desc = "Add C# breakpoint" })

        -- Delete all breakpoints in current buffer
        vim.api.nvim_create_user_command("GodotDeleteBreakpoints", function()
          vim.cmd([[g/System.Diagnostics.Debugger.Break();/d]])
        end, { desc = "Delete all C# breakpoints in buffer" })

        -- Find all breakpoints in project
        vim.api.nvim_create_user_command("GodotFindBreakpoints", function()
          vim.cmd([[vimgrep /System.Diagnostics.Debugger.Break();/gj **/*.cs]])
          vim.cmd("copen")
        end, { desc = "Find all C# breakpoints in project" })

        -- Keymaps for Godot C# development
        vim.keymap.set("n", "<leader>gb", ":GodotBreakpoint<CR>",
          { desc = "Godot: Add breakpoint" })
        vim.keymap.set("n", "<leader>gd", ":GodotDeleteBreakpoints<CR>",
          { desc = "Godot: Delete breakpoints" })
        vim.keymap.set("n", "<leader>gf", ":GodotFindBreakpoints<CR>",
          { desc = "Godot: Find breakpoints" })
      end
    end,
  },

  -- Treesitter for C# syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "c_sharp" })
      end
    end,
  },
}
