return {
  "pablopunk/pi.nvim",
  cmd = { "PiAsk", "PiAskSelection", "PiCancel", "PiLog" },
  opts = {
    provider = "opencode-go",
    model = "glm-5.3-flash",
  },
  keys = {
    { "<leader>ai", ":PiAsk<CR>", mode = "n", desc = "Ask pi" },
    { "<leader>ai", ":PiAskSelection<CR>", mode = "v", desc = "Ask pi (selection)" },
  },
  config = function(_, opts)
    require("pi").setup(opts)

    -- Register with which-key for discoverability
    pcall(function()
      local wk = require("which-key")
      wk.add({
        { "<leader>a", group = "AI" },
        { "<leader>ai", desc = "Ask pi" },
      })
    end)
  end,
}
