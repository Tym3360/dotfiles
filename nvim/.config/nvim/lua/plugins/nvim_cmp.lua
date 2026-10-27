return{
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'rafamadriz/friendly-snippets', -- optional: pre-made snippets
  },
  config = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    local types = require('cmp.types')
    
    -- Helper function to detect Arduino/PlatformIO files
    local function is_arduino_file()
      local filetype = vim.bo.filetype
      if filetype == 'arduino' then return true end
      if filetype == 'cpp' or filetype == 'c' then
        local filename = vim.fn.expand('%:p')
        return filename:match('%.ino$') ~= nil 
            or filename:match('platformio%.ini') ~= nil
            or filename:match('%.pio/') ~= nil
      end
      return false
    end

    local has_words_before = function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      if col == 0 then
        return false
      end
      local current_line = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
      return current_line:sub(col, col):match('%s') == nil
    end

    local get_before_cursor = function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      local current_line = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1] or ''
      return current_line:sub(1, col)
    end

    local is_path_context = function()
      local before = get_before_cursor()
      if before:match('\\input%s*{[^}]*$')
        or before:match('\\include%s*{[^}]*$')
        or before:match('\\includegraphics%s*%b[]%s*{[^}]*$')
        or before:match('\\includegraphics%s*{[^}]*$')
        or before:match('\\bibliography%s*{[^}]*$')
        or before:match('\\addbibresource%s*{[^}]*$')
        or before:match('\\subfile%s*{[^}]*$') then
        return true
      end
      return before:match('[%w%._%-%~/]+/[%w%._%-%~/]*$') ~= nil
    end

    local is_function_context = function()
      local before = get_before_cursor()
      return before:match('^%s*function%s+[%w_]*$') ~= nil
        or before:match('^%s*def%s+[%w_]*$') ~= nil
        or before:match('[%w_%.:]+%(%s*[%w_]*$') ~= nil
    end

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  -- Disable ALL auto-completion globally, ONLY trigger manually with Tab
  completion = {
    autocomplete = false,
    completeopt = 'menu,menuone,noinsert',
    keyword_length = 1,
  },
  preselect = cmp.PreselectMode.Item,
  -- Only prefix/substring matches. Without this, `pri` also drags in
  -- PartialEq, ParentDir, park_timeout_ms... via subsequence matching.
  matching = { disallow_fuzzy_matching = true },
  
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    -- Enter: confirm the selection when the menu is open, insert a newline
    -- otherwise. (Explicit guard so a closed menu can never accept an
    -- implicit first item.)
    -- NOTE: cmp.core:confirm is called directly instead of the cmp.confirm
    -- wrapper: the wrapper unconditionally re-runs cmp.core:complete with
    -- reason TriggerOnly after every confirm, which re-opens the menu without
    -- a Tab press (very visible in prose/markdown). Confirming via core keeps
    -- the menu closed until Tab (or <C-Space>) is pressed again.
    ['<CR>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        local entry = cmp.core.view:get_selected_entry()
          or cmp.core.view:get_first_entry()
        if entry then
          cmp.core:confirm(entry, {
            behavior = cmp.ConfirmBehavior.Replace,
          })
          return
        end
        cmp.confirm({
          select = true,
          behavior = cmp.ConfirmBehavior.Replace,
        }, function()
          -- Fallback path (wrapper) also re-triggers: close the session.
          vim.schedule(cmp.abort)
        end)
      else
        fallback()
      end
    end, { 'i', 'c' }),
    
    -- Tab: completion first, then snippet navigation. Inside a snippet
    -- placeholder Tab jumps to the next placeholder; it never expands a
    -- snippet trigger (pick snippets from the menu instead).
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      elseif has_words_before() then
        cmp.complete()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer', option = { keyword_length = 2 } },
    { name = 'path' },
  }),
  sorting = {
    comparators = {
      function(entry1, entry2)
        if is_path_context() then
          local e1_path = entry1.source.name == 'path'
          local e2_path = entry2.source.name == 'path'
          if e1_path ~= e2_path then
            return e1_path
          end
        elseif is_function_context() then
          local function_kinds = {
            [types.lsp.CompletionItemKind.Function] = true,
            [types.lsp.CompletionItemKind.Method] = true,
          }
          local e1_fn = function_kinds[entry1:get_kind()] or false
          local e2_fn = function_kinds[entry2:get_kind()] or false
          if e1_fn ~= e2_fn then
            return e1_fn
          end
        end
      end,
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
})

