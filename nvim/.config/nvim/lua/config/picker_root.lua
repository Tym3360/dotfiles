-- Search-root resolution for the file finders (snacks picker, telescope).
--
-- Both scan from the Neovim working directory by default. That's fine while
-- cwd is a project or a vault, but balloons badly when nvim was launched
-- from $HOME (or a dead cwd was repaired to $HOME): "Find Files" would scan
-- the whole computer.
--
-- Root precedence:
--   1. obsidian vault root, if the buffer lives in one
--   2. git repo root containing the buffer
--   3. the buffer's directory — unless that IS $HOME, in which case cwd is
--      the honest scope (the user really did open nvim at ~)

local M = {}

---@return string
function M.root()
  local buf = vim.api.nvim_buf_get_name(0)
  local dir = (buf ~= "" and vim.fs.dirname(buf)) or (vim.uv.cwd() or vim.env.HOME)
  dir = vim.fs.normalize(dir)

  -- 1. obsidian vault containing the buffer (prefix match against the vault
  --    list in lua/config/vaults.lua — cheap, no obsidian.nvim loading)
  local ok_vaults, vaults = pcall(require, "config.vaults")
  if ok_vaults then
    local dir_p = dir .. "/"
    for _, vault in ipairs(vaults) do
      local root = vim.fs.normalize(vim.fn.expand(vault.path))
      if dir_p:sub(1, #root + 1) == root .. "/" then
        return root
      end
    end
  end

  -- 2. git repo root containing the buffer
  local ok_root, git_root = pcall(vim.fs.root, dir, { ".git" })
  if ok_root and git_root then
    return vim.fs.normalize(git_root)
  end

  -- 3. buffer directory, except never scan the entire home directory
  local home = vim.fs.normalize(vim.env.HOME or "~")
  if dir ~= "" and dir ~= home then
    return dir
  end

  return vim.uv.cwd() or home
end

return M
