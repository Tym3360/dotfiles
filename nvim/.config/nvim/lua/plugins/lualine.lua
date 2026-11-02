-- LazyVim-style statusline: mode block, global line, devicons, diff counts,
-- diagnostics counter, LSP clients, progress/location. Works on tokyonight.
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  init = function()
    -- one global statusline across windows (featured split indicator)
    vim.opt.laststatus = 3
  end,
  opts = {
    options = {
      theme = "auto",
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { statusline = { "snacks_dashboard" }, winbar = {} },
    },
    sections = {
      lualine_a = { { "mode", separator = { left = "" } } },
      lualine_b = { { "branch", icon = "", separator = "" } },
      lualine_c = {
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { "filename", path = 1, symbols = { modified = " ● ", readonly = "", unnamed = "" } },
      },
      lualine_x = {
        {
          "diff",
          symbols = { added = " ", modified = " ╱ ", removed = " " },
        },
        {
          "diagnostics",
          symbols = { error = " ", warn = " ", info = " ", hint = " " },
        },
      },
      lualine_y = {
        {
          -- attached LSP servers for the current buffer
          function()
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            if #clients == 0 then
              return ""
            end
            local names = {}
            for _, c in ipairs(clients) do
              names[#names + 1] = c.name
            end
            return "" .. (names[1] or "") .. (#names > 1 and ("+" .. (#names - 1)) or "")
          end,
          separator = "",
          padding = { left = 1, right = 0 },
        },
        { "progress", separator = " ", padding = { left = 1, right = 0 } },
        { "location", padding = { left = 0, right = 1 } },
      },
      lualine_z = {},
    },
    inactive_sections = {},
    extensions = { "lazy", "nvim-dap-ui", "toggleterm", "trouble", "quickfix" },
  },
}
