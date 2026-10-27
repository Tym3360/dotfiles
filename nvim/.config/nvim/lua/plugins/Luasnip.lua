-- File: ~/.config/nvim/lua/plugins/luasnip.lua

return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  build = "make install_jsregexp", -- optional, for advanced regex support
  dependencies = {
    "rafamadriz/friendly-snippets", -- optional: collection of pre-made snippets
  },
  config = function()
    local ls = require("luasnip")
    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node
    local f = ls.function_node
    local c = ls.choice_node
    local d = ls.dynamic_node
    local sn = ls.snippet_node
    -- LuaSnip configuration
    ls.config.set_config({
      history = true, -- keep around last snippet local to jump back
      updateevents = "TextChanged,TextChangedI", -- update changes as you type
      enable_autosnippets = false,
      ext_opts = {
        [require("luasnip.util.types").choiceNode] = {
          active = {
            virt_text = { { "●", "GruvboxOrange" } },
          },
        },
      },
    })

    -- Load friendly-snippets
    require("luasnip.loaders.from_vscode").lazy_load({ exclude = { "latex", "tex" } })

    local function trigger_path_cmp()
      vim.defer_fn(function()
        local ok, cmp = pcall(require, "cmp")
        if ok then
          cmp.complete()
        end
      end, 50)
    end

    -- Load custom snippets from ~/.config/nvim/LuaSnip/
    require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/LuaSnip"})

    -- Custom LaTeX snippets.
    -- Triggers also defined in LuaSnip/tex.lua (ali, beg, bf, cite, enum, it,
    -- item, lem, mat, proof, ref, tab, thm) are intentionally NOT duplicated
    -- here -- that file is the canonical definition and its versions are
    -- better (e.g. `rep(1)` keeps \end{} in sync with \begin{}).
    ls.add_snippets("tex", {
      -- Inline math
      s("mm", {
        t("$"), i(1), t("$"), i(0)
      }),

      -- Display math
      s("dm", {
        t({"\\[", "\t"}), i(1),
        t({"", "\\]"}), i(0)
      }),

      -- Equation environment
      s("eq", {
        t({"\\begin{equation}", "\t"}), i(1),
        t({"", "\\end{equation}"}), i(0)
      }),

      -- Fraction
      s("frac", {
        t("\\frac{"), i(1), t("}{"), i(2), t("}"), i(0)
      }),

      -- Section
      s("sec2", {
        t("\\section{"), i(1), t("}"),
        t({"", ""}), i(0)
      }),

      -- Subsection
      s("ssec2", {
        t("\\subsection{"), i(1), t("}"),
        t({"", ""}), i(0)
      }),

      -- Subsubsection
      s("sssec2", {
        t("\\subsubsection{"), i(1), t("}"),
        t({"", ""}), i(0)
      }),

      -- Figure environment
      s("fig2", {
        t({"\\begin{figure}[htbp]", "\t\\centering"}),
        t({"", "\t\\includegraphics[width="}), i(1, "0.8"), t("\\textwidth]{"), i(2, "", { callbacks = { [-1] = { [require("luasnip.util.events").enter] = trigger_path_cmp } } }), t("}"),
        t({"", "\t\\caption{"}), i(3, "caption"), t("}"),
        t({"", "\t\\label{fig:"}), i(4, "label"), t("}"),
        t({"", "\\end{figure}"}), i(0)
      }),

      -- Description
      s("desc", {
        t({"\\begin{description}", "\t\\item["}), i(1, "term"), t("] "), i(2),
        t({"", "\\end{description}"}), i(0)
      }),

      s("tt", {
        t("\\texttt{"), i(1), t("}"), i(0)
      }),

      -- Greek letters (common ones)
      s("alpha", { t("\\alpha") }),
      s("beta", { t("\\beta") }),
      s("gamma", { t("\\gamma") }),
      s("delta", { t("\\delta") }),
      s("eps", { t("\\epsilon") }),
      s("theta", { t("\\theta") }),
      s("lambda", { t("\\lambda") }),
      s("mu", { t("\\mu") }),
      s("sigma", { t("\\sigma") }),
      s("omega", { t("\\omega") }),

      -- Common math operators
      s("sum", {
        t("\\sum_{"), i(1, "i=1"), t("}^{"), i(2, "n"), t("} "), i(0)
      }),

      s("int", {
        t("\\int_{"), i(1, "a"), t("}^{"), i(2, "b"), t("} "), i(3), t(" \\, d"), i(4, "x"), i(0)
      }),

      s("lim", {
        t("\\lim_{"), i(1, "x \\to \\infty"), t("} "), i(0)
      }),

      s("pmat", {
        t({"\\begin{pmatrix}", "\t"}), i(1),
        t({"", "\\end{pmatrix}"}), i(0)
      }),

      -- Citation and reference
      s("eqref", {
        t("\\eqref{"), i(1), t("}"), i(0)
      }),
    })

    -- Snippet keys. These are the ONLY things that touch snippets, so <Tab>
    -- is free to mean "complete" and nothing else.
    -- <C-k>: expand the trigger at the cursor, or advance to the next
    --        placeholder of the current snippet.
    vim.keymap.set({"i", "s"}, "<C-k>", function()
      if ls.expand_or_locally_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true, desc = "LuaSnip: Expand or jump forward" })

    -- <C-j>: back to the previous placeholder.
    vim.keymap.set({"i", "s"}, "<C-j>", function()
      if ls.locally_jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true, desc = "LuaSnip: Jump backward" })

    -- <C-l>: step past a closing bracket/quote and stay in insert mode, so
    -- after accepting "println!()" you can type ";" without <Esc>. Cycles a
    -- snippet choice node instead when one is active.
    local CLOSERS = { [")"] = true, ["]"] = true, ["}"] = true, ['"'] = true, ["'"] = true, ["`"] = true }
    vim.keymap.set("i", "<C-l>", function()
      if ls.choice_active() then
        ls.change_choice(1)
        return
      end
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local ch = vim.api.nvim_get_current_line():sub(col + 1, col + 1)
      if CLOSERS[ch] then
        vim.api.nvim_win_set_cursor(0, { row, col + 1 })
      end
    end, { silent = true, desc = "Step out of closing bracket / cycle choice" })
  end,
}
