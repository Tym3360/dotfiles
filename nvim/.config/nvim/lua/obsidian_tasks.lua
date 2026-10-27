-- obsidian_tasks.lua
-- TickTick-style task pickers for Obsidian vaults, reimplemented without the
-- Obsidian Tasks/Dataview engines: rg-scans the vault for `- [ ]` lines,
-- parses 📅 due / ✅ done dates / priority emoji (⏫ 🔼 🔽), and excludes
-- `99 - Templates/` and `.trash/` — mirroring the queries in Tasks.md.
--
-- Commands (work from any buffer, even before obsidian.nvim lazy-loads):
--   :ObsidianTasksToday   due today or overdue
--   :ObsidianTasksAll     all open tasks
--   :ObsidianTasksInbox   open tasks with no date
--   :ObsidianTasksDone    completed in the last 30 days
--   :ObsidianTaskToggle   toggle the checkbox on the current line
--
-- Buffer-local keymaps inside vault markdown buffers:
--   <leader>tt  today/overdue   <leader>ta  all open
--   <leader>ti  inbox           <leader>td  done last 30 days
--   <leader>tw  open Home.md

local M = {}

-- Exclusions mirror the `path does not include 99 - Templates` lines in Tasks.md
local EXCLUDE_ARGS = {
  "-g", "!.trash/**",
  "-g", "!99 - Templates/**",
}

local PRIORITY = { ["⏫"] = 3, ["🔼"] = 2, ["🔽"] = 1 }

-- ---------------------------------------------------------------------------
-- helpers

---@return string  YYYY-MM-DD for today
local function today()
  return os.date("%Y-%m-%d")
end

---@param date_str string  YYYY-MM-DD
---@return number?  epoch at noon (nil if unparsable)
local function parse_date(date_str)
  local y, m, d = date_str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not y then return nil end
  local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
  if os.date("%Y", t) ~= y then return nil end -- invalid calendar date
  return t
end

---@return string  YYYY-MM-DD for n days ago
local function days_ago(n)
  return os.date("%Y-%m-%d", os.time() - n * 86400)
end

---@return string?  vault root (dir containing `.obsidian`) for a path or cwd
local function find_vault_root(path)
  local start = path and path ~= "" and vim.fs.dirname(path) or vim.uv.cwd()
  if not start then return nil end
  local found = vim.fs.find(".obsidian", { upward = true, path = start })
  if found and found[1] then
    return vim.fs.dirname(found[1])
  end
  return nil
end

local function notify(msg, level)
  vim.notify("[obsidian_tasks] " .. msg, level or vim.log.levels.INFO, { title = "Obsidian Tasks" })
end

-- ---------------------------------------------------------------------------
-- scanning & parsing

---@class Task
---@field path string    absolute file path
---@field lnum number    1-based line number
---@field text string    raw line content
---@field title string   task text (checkbox and link prefix stripped)
---@field due string?    📅 date
---@field done string?   ✅ date
---@field prio number    0 = none, 1..3 = 🔽..⏫
---@field folder string  folder containing the note ("" for root)

