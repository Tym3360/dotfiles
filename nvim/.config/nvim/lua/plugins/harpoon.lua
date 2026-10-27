return {
  -- Harpoon 2: bookmark key files, jump to them instantly
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  -- All mappings live here so lazy.nvim loads harpoon on any of them
  keys = function()
    local harpoon_keys = {
      { "<leader>ha", desc = "Harpoon: add file" },
      { "<leader>hm", desc = "Harpoon: quick menu" },
      { "<leader>h1", desc = "Harpoon: file 1" },
      { "<leader>h2", desc = "Harpoon: file 2" },
      { "<leader>h3", desc = "Harpoon: file 3" },
      { "<leader>h4", desc = "Harpoon: file 4" },
      { "<leader>hn", desc = "Harpoon: next file" },
      { "<leader>hp", desc = "Harpoon: previous file" },
    }
    return harpoon_keys
  end,
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    local map = function(key, fn, desc)
      vim.keymap.set("n", key, fn, { desc = desc })
    end

    -- Add current file to harpoon list
    map("<leader>ha", function() harpoon:list():add() end, "Harpoon: add file")

    -- Quick menu (file list, editable in-place)
    map("<leader>hm", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, "Harpoon: quick menu")

    -- Jump to slots 1-4 (<leader>h1..4)
    map("<leader>h1", function() harpoon:list():select(1) end, "Harpoon: file 1")
    map("<leader>h2", function() harpoon:list():select(2) end, "Harpoon: file 2")
    map("<leader>h3", function() harpoon:list():select(3) end, "Harpoon: file 3")
    map("<leader>h4", function() harpoon:list():select(4) end, "Harpoon: file 4")

    -- Cycle through the list
    map("<leader>hn", function() harpoon:list():next() end, "Harpoon: next file")
    map("<leader>hp", function() harpoon:list():prev() end, "Harpoon: previous file")

    -- which-key group
    pcall(function()
      local wk = require("which-key")
      wk.add({
        { "<leader>h", group = "Harpoon" },
      })
    end)
  end,
}