-- Filetype config for Arduino/PlatformIO: prioritize LSP completions
cmp.setup.filetype({ 'cpp', 'c', 'arduino' }, {
  completion = {
    autocomplete = false,  -- ONLY trigger on Tab keypress
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp', priority = 100 },  -- LSP completions first
    { name = 'luasnip', priority = 90 },
    { name = 'buffer', priority = 80, option = { keyword_length = 2 } },
    { name = 'path', priority = 70 },
  }),
  sorting = {
    comparators = {
      -- Prioritize Arduino-specific completions
      function(entry1, entry2)
        local function_kind = types.lsp.CompletionItemKind.Function
        local variable_kind = types.lsp.CompletionItemKind.Variable
        local snippet_kind = types.lsp.CompletionItemKind.Snippet
        
        -- Prioritize functions (Arduino functions like digitalWrite)
        if entry1:get_kind() == function_kind and entry2:get_kind() ~= function_kind then
          return true
        end
        if entry2:get_kind() == function_kind and entry1:get_kind() ~= function_kind then
          return false
        end
        
        return nil
      end,
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
})

-- Filetype config for markdown: add obsidian sources but keep autocomplete disabled
-- (we trigger manually via autocmd below for specific characters)
cmp.setup.filetype('markdown', {
  sources = cmp.config.sources({
    { name = 'obsidian' },
    { name = 'obsidian_new' },
    { name = 'obsidian_tags' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer', option = { keyword_length = 2 } },
    { name = 'path' },
  }),
})

-- Auto-trigger completion while typing inside LuaSnip snippet placeholders.
-- Tab stays reserved for jumping between placeholders, so completion inside a
-- snippet must come automatically while typing (VSCode-style behaviour).
-- Outside snippets nothing auto-triggers: Tab opens the menu manually.
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    local ls = require("luasnip")
    -- Only inside an active snippet, and only when there is a typed prefix
    -- worth completing (>= 2 word chars, avoids popping on every keystroke).
    if not ls.in_snippet() then
      return
    end
    local cmp = require("cmp")
    if cmp.visible() then
      return
    end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local before_cursor = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(1, col)
    local prefix = before_cursor:match("[%w_]+$") or ""
    if #prefix >= 2 then
      cmp.complete()
    end
  end,
})

-- Auto-trigger completion for LaTeX specific commands
vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = {"*.tex", "*.latex", "*.bib"},
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before_cursor = line:sub(1, col)
    
    if before_cursor:match('\\input%s*{[^}]*$')
      or before_cursor:match('\\include%s*{[^}]*$')
      or before_cursor:match('\\includegraphics%s*%b[]%s*{[^}]*$')
      or before_cursor:match('\\includegraphics%s*{[^}]*$')
      or before_cursor:match('\\bibliography%s*{[^}]*$')
      or before_cursor:match('\\addbibresource%s*{[^}]*$')
      or before_cursor:match('\\subfile%s*{[^}]*$')
      or before_cursor:match('\\cite%w*%s*{[^}]*$')
      or before_cursor:match('\\ref%w*%s*{[^}]*$') then
      require('cmp').complete()
    end
  end,
})

-- Auto-trigger completion for obsidian wiki links [[ and tags #
-- Only in markdown files within the Obsidian vault
vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = "*.md",
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before_cursor = line:sub(1, col + 1)
    
    -- Check if we're in the Obsidian vault
    local filepath = vim.fn.expand("%:p")
    if not filepath:match("Obsidian Tym") then
      return
    end
    
    -- Trigger completion for [[ (wiki links) or # (tags)
    if before_cursor:match("%[%[$") or before_cursor:match("%[%[[^%]]+$") or before_cursor:match("#[%w_-]*$") then
      cmp.complete()
    end
  end,
})
  end
}
