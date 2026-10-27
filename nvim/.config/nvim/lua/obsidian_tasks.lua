-- lua/obsidian_tasks.lua
--
-- TickTick-style task views for the capture-ss Obsidian vault in Neovim.
-- Source of truth is the markdown files themselves: the same `- [ ]` lines
-- that the Obsidian Tasks plugin manages. No global filter, no hidden state.
--
-- Conventions parsed (mirrors obsidian-tasks emoji format, Tasks 8.x):
--   [ ] open · [x]/[X] done · [/] in progress
--   📅 YYYY-MM-DD  due date
--   ✅ YYYY-MM-DD  done date (appended automatically on completion here too)
--
-- Pickers: :ObsidianTasksToday / All / Inbox / Done — CR jumps to the line.
-- Homepage: opening nvim inside the vault with no file argument opens Home.md
-- (emulating the Homepage plugin's "open on startup", replace-all mode).

local M = {}

local EPOCH_DAY = 86400
local DOCS = { days = 30 } -- "Done" lookback window

-- ------------------------------------------------------------------ paths

local function vault_dir()
	-- Fast path: obsidian.nvim client already exists (plugin loaded).
	local ok, obsidian = pcall(require, "obsidian")
	if ok then
		local ok2, client = pcall(function() return obsidian.get_client() end)
		if ok2 and client and client.dir then
			return vim.fs.normalize(tostring(client.dir))
		end
	end
	-- Fallback: read the workspace path straight from the lazy spec
	-- (works before obsidian.nvim is loaded, e.g. from any buffer).
	local ok_spec, spec = pcall(require, "plugins.obsidian")
	if ok_spec and spec and spec.opts and spec.opts.workspaces then
		for _, ws in ipairs(spec.opts.workspaces) do
			if ws.path then
				return vim.fs.normalize(vim.fn.expand(ws.path))
			end
		end
	end
	return nil
end

-- ----------------------------------------------------------------- grep

--- Collect all task lines of the vault via ripgrep.
local function collect(vault)
	local argv = {
		"rg",
		"--no-heading",
		"-n",
		"-g", "*.md",
		"-g", "!99 - Templates/**", -- mirrors `path does not include 99 - Templates`
		"-g", "!.trash/**",
		"-e", "^\\s*- \\[[ xX/]\\] ",
		".",
	}
	local res = vim.system(argv, { cwd = vault, text = true }):wait()
	local tasks = {}
	if res.stdout ~= "" then
		for _, ln in ipairs(vim.split(res.stdout, "\n", { trimempty = true })) do
			local rel, lnum, content = ln:match("^(.-):(%d+):(.*)$")
			if rel and lnum then
				local mark, text = content:match("^%s*%- %[(.)%] ?(.*)$")
				if mark then
					tasks[#tasks + 1] = {
						status = mark, -- " " / "x" / "X" / "/"
						text = text,
						due = text:match("📅%s*(%d%d%d%d%-%d%d%-%d%d)"),
						done = text:match("✅%s*(%d%d%d%d%-%d%d%-%d%d)"),
						rel = rel,
						path = vault .. "/" .. rel,
						lnum = tonumber(lnum),
					}
				end
			end
		end
	end
	return tasks
end

local function open_only(t)
	return t.status == " "
end

local function done_only(t)
	return t.status ~= " "
end

-- ----------------------------------------------------------------- picker

local function pick(title, tasks, sort_key)
	local ok, telescope = pcall(require, "telescope")
	if not ok then
		return vim.notify("telescope.nvim is required for task pickers", vim.log.levels.ERROR)
	end
	local pickers = require "telescope.pickers"
	local finders = require "telescope.finders"
	-- NOTE: newer telescope versions removed `config.clone`; `values` is the way
	local conf = require("telescope.config").values
	local actions = require "telescope.actions"
	local action_state = require "telescope.actions.state"
	local previewers = require "telescope.previewers"

	if sort_key == "done" then
		table.sort(tasks, function(a, b)
			if (a.done or "") ~= (b.done or "") then
				return (a.done or "") > (b.done or "")
			end
			return a.rel < b.rel
		end)
	else
		table.sort(tasks, function(a, b)
			if a.rel ~= b.rel then
				return a.rel < b.rel
			end
			if (a.due or "9999") ~= (b.due or "9999") then
				return (a.due or "9999") < (b.due or "9999")
			end
			return a.text < b.text
		end)
	end

	pickers.new({}, {
		prompt_title = title,
		finder = finders.new_table({
			results = tasks,
			entry_maker = function(t)
				return {
					value = t,
					ordinal = t.rel .. " " .. t.text,
					display = string.format("%-28s %s", t.rel, t.text),
					path = t.path,
					lnum = t.lnum,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		previewer = previewers.vim_buffer_vimgrep.new({}),
		attach_mappings = function(prompt_bufnr, _map)
			actions.select_default:replace(function(bufnr)
				local entry = action_state.get_selected_entry()
				actions.close(bufnr)
				if entry then
					local t = entry.value
					vim.cmd("edit " .. vim.fn.fnameescape(t.path))
					vim.api.nvim_win_set_cursor(0, { t.lnum, 0 })
				end
			end)
			return true
		end,
	}):find()
end

-- ----------------------------------------------------------------- public

--- 🔥 Today: open tasks due today or overdue.
function M.today()
	local vault = vault_dir()
	if not vault then
		return vim.notify("obsidian.nvim vault not found", vim.log.levels.ERROR)
	end
	local today = os.date("%Y-%m-%d")
	local out = {}
	for _, t in ipairs(collect(vault)) do
		if open_only(t) and t.due and t.due <= today then
			out[#out + 1] = t
		end
	end
	table.sort(out, function(a, b)
		return a.due < b.due
	end)
	pick("Tasks due today or overdue", out)
end

--- 🗂 All open tasks, grouped by note (folder-as-category inherits naturally).
function M.all()
	local vault = vault_dir()
	if not vault then
		return vim.notify("obsidian.nvim vault not found", vim.log.levels.ERROR)
	end
	local out = {}
	for _, t in ipairs(collect(vault)) do
		if open_only(t) then
			out[#out + 1] = t
		end
	end
	pick("All open tasks (grouped by note)", out)
end

--- 👝 Inbox: open tasks waiting for a due date.
function M.inbox()
	local vault = vault_dir()
	if not vault then
		return vim.notify("obsidian.nvim vault not found", vim.log.levels.ERROR)
	end
	local out = {}
	for _, t in ipairs(collect(vault)) do
		if open_only(t) and not t.due then
			out[#out + 1] = t
		end
	end
	pick("Inbox — tasks waiting for a date", out)
end

--- ✅ Completed in the last 30 days.
function M.done()
	local vault = vault_dir()
	if not vault then
		return vim.notify("obsidian.nvim vault not found", vim.log.levels.ERROR)
	end
	local cutoff = os.date("%Y-%m-%d", os.time() - DOCS.days * EPOCH_DAY)
	local out = {}
	for _, t in ipairs(collect(vault)) do
		if done_only(t) and t.done and t.done >= cutoff then
			out[#out + 1] = t
		end
	end
	pick("Completed in the last 30 days", out, "done")
end

--- Smart action for <CR>: on a task line use the done-date-aware toggle,
--- otherwise defer to obsidian.nvim's smart action (follow links, etc.).
function M.smart_action()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1] or ""
	if line:match("^%s*%- %[(.)%]") then
		-- NOTE: the <CR> mapping is expr=true → the callback runs under
		-- textlock, where nvim_buf_set_lines raises E565 (not allowed to
		-- change text). Defer the edit until after the mapping evaluation.
		-- Also don't return the toggle's result: expr mappings replay their
		-- return value as keystrokes (a boolean would be literally typed).
		vim.schedule(function() M.toggle() end)
		return nil
	end
	local ok, obsidian = pcall(require, "obsidian")
	if ok then
		return obsidian.util.smart_action()
	end
	return nil
end

--- Checkbox toggle that writes a ✅ done date, like the Obsidian Tasks plugin.
--- (Existing due date 📅 and other emoji are left untouched.)
function M.toggle()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)
	local line = lines[1] or ""
	local indent, mark, rest = line:match("^(%s*)%- %[(.)%] ?(.*)$")
	if not indent then
		-- Not a task line: fall back to the plain checkbox toggle from
		-- obsidian.nvim so existing behaviour (e.g. nested / [/-]-symbols)
		-- keeps working.
		local ok, obsidian = pcall(require, "obsidian")
		if ok then
			return obsidian.util.toggle_checkbox()
		end
		return false
	end
	if mark == " " then
		mark = "x"
		rest = rest .. " ✅ " .. os.date("%Y-%m-%d")
	else
		mark = " "
		rest = rest:gsub("%s*✅%s*%d%d%d%d%-%d%d%-%d%d", "")
		rest = rest:gsub("%s+$", "")
	end
	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { indent .. "- [" .. mark .. "] " .. rest })
	return true
end

-- Test helper: returns the filtered task list for a given view without
-- opening a picker.  Not used in normal operation.
function M._list(kind)
	local vault = vault_dir()
	if not vault then
		return nil, "vault not found"
	end
	local today = os.date("%Y-%m-%d")
	local cutoff = os.date("%Y-%m-%d", os.time() - DOCS.days * EPOCH_DAY)
	local out = {}
	for _, t in ipairs(collect(vault)) do
		if kind == "today" and open_only(t) and t.due and t.due <= today then
			out[#out + 1] = t
		elseif kind == "inbox" and open_only(t) and not t.due then
			out[#out + 1] = t
		elseif kind == "all" and open_only(t) then
			out[#out + 1] = t
		elseif kind == "done" and done_only(t) and t.done and t.done >= cutoff then
			out[#out + 1] = t
		end
	end
	return out
end

-- ------------------------------------------------------------------ setup

function M.setup()
	local cmds = {
		{ "ObsidianTasksToday", "today",  "Tasks: today / overdue" },
		{ "ObsidianTasksAll",   "all",    "Tasks: all open, grouped by note" },
		{ "ObsidianTasksInbox", "inbox",  "Tasks waiting for a date" },
		{ "ObsidianTasksDone",  "done",   "Tasks completed in last 30 days" },
		{ "ObsidianTaskToggle", "toggle", "Toggle checkbox on current line (+done date)" },
	}
	for _, c in ipairs(cmds) do
		vim.api.nvim_create_user_command(c[1], function() M[c[2]]() end, { desc = c[3] })
	end

	-- NOTE: intentionally NO auto-open of Home.md on startup: the user's
	-- existing nvim dashboard owns VimEnter inside the vault, and fighting
	-- it caused conflicts. The homepage is a manual action: <leader>tw.
end

return M
