-- Snacks dashboard (replaces alpha-nvim) with the same aesthetic as LazyVim:
-- big header, key hints bound to THIS config's actual leader maps, and
-- quick access to the Obsidian vault (same as <leader>tw behaviour).
return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          keys = {
            { icon = " ", key = "<leader>sf", desc = "Find File", action = function() Snacks.dashboard.pick("files") end },
            { icon = " ", key = "<leader>sr", desc = "Recent Files", action = function() Snacks.dashboard.pick("recent") end },
            { icon = " ", key = "<leader>sg", desc = "Find Text", action = function() Snacks.dashboard.pick("grep") end },
            { icon = " ", key = "o", desc = "Open Obsidian Vault", action = function()
              -- capture-ss vault / Home.md — mirrors the old <leader>tw map
              local dir = "/run/user/386641961/gvfs/smb-share:server=fgen-srv-smb.genie.usherbrooke.ca,share=locus/Partage/Projects/Carbon Management/Capture SS/99_Notes_Obsidian/Obsidian_Capture_SS"
              vim.cmd("cd " .. vim.fn.fnameescape(dir))
              vim.cmd("edit " .. vim.fn.fnameescape(dir .. "/Home.md"))
            end },
            { icon = " ", key = "<leader>gg", desc = "Lazygit", action = function() Snacks.lazygit() end },
            { icon = " ", key = "A", desc = "OpenCode", action = function()
              -- replays the global <leader>ot toggle from opencode.lua
              require("snacks.terminal").toggle("opencode", { win = { position = "right", enter = false } })
            end },
            { icon = " ", key = "L", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { icon = " ", section = "startup" },
        },
      },
    },
  },
}
