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
      enable_autosnippets = true,
      ext_opts = {
        [require("luasnip.util.types").choiceNode] = {
          active = {
            virt_text = { { "●", "GruvboxOrange" } },
          },
        },
      },
    })

    -- Load friendly-snippets
    require("luasnip.loaders.from_vscode").lazy_load()

    -- Custom LaTeX snippets
    ls.add_snippets("tex", {
      -- Begin/End environment
      s("beg", {
        t("\\begin{"), i(1, "environment"), t("}"),
        t({"", "\t"}), i(0),
        t({"", "\\end{"}), f(function(args) return args[1][1] end, {1}), t("}"),
      }),
      
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
      
      -- Align environment
      s("ali", {
        t({"\\begin{align}", "\t"}), i(1),
        t({"", "\\end{align}"}), i(0)
      }),
      
      -- Fraction
      s("frac", {
        t("\\frac{"), i(1), t("}{"), i(2), t("}"), i(0)
      }),
      
      -- Section
      s("sec", {
        t("\\section{"), i(1), t("}"),
        t({"", ""}), i(0)
      }),
      
      -- Subsection
      s("ssec", {
        t("\\subsection{"), i(1), t("}"),
        t({"", ""}), i(0)
      }),
      
      -- Subsubsection
      s("sssec", {
        t("\\subsubsection{"), i(1), t("}"),
        t({"", ""}), i(0)
      }),
      
      -- Figure environment
      s("fig", {
        t({"\\begin{figure}[htbp]", "\t\\centering"}),
        t({"", "\t\\includegraphics[width="}), i(1, "0.8"), t("\\textwidth]{"), i(2, "image"), t("}"),
        t({"", "\t\\caption{"}), i(3, "caption"), t("}"),
        t({"", "\t\\label{fig:"}), i(4, "label"), t("}"),
        t({"", "\\end{figure}"}), i(0)
      }),
      
      -- Table environment
      s("tab", {
        t({"\\begin{table}[htbp]", "\t\\centering"}),
        t({"", "\t\\caption{"}), i(1, "caption"), t("}"),
        t({"", "\t\\label{tab:"}), i(2, "label"), t("}"),
        t({"", "\t\\begin{tabular}{"}), i(3, "c c c"), t("}"),
        t({"", "\t\t\\toprule"}),
        t({"", "\t\t"}), i(4, "Header 1"), t(" & "), i(5, "Header 2"), t(" \\\\"),
        t({"", "\t\t\\midrule"}),
        t({"", "\t\t"}), i(0),
        t({"", "\t\t\\bottomrule"}),
        t({"", "\t\\end{tabular}"}),
        t({"", "\\end{table}"}),
      }),
      
      -- Itemize
      s("item", {
        t({"\\begin{itemize}", "\t\\item "}), i(1),
        t({"", "\\end{itemize}"}), i(0)
      }),
      
      -- Enumerate
      s("enum", {
        t({"\\begin{enumerate}", "\t\\item "}), i(1),
        t({"", "\\end{enumerate}"}), i(0)
      }),
      
      -- Description
      s("desc", {
        t({"\\begin{description}", "\t\\item["}), i(1, "term"), t("] "), i(2),
        t({"", "\\end{description}"}), i(0)
      }),
      
      -- Text formatting
      s("bf", {
        t("\\textbf{"), i(1), t("}"), i(0)
      }),
      
      s("it", {
        t("\\textit{"), i(1), t("}"), i(0)
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
      
      -- Matrices
      s("mat", {
        t({"\\begin{bmatrix}", "\t"}), i(1),
        t({"", "\\end{bmatrix}"}), i(0)
      }),
      
      s("pmat", {
        t({"\\begin{pmatrix}", "\t"}), i(1),
        t({"", "\\end{pmatrix}"}), i(0)
      }),
      
      -- Theorem-like environments
      s("thm", {
        t({"\\begin{theorem}", "\t"}), i(1),
        t({"", "\\end{theorem}"}), i(0)
      }),
      
      s("lem", {
        t({"\\begin{lemma}", "\t"}), i(1),
        t({"", "\\end{lemma}"}), i(0)
      }),
      
      s("proof", {
        t({"\\begin{proof}", "\t"}), i(1),
        t({"", "\\end{proof}"}), i(0)
      }),
      
      -- Citation and reference
      s("cite", {
        t("\\cite{"), i(1), t("}"), i(0)
      }),
      
      s("ref", {
        t("\\ref{"), i(1), t("}"), i(0)
      }),
      
      s("eqref", {
        t("\\eqref{"), i(1), t("}"), i(0)
      }),
    })

    -- Keymaps for LuaSnip
    vim.keymap.set({"i", "s"}, "<C-k>", function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true, desc = "LuaSnip: Expand or jump forward" })

    vim.keymap.set({"i", "s"}, "<C-j>", function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true, desc = "LuaSnip: Jump backward" })

    vim.keymap.set("i", "<C-l>", function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end, { silent = true, desc = "LuaSnip: Change choice" })
  end,
}
