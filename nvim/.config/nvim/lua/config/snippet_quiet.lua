-- Shared between nvim_cmp.lua (Enter/Tab mappings + snippet auto-trigger
-- autocmd) and Luasnip.lua (<C-k> expand): a short quiet window armed by any
-- action that inserts text non-interactively (completion confirm, snippet
-- expansion). Those inserts fire TextChangedI while a snippet is active, and
-- the snippet auto-trigger would otherwise mistake the inserted text for a
-- typed prefix and re-open the completion menu right after Enter/expansion.

local M = {}

-- 250ms: long enough to cover cmp's confirm machinery (resolve timeout ~80ms
-- + feedkeys insert) and LuaSnip expansion; much shorter than the interval
-- between a human's Enter and their next typed character.
M.window_ns = 250 * 1e6

-- Arm the quiet window starting now.
M.arm = function()
  vim.g.nvim_cmp_snippet_quiet_until = vim.uv.hrtime() + M.window_ns
end

-- True while the window is armed. Lazily clears the flag once it has expired,
-- so a stale value never suppresses later typing.
M.quiet = function()
  local until_ns = vim.g.nvim_cmp_snippet_quiet_until
  if not until_ns then
    return false
  end
  if vim.uv.hrtime() < until_ns then
    return true
  end
  vim.g.nvim_cmp_snippet_quiet_until = nil
  return false
end

return M
