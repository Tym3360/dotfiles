-- Single source of truth for Obsidian vault locations.
--
-- Consumed by:
--   - lua/plugins/obsidian.lua   (obsidian.nvim `workspaces`)
--   - lua/config/picker_root.lua (search-root resolution for file finders)
--   - lua/plugins/nvim_cmp.lua   ([[ link / # tag autotrigger guard)
--
-- Add or change vaults here; everything else follows.
return {
  {
    name = "personal",
    path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Tym",
  },
  {
    name = "capture-ss",
    path = "/Volumes/LOCUS/Partage/Projects/Carbon Management/Capture SS/99_Notes_Obsidian/Obsidian_Capture_SS",
  },
}
