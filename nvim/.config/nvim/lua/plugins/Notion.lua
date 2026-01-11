return{
  "Al0den/notion.nvim",
  lazy = false, --Should work when lazy loaded, not tested
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require"notion".setup{
      autoUpdate = true, --Allow the plugin to automatically update the data from the Notion API
      open = "notion", --If not set, or set to something different to notion, will open in web browser
      keys = { --Menu keys
        deleteKey = "d", 
        editKey = "e",
        openNotion = "o",
        itemAdd = "a",
        viewKey = "v"
      },
      delays = { --Delays before running specific actions
        reminder = 4000,
        format = 200,
        update = 10000
      },
      notifications = true, --Enable notifications
      editor = "light", --light/medium/full, changes the amount of data displayed in editor
      viewOnEdit = {
        enabled = true, --Enable double window, view and edit simultaneously
        replace = false --Replace current window with preview window
      },
      direction = "vsplit", --Direction windows will be opened in
      noEvent = "No events",
      debug = true --Enable some error messages on failed API calls
    }
  end,
}
