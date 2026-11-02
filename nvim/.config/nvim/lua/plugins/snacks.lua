-- snacks.nvim: collection of QoL modules (picker, explorer, terminal, etc.).
-- Kept as a top-level spec because several modules need to be set up early.
-- Note: snacks.dashboard is configured in snacks-dashboard.lua and now owns
-- the startup screen (alpha-nvim was removed).
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    explorer = { enabled = true },
    git = { enabled = true },
    gitbrowse = {
      enabled = true,
      -- Open the current file/line rather than the commit page.
      what = "file",
    },
    indent = { enabled = true },
    input = { enabled = true },
    lazygit = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    picker = { enabled = true },
    quickfile = { enabled = true },
    rename = { enabled = true },
    scope = { enabled = true },
    scratch = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    toggle = { enabled = true },
    words = { enabled = true },
    zen = { enabled = true },
    styles = {
      notification = {
        wo = { wrap = true },
      },
    },
  },
  keys = {
    -- Search / pickers (telescope keeps <leader>f*)
    { "<leader>sf", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>sw", function() Snacks.picker.grep_word() end, mode = { "n", "x" }, desc = "Grep Word/Selection" },
    { "<leader>sb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>sr", function() Snacks.picker.recent() end, desc = "Recent Files" },
    { "<leader>sl", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
    { "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume Picker" },

    -- Explorer
    { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
    -- The tree used to be neo-tree on <C-n> (removed in favour of snacks);
    -- keep the muscle memory.
    { "<C-n>", function() Snacks.explorer() end, desc = "Toggle File Explorer" },

    -- Git (uppercase to avoid godot's <leader>gb/gd/gf buffer maps)
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gB", function() Snacks.gitbrowse() end, mode = { "n", "v" }, desc = "Git Browse" },
    { "<leader>gS", function() Snacks.picker.git_status() end, desc = "Git Status" },
    { "<leader>gL", function() Snacks.picker.git_log() end, desc = "Git Log" },
    { "<leader>gD", function() Snacks.picker.git_diff() end, desc = "Git Diff" },
    { "<leader>gF", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },

    -- Buffers / files
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },

    -- Terminal / scratch / zen
    { "<C-/>", function() Snacks.terminal() end, mode = { "n", "t" }, desc = "Toggle Terminal" },
    { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode" },
    { "<leader>Z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },

    -- Notifications
    { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss Notifications" },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Debug helpers (available as :lua dd(...) / :lua bt())
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end

        -- UI toggles
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.option("conceallevel", {
          off = 0,
          on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
        }):map("<leader>uc")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")

        pcall(function()
          require("which-key").add({
            { "<leader>s", group = "Search" },
            { "<leader>g", group = "Git" },
            { "<leader>u", group = "UI" },
            { "<leader>b", group = "Buffer" },
          })
        end)
      end,
    })
  end,
}
