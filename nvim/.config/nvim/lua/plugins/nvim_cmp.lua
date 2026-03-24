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

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  -- Disable auto-completion globally, only trigger manually with Tab
  completion = {
    autocomplete = false,
  },
  
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    
    -- Tab: trigger completion or navigate/expand snippets
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        cmp.complete()
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

-- Auto-trigger completion for obsidian wiki links [[ and tags #
-- Only in markdown files within the Obsidian vault
vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = "*.md",
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before_cursor = line:sub(1, col)
    
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
