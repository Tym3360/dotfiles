return {
  "lervag/vimtex",
  lazy = false,
  config = function()
    -- Use zathura as viewer
    vim.g.vimtex_view_method = "skim"
    vim.g.tex_flavor = 'latex'

    -- Compiler settings
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_compiler_latexmk = {
      build_dir = '',
      callback = 1,
      continuous = 1,
      executable = 'latexmk',
      options = {
        '-pdf',
        '-verbose',
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
      },
    }


    -- Auto-open viewer
    vim.g.vimtex_view_automatic = 1

    -- Quickfix settings
    vim.g.vimtex_quickfix_mode = 1
    vim.g.vimtex_quickfix_ignore_filters = {
      'Underfull',
      'Overfull',
      'specifier changed to',
      'Token not allowed in a PDF string',
    }

    -- Disable imaps
    vim.g.vimtex_imaps_enabled = 0
    vim.g.vimtex_syntax_enabled = 0
  end,
}
