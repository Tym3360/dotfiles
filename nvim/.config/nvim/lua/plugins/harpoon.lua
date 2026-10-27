return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = function()
    local keys = {
      { "<leader>h", group = "Harpoon" },
      { "<leader>ha", desc = "Harpoon add file", mode = "n" },
      { "<leader>hm", desc = "Harpoon menu", mode = "n" },
      { "<leader>ht", desc = "Harpoon telescope menu", mode = "n" },
      { "]", desc = "Harpoon next", mode = "n" },
      { "[", desc = "Harpoon prev", mode = "n" },
      { "<leader>h1", desc = "Harpoon file 1", mode = "n" },
      { "<leader>h2", desc = "Harpoon file 2", mode = "n" },
      { "<leader>h3", desc = "Harpoon file 3", mode = "n" },
      { "<leader>h4", desc = "Harpoon file 4", mode = "n" },
    }
    -- Show under <leader>h in which-key
    pcall(function()
      require("which-key").add({
        { "<leader>h", group = "Harpoon" },
        { "<leader>ha", desc = "Add file" },
        { "<leader>hm", desc = "Quick menu" },
        { "<leader>ht", desc = "Telescope menu" },
        { "]", desc = "Next mark" },
        { "[", desc = "Prev mark" },
        { "<leader>h1", desc = "Go to file 1" },
        { "<leader>h2", desc = "Go to file 2" },
        { "<leader>h3", desc = "Go to file 3" },
        { "<leader>h4", desc = "Go to file 4" },
      })
    end)
    return keys
  end,
  config = function()
    local harpoon = require("harpoon")

    harpoon:setup({
      settings = {
        save_on_toggle = false,  -- ui toggle also persists list
        save_on_change = true,   -- persist when navigating the list
        enter_on_sendcmd = false,
        tmux_autoclose_windows = false,
        excluded_filetypes = { "harpoon", "NvimTree", "neo-tree", "TelescopePrompt" },
        mark_branch = false,     -- false = one global list; true = per git branch
      },
    })

    local map = vim.keymap.set

    -- Add current file to the list
    map("n", "<leader>ha", function()
      harpoon:list():add()
    end, { desc = "Harpoon add file" })

    -- Open the harpoon quick menu (edit list in a floats)
    map("n", "<leader>hm", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon quick menu" })

    -- Telescope integration for the harpoon menu (falls back if missing)
    map("n", "<leader>ht", function()
      local ok, _ = pcall(require, "telescope")
      if ok then
        local conf = require("telescope.config").values
        local finders = require("telescope.finders")
        local pickers = require("telescope.pickers")
        local make_entry = require("telescope.make_entry")
        local themes = require("telescope.themes")

        local file_paths = {}
        for _, item in ipairs(harpoon:list().items) do
          table.insert(file_paths, item.value)
        end

        pickers.new(themes.get_dropdown({}), {
          prompt_title = "Harpoon",
          finder = finders.new_table({
            results = file_paths,
            entry_maker = make_entry.gen_from_file({}),
          }),
          previewer = require("telescope.config").values.file_previewer({}),
          sorter = conf.generic_sorter({}),
        }):find()
      else
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end
    end, { desc = "Harpoon telescope menu" })

    -- Navigate previous / next in the list
    map("n", "[", function()
      harpoon:list():prev()
    end, { desc = "Harpoon prev" })
    map("n", "]", function()
      harpoon:list():next()
    end, { desc = "Harpoon next" })

    -- Jump directly to file N
    for i = 1, 4 do
      map("n", "<leader>h" .. i, function()
        local ok, entry = pcall(function() return harpoon:list():get(i) end)
        if ok and entry then
          harpoon:list():select(i)
        else
          vim.notify("Harpoon: no mark at position " .. i, vim.log.levels.WARN)
        end
      end, { desc = "Harpoon file " .. i })
    end
  end,
}
