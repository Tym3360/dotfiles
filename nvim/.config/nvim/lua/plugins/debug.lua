return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "Cliffback/netcoredbg-macOS-arm64.nvim",
  },
  config = function ()
    local dap, dapui = require("dap"), require("dapui")
    require("dapui").setup()
    require('netcoredbg-macOS-arm64').setup(require('dap'))

    -- lldb-dap adapter (macOS Xcode CLT) for C/C++
    dap.adapters.lldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = "/Library/Developer/CommandLineTools/usr/bin/lldb-dap",
        args = { "--port", "${port}" },
      },
    }

    dap.configurations.cpp = {
      {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
        env = {},
      },
      {
        name = "Launch with args",
        type = "lldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        args = function()
          local args_str = vim.fn.input("Arguments: ")
          return vim.split(args_str, " ")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        env = {},
      },
    }
    dap.configurations.c = dap.configurations.cpp

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
    vim.keymap.set('n','<Leader>dc', function() require('dap').continue() end)
    vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
    vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
    vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
    vim.keymap.set('n', '<Leader>db', function() require('dap').toggle_breakpoint() end)
    vim.keymap.set('n', '<Leader>dB', function() require('dap').set_breakpoint() end)

  end,
}
