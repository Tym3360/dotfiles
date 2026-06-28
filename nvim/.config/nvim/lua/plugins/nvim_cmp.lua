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

    local complete_with_context_sources = function()
      if is_path_context() then
        cmp.complete({
          config = {
            sources = cmp.config.sources({
              { name = 'path' },
              { name = 'buffer' },
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
            }),
          },
        })
      else
        cmp.complete()
      end
    end

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  -- Disable auto-completion globally, only trigger manually with Tab
  completion = {
    autocomplete = false,
    completeopt = 'menu,menuone,noinsert',
  },
  preselect = cmp.PreselectMode.Item,
  
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({
      select = true,
      behavior = cmp.ConfirmBehavior.Replace,
    }),
    
    -- Tab: trigger completion or navigate/expand snippets
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      elseif has_words_before() then
        complete_with_context_sources()
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
    { name = 'buffer' },
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

-- Filetype config for markdown: add obsidian sources but keep autocomplete disabled
-- (we trigger manually via autocmd below for specific characters)
cmp.setup.filetype('markdown', {
  sources = cmp.config.sources({
    { name = 'obsidian' },
    { name = 'obsidian_new' },
    { name = 'obsidian_tags' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  }),
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
