return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pylsp",
          "texlab",
          "arduino_language_server",
          "clangd",
        },
        automatic_installation = true,
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim"
    },
    config = function()
      -- Configure LSP servers with custom settings using vim.lsp.config
      -- Lua Language Server configuration
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }, -- Recognize 'vim' as a global
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
      -- Pyright configuration
      vim.lsp.config.pylsp = {
        cmd = { 'pylsp' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', '.git' },

        before_init = function(params, config)
          if vim.g.poetv_venv then
            config.settings = vim.deepcopy(config.settings or {})
            config.settings.pylsp = config.settings.pylsp or {}
            config.settings.pylsp.plugins = config.settings.pylsp.plugins or {}
            config.settings.pylsp.plugins.jedi = config.settings.pylsp.plugins.jedi or {}
            config.settings.pylsp.plugins.jedi.environment = vim.g.poetv_venv .. '/bin/python'
          end
        end,

        settings = {
          pylsp = {
            plugins = {
              pycodestyle = { enabled = true },
              pyflakes = { enabled = true },
              pylint = { enabled = false },
              mccabe = { enabled = false },
            }
          }
        }
      }

      vim.lsp.enable('pylsp')
      -- Texlab LSP setup using new vim.lsp.config API (Neovim 0.11+)
      vim.lsp.config.texlab = {
        cmd = { "texlab" },
        filetypes = { "tex", "plaintex", "bib" },
        root_markers = { ".latexmkrc", ".git" },
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
        handlers = {
          ["textDocument/publishDiagnostics"] = function() end,
        },
        settings = {
          texlab = {
            build = {
              executable = "latexmk",
              args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
              onSave = false,
            },
            chktex = {
              onOpenAndSave = false,
              onEdit = false,
            },
            forwardSearch = {
              executable = "skim", -- or "zathura" on Linux, "sumatrapdf" on Windows
              args = { "--synctex-forward", "%l:1:%f", "%p" },
            },
          },
        },
      }

      -- Arduino Language Server configuration
      -- Arduino Language Server configuration
      -- NOTE: Arduino Language Server does NOT work with PlatformIO projects!
      -- For PlatformIO, we use clangd with compile_commands.json instead.
      -- This only works for standalone Arduino IDE projects with .ino files.
      vim.lsp.config.arduino_language_server = {
        cmd = {
          "arduino-language-server",
          "-cli-config", vim.fn.expand("~/Library/Arduino15/arduino-cli.yaml"),
          "-clangd", "clangd",
          "-cli", "arduino-cli",
          "-fqbn", "arduino:avr:uno" -- Default board, can be overridden per project
        },
        filetypes = { "arduino" },  -- Only for .ino files (standalone Arduino projects)
        root_markers = { "*.ino" },
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
      }


      -- Clangd (C/C++) configuration - works for both regular C++ and PlatformIO
      vim.lsp.config.clangd = {
        cmd = { "clangd" },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto", "arduino" },
        root_markers = {
          "compile_commands.json",
          "compile_flags.txt",
          ".clangd",
          "CMakeLists.txt",
          "Makefile",
          ".git",
          -- PlatformIO project markers
          "platformio.ini",
          ".pio",
        },
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
        settings = {
          clangd = {
            InlayHints = { Enabled = true },
            -- Point to compile_commands.json in project root
            compilationDatabasePath = ".",
          },
        },
      }

      -- Function to detect if we're in a PlatformIO project
      local function is_platformio_project()
        return vim.fn.filereadable(vim.fn.getcwd() .. "/platformio.ini") == 1
      end

      -- Function to check if a file includes Arduino.h
      -- NOTE: When both arduino_language_server and clangd are active for the same buffer,
      -- you may see duplicate diagnostics (e.g. both report the same error).
      -- To silence one, add a handler in the LSP config that discards its diagnostics.
      local function has_arduino_header(bufnr)
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
        for _, line in ipairs(lines) do
          if line:match('#include.*Arduino%.h') then
            return true
          end
        end
        return false
      end

      -- Enable clangd for C/C++ files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "cpp" },
        callback = function(args)
          -- For PlatformIO projects: use ONLY clangd (Arduino LSP doesn't work with PlatformIO)
          -- Note: compile_commands.json generation is handled by the platformio plugin config
          if is_platformio_project() then
            -- Enable clangd for C++ diagnostics
            vim.lsp.enable("clangd")
          -- For standalone Arduino .cpp files with Arduino.h, enable both LSPs
          elseif has_arduino_header(args.buf) then
            vim.lsp.enable("arduino_language_server")
            vim.lsp.enable("clangd")
          -- For regular C++ files (not Arduino), just use clangd
          else
            vim.lsp.enable("clangd")
          end
        end,
      })

      -- Enable Arduino LSP for .ino files (standalone Arduino projects only)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "arduino",
        callback = function()
          -- For standalone Arduino IDE projects: enable Arduino LSP
          -- Arduino IDE requires: directory name == .ino filename (without extension)
          -- E.g., Blink/Blink.ino
          if not is_platformio_project() then
            local bufname = vim.api.nvim_buf_get_name(0)
            local dir = vim.fn.fnamemodify(bufname, ':h')
            local dirname = vim.fn.fnamemodify(dir, ':t')  -- Directory name
            local name_no_ext = vim.fn.fnamemodify(bufname, ':t:r')  -- Filename without .ino
            
            -- Check if this is a proper Arduino IDE project structure
            -- (directory name must match the .ino filename)
            if dirname == name_no_ext then
              vim.lsp.enable("arduino_language_server")
            else
              -- Not a proper Arduino IDE project structure
              -- Arduino CLI would fail to compile this, so Arduino LSP won't work
              -- We just use clangd (without compilation database)
            end
          end
          -- Always enable clangd for Arduino files
          vim.lsp.enable("clangd")
        end,
      })

      -- User command to regenerate compile_commands.json for PlatformIO
      vim.api.nvim_create_user_command("PioCompiledb", function()
        if not is_platformio_project() then
          vim.notify("Not a PlatformIO project", vim.log.levels.WARN)
          return
        end
        vim.notify("Generating compile_commands.json...", vim.log.levels.INFO)
        vim.fn.jobstart("pio run -t compiledb", {
          on_exit = function(_, exit_code)
            if exit_code == 0 then
              vim.schedule(function()
                vim.notify("compile_commands.json generated successfully", vim.log.levels.INFO)
                -- clangd will auto-detect compile_commands.json changes
              end)
            else
              vim.schedule(function()
                vim.notify("Failed to generate compile_commands.json", vim.log.levels.ERROR)
              end)
            end
          end,
        })
      end, { desc = "Generate compile_commands.json for PlatformIO" })

      -- Enable texlab for LaTeX files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tex", "plaintex", "bib" },
        callback = function()
          vim.lsp.enable("texlab")
        end,
      })
      -- Enable other LSP servers using new Nvim 0.11+ way
      vim.lsp.enable('lua_ls')
      vim.lsp.enable('pylsp')
      -- Global LSP keymaps (apply to all buffers with LSP)
      -- Note: Nvim 0.11+ sets some default keymaps automatically
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'LSP: Hover Documentation' })
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP: Go to Definition' })
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'LSP: Go to Declaration' })
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'LSP: Go to Implementation' })
      vim.keymap.set('n', 'gR', vim.lsp.buf.references, { desc = 'LSP: Show References' })
      vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, { desc = 'LSP: Rename' })
      vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, { desc = 'LSP: Code Action' })
      vim.keymap.set('n', '<space>fm', function()
        vim.lsp.buf.format({ async = true })
      end, { desc = 'LSP: Format' })
      -- Note: <C-k> in insert/select mode is also mapped by LuaSnip (expand/jump forward).
      -- The modal split is intentional: normal mode = LSP signature help,
      -- insert/select mode = LuaSnip snippet navigation.
      vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { desc = 'LSP: Signature Help' })
      vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, { desc = 'LSP: Type Definition' })
      -- Optional: Configure diagnostics display
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = 'rounded',
        },
      })
      -- Optional: Customize diagnostic signs
      local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    end
  },
}