---Parse one markdown line into a task table (nil if not a task line).
function M.parse_task(path, lnum, text)
  local indent, box, rest = text:match("^(%s*)%- %[([ xX])%] (.*)$")
  if not box then return nil end
  if box == "x" or box == "X" then
    local due = rest:match("📅 (%d%d%d%d%-%d%d%-%d%d)")
    local done = rest:match("✅ (%d%d%d%d%-%d%d%-%d%d)")
    return {
      path = path,
      lnum = lnum,
      text = text,
      title = rest,
      due = due,
      done = done,
      prio = 0,
      folder = vim.fs.dirname(path):sub(#M._vault_root + 2) or "",
    }
  end
  local due = rest:match("📅 (%d%d%d%d%-%d%d%-%d%d)")
  local prio = 0
  for emoji, level in pairs(PRIORITY) do
    if rest:find(emoji, 1, true) and level > prio then prio = level end
  end
  return {
    path = path,
    lnum = lnum,
    text = text,
    title = rest,
    due = due,
    done = nil,
    prio = prio,
    folder = (vim.fs.dirname(path):sub(#M._vault_root + 2) or ""),
  }
end

---rg-scan the vault for checkbox lines, excluding templates and .trash.
---@return Task[]
local function scan_vault()
  if not M._vault_root then return {} end
  -- build explicitly: a mid-list unpack() would truncate the exclusions
  local args = {
    "rg", "--no-heading", "--line-number", "--color", "never",
    "-e", [[^\s*- \[[ xX]\] ]],
  }
  for _, a in ipairs(EXCLUDE_ARGS) do table.insert(args, a) end
  table.insert(args, M._vault_root)
  local out = vim.system(args, { text = true }):wait()
  if out.code > 1 and out.stderr ~= "" then
    notify("rg failed: " .. (out.stderr:gsub("\n", " "):sub(1, 120)), vim.log.levels.ERROR)
    return {}
  end
  local tasks = {}
  for chunk in out.stdout:gmatch("[^\r\n]+") do
    local path, lnum, rest = chunk:match("^(.-):(%d+):(.*)$")
    if path and rest:find("^%s*- %[", 1, false) then
      local task = M.parse_task(vim.fs.abspath(path), tonumber(lnum), rest)
      if task then table.insert(tasks, task) end
    end
  end
  return tasks
end

-- ---------------------------------------------------------------------------
-- views (mirror the queries in Tasks.md / Home.md)

local function open_with_due_leq_today(t)
  return t.done == nil and t.due ~= nil and parse_date(t.due) ~= nil
      and parse_date(t.due) < parse_date(today()) + 86400
end

---@return Task[] today/overdue tasks (Home 🔥 Today)
function M.tasks_today()
  local tasks = vim.tbl_filter(open_with_due_leq_today, scan_vault())
  table.sort(tasks, function(a, b)
    if a.path ~= b.path then return a.path < b.path end
    if a.due ~= b.due then return a.due < b.due end
    return a.lnum < b.lnum
  end)
  return tasks
end

---@return Task[] all open tasks
function M.tasks_all()
  local tasks = vim.tbl_filter(function(t) return t.done == nil end, scan_vault())
  table.sort(tasks, function(a, b)
    if a.path ~= b.path then return a.path < b.path end
    local pa, pb = -a.prio, -b.prio
    if pa ~= pb then return pa < pb end
    return a.lnum < b.lnum
  end)
  return tasks
end

---@return Task[] open tasks with no date (👝 Inbox)
function M.tasks_inbox()
  local tasks = vim.tbl_filter(function(t) return t.done == nil and t.due == nil end, scan_vault())
  table.sort(tasks, function(a, b)
    if a.path ~= b.path then return a.path < b.path end
    return a.lnum < b.lnum
  end)
  return tasks
end

---@return Task[] tasks completed in the last 30 days (✅ Completed)
function M.tasks_done()
  local since = days_ago(30)
  local tasks = vim.tbl_filter(function(t)
    return t.done ~= nil and t.done >= since
  end, scan_vault())
  table.sort(tasks, function(a, b)
    if a.done ~= b.done then return a.done > b.done end
    return a.lnum > b.lnum
  end)
  return vim.list_slice(tasks, 1, 30)
end

-- ---------------------------------------------------------------------------
-- telescope picker (or lazylist fallback)

local function make_entry(task)
  return {
    value = task,
    ordinal = table.concat({ task.title, task.path }, " "),
    path = task.path,
    lnum = task.lnum,
    -- NOTE: entry.display MUST return a string — telescope's
    -- entry_display.resolve() skips any entry whose display is not a string
    -- (that showed up as "N results" but an empty list).
    display = function(entry)
      local t = entry.value
      local out = {}
      if t.prio > 0 then
        for emoji, level in pairs(PRIORITY) do
          if level == t.prio then table.insert(out, emoji) end
        end
        table.insert(out, " ")
      end
      table.insert(out, "[ ] ")
      table.insert(out, t.title)
      if t.due then table.insert(out, " 📅 " .. t.due) end
      if t.folder ~= "" then table.insert(out, "  ·  " .. t.folder) end
      return table.concat(out)
    end,
  }
end

M._make_entry = make_entry -- exported for tests/debug

local function open_picker(title, tasks)
  if #tasks == 0 then
    notify("No tasks match: " .. title)
    return
  end
  local ok_telescope, telescope = pcall(require, "telescope")
  if not ok_telescope then
    -- fallback: quickfix list
    local qf = vim.tbl_map(function(t)
      return { filename = t.path, lnum = t.lnum, text = t.title }
    end, tasks)
    vim.fn.setloclist(0, qf, "r", { title = "Obsidian Tasks — " .. title })
    vim.cmd("lopen")
    return
  end
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values -- NOTE: config.clone() was removed in recent telescope
  local opts = {}
  pickers
    .new(opts, {
      prompt_title = "Obsidian Tasks — " .. title,
      finder = finders.new_table({
        results = tasks,
        entry_maker = make_entry,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = previewers.vim_buffer_vimgrep.new(opts),
    })
    :find()
end

-- ---------------------------------------------------------------------------
-- toggling

---Is the given line a task (checkbox) line?
function M.is_task_line(line)
  return line:match("^%s*- %[ %] ") ~= nil
      or line:match("^%s*- %[xX%] ") ~= nil
end

---Call from an `expr` mapping (e.g. obsidian.nvim's `<CR>` action, which runs
---under textlock): if the current line is a task, defer the toggle with
---vim.schedule (else E565) and let the mapping replay nothing.
---@return boolean true if the line was a task (mapping should not fall through)
function M.toggle_if_task()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then return false end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, true)[1] or ""
  if not M.is_task_line(line) then return false end
  vim.schedule(M.toggle_task_line)
  return true
end

---Append ` ✅ YYYY-MM-DD` (byte-compatible with what the Obsidian Tasks
---plugin writes); un-toggling strips the ✅ date and keeps ` 📅`.
function M.toggle_task_line()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then return end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, true)[1] or ""

  local indent, box, rest = line:match("^(%s*)%- %[(.)%] (.*)$")
  if not box then return end
  if box ~= " " and box ~= "x" and box ~= "X" then
    box = nil -- wiki-style `[[]]` links etc. are not checkboxes
  end
  if not box then return end
  local new_line
  if box == "x" or box == "X" then
    -- untoggle → strip the ✅ date, keep the rest (incl. 📅)
    new_line = (indent or "") .. "- [ ] " .. rest:gsub(" ?✅ %d%d%d%d%-%d%d%-%d%d", "")
  else
    -- toggle as done → set box and append the ✅ date (once)
    rest = rest:gsub(" ?✅ %d%d%d%d%-%d%d%-%d%d", "")
    new_line = (indent or "") .. "- [x] " .. rest .. " ✅ " .. today()
  end
  vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, true, { new_line })
end

-- ---------------------------------------------------------------------------
-- setup

local function resolve_root_from_current_buf()
  -- prefer the file in the current buffer; fall back to cwd
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then return find_vault_root(nil) end
  return find_vault_root(bufname)
end

---Wire commands + keymaps. Call once from config (see lua/plugins/obsidian.lua).
function M.setup(opts)
  opts = opts or {}

  -- Commands: work from any buffer, resolving the vault root on the fly
  -- (even before obsidian.nvim lazy-loads).
  vim.api.nvim_create_user_command("ObsidianTasksToday", function()
    M._vault_root = resolve_root_from_current_buf()
    open_picker("Today", M.tasks_today())
  end, { desc = "Obsidian tasks due today or overdue" })

  vim.api.nvim_create_user_command("ObsidianTasksAll", function()
    M._vault_root = resolve_root_from_current_buf()
    open_picker("All open", M.tasks_all())
  end, { desc = "All open Obsidian tasks" })

  vim.api.nvim_create_user_command("ObsidianTasksInbox", function()
    M._vault_root = resolve_root_from_current_buf()
    open_picker("Inbox", M.tasks_inbox())
  end, { desc = "Obsidian tasks with no date (inbox)" })

  vim.api.nvim_create_user_command("ObsidianTasksDone", function()
    M._vault_root = resolve_root_from_current_buf()
    open_picker("Done (30 days)", M.tasks_done())
  end, { desc = "Obsidian tasks done in the last 30 days" })

  vim.api.nvim_create_user_command("ObsidianTaskToggle", function()
    M.toggle_task_line()
  end, { desc = "Toggle the Obsidian task on the current line" })

  -- Buffer-local keymaps inside vault markdown buffers
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("ObsidianTasksKeymaps", { clear = true }),
    pattern = "markdown",
    callback = function(args)
      local buf = args.buf
      local fname = vim.api.nvim_buf_get_name(buf)
      local root = fname ~= "" and find_vault_root(fname) or nil
      if not root then return end
      M._vault_root = root

      -- defer so obsidian.nvim's own buffer-local maps are set first, ours win
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local map = function(lhs, rhs, func_desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, desc = func_desc })
        end

        map("<leader>tt", function()
          M._vault_root = root
          open_picker("Today", M.tasks_today())
        end, "Tasks: today/overdue")
        map("<leader>ta", function()
          M._vault_root = root
          open_picker("All open", M.tasks_all())
        end, "Tasks: all open")
        map("<leader>ti", function()
          M._vault_root = root
          open_picker("Inbox", M.tasks_inbox())
        end, "Tasks: inbox (no date)")
        map("<leader>td", function()
          M._vault_root = root
          open_picker("Done (30 days)", M.tasks_done())
        end, "Tasks: done last 30 days")
        map("<leader>tw", function()
          vim.cmd("edit " .. vim.fn.fnameescape(root .. "/Home.md"))
        end, "Tasks: open Home.md")

        -- NOTE: <CR> and <leader>ch are NOT mapped here. obsidian.nvim
        -- re-registers its `opts.mappings` on every BufEnter, which would
        -- overwrite any buffer-local map set here (making toggles run through
        -- util.toggle_checkbox, which never writes dates). Instead, the
        -- task-aware toggle lives in the mapping actions defined in
        -- lua/plugins/obsidian.lua (see M.toggle_if_task()).
      end)
    end,
  })
end

return M
