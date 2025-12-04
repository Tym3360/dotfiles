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
          "texlab"-- Changed from pylsp, but you can use either
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
  settings = {
    texlab = {
      build = {
        executable = "latexmk",
        args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
        onSave = true,
      },
      forwardSearch = {
        executable = "skim", -- or "zathura" on Linux, "sumatrapdf" on Windows
        args = { "--synctex-forward", "%l:1:%f", "%p" },
      },
    },
  },
}

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
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'LSP: Show References' })
      vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, { desc = 'LSP: Rename' })
      vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, { desc = 'LSP: Code Action' })
      vim.keymap.set('n', '<space>f', function()
        vim.lsp.buf.format({ async = true })
      end, { desc = 'LSP: Format' })
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
