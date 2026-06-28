local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local events = require("luasnip.util.events")

local function trigger_path_cmp()
  vim.defer_fn(function()
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.complete()
    end
  end, 50)
end

-- Helper function for math context
local tex = {}
tex.in_mathzone = function()
  return vim.fn['vimtex#syntax#in_mathzone']() == 1
end
tex.in_text = function()
  return not tex.in_mathzone()
end

-- Auto snippets
local autosnippets = {
  -- Inline math
  s({trig = "mk", snippetType = "autosnippet"},
    fmta("$<>$", {i(1)}),
    {condition = tex.in_text}
  ),
  
  -- Display math
  s({trig = "dm", snippetType = "autosnippet"},
    fmta(
[[
\[
  <>
\]
]], {i(1)}),
    {condition = tex.in_text}
  ),

  -- Fractions
  s({trig = "//", snippetType = "autosnippet"},
    fmta("\\frac{<>}{<>}", {i(1), i(2)}),
    {condition = tex.in_mathzone}
  ),

  -- Superscript
  s({trig = "sr", regTrig = true, snippetType = "autosnippet"},
    fmta("<>^{<>}", {f(function(_, snip) return snip.captures[1] end), i(1)}),
    {condition = tex.in_mathzone}
  ),

  -- Subscript
  s({trig = "([%a%)%]%}])_", regTrig = true, snippetType = "autosnippet"},
    fmta("<>_{<>}", {f(function(_, snip) return snip.captures[1] end), i(1)}),
    {condition = tex.in_mathzone}
  ),

  -- Square root
  s({trig = "sq", snippetType = "autosnippet"},
    fmta("\\sqrt{<>}", {i(1)}),
    {condition = tex.in_mathzone}
  ),

  -- Sum
  s({trig = "sum", snippetType = "autosnippet"},
    fmta("\\sum_{<>}^{<>}", {i(1, "i=1"), i(2, "n")}),
    {condition = tex.in_mathzone}
  ),

  -- Integral
  s({trig = "int", snippetType = "autosnippet"},
    fmta("\\int_{<>}^{<>}", {i(1), i(2)}),
    {condition = tex.in_mathzone}
  ),

  -- Limit
  s({trig = "lim", snippetType = "autosnippet"},
    fmta("\\lim_{<> \\to <>}", {i(1, "n"), i(2, "\\infty")}),
    {condition = tex.in_mathzone}
  ),

  -- Greek letters (common ones)
  s({trig = ";a", snippetType = "autosnippet"}, t("\\alpha"), {condition = tex.in_mathzone}),
  s({trig = ";b", snippetType = "autosnippet"}, t("\\beta"), {condition = tex.in_mathzone}),
  s({trig = ";g", snippetType = "autosnippet"}, t("\\gamma"), {condition = tex.in_mathzone}),
  s({trig = ";d", snippetType = "autosnippet"}, t("\\delta"), {condition = tex.in_mathzone}),
  s({trig = ";e", snippetType = "autosnippet"}, t("\\epsilon"), {condition = tex.in_mathzone}),
  s({trig = ";t", snippetType = "autosnippet"}, t("\\theta"), {condition = tex.in_mathzone}),
  s({trig = ";l", snippetType = "autosnippet"}, t("\\lambda"), {condition = tex.in_mathzone}),
  s({trig = ";m", snippetType = "autosnippet"}, t("\\mu"), {condition = tex.in_mathzone}),
  s({trig = ";p", snippetType = "autosnippet"}, t("\\pi"), {condition = tex.in_mathzone}),
  s({trig = ";s", snippetType = "autosnippet"}, t("\\sigma"), {condition = tex.in_mathzone}),
  s({trig = ";o", snippetType = "autosnippet"}, t("\\omega"), {condition = tex.in_mathzone}),

  -- Parentheses
  s({trig = "lr(", snippetType = "autosnippet"},
    fmta("\\left( <> \\right)", {i(1)}),
    {condition = tex.in_mathzone}
  ),
  
  s({trig = "lr[", snippetType = "autosnippet"},
    fmta("\\left[ <> \\right]", {i(1)}),
    {condition = tex.in_mathzone}
  ),
  
  s({trig = "lr{", snippetType = "autosnippet"},
    fmta("\\left\\{ <> \\right\\}", {i(1)}),
    {condition = tex.in_mathzone}
  ),

  -- Text in math mode
  s({trig = "tt", snippetType = "autosnippet"},
    fmta("\\text{<>}", {i(1)}),
    {condition = tex.in_mathzone}
  ),
}

local function create_label(args)
  local text = args[1][1] or ""
  -- Replace accented characters
  text = text:gsub("é", "e"):gsub("è", "e"):gsub("ê", "e"):gsub("ë", "e")
  text = text:gsub("à", "a"):gsub("â", "a"):gsub("ä", "a")
  text = text:gsub("î", "i"):gsub("ï", "i")
  text = text:gsub("ô", "o"):gsub("ö", "o")
  text = text:gsub("ù", "u"):gsub("û", "u"):gsub("ü", "u")
  text = text:gsub("ç", "c")
  text = text:gsub("É", "E"):gsub("È", "E"):gsub("Ê", "E"):gsub("Ë", "E")
  text = text:gsub("À", "A"):gsub("Â", "A"):gsub("Ä", "A")
  text = text:gsub("Î", "I"):gsub("Ï", "I")
  text = text:gsub("Ô", "O"):gsub("Ö", "O")
  text = text:gsub("Ù", "U"):gsub("Û", "U"):gsub("Ü", "U")
  text = text:gsub("Ç", "C")
  -- Convert to lowercase
  text = text:lower()
  -- Replace any non-alphanumeric character with underscore
  text = text:gsub("[^%w]+", "_")
  -- Remove leading/trailing underscores
  text = text:gsub("^_", ""):gsub("_$", "")
  return text
end

-- Regular snippets
local snippets = {
  -- Document templates
  s("template",
    fmta(
[[
\documentclass{<>}

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{amsmath, amssymb, amsthm}
\usepackage{graphicx}
\usepackage{hyperref}

\title{<>}
\author{<>}
\date{<>}

\begin{document}

\maketitle

<>

\end{document}
]], {
  c(1, {t("article"), t("report"), t("book")}),
  i(2, "Title"),
  i(3, "Author"),
  i(4, "\\today"),
  i(0)
})),

  -- Sections & Chapters
  s("part", fmta(
[[
\part{<>}\label{prt:<>} % (fold)

% part <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
  s("cha", fmta(
[[
\chapter{<>}\label{chap:<>} % (fold)

% chapter <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
  s("sec", fmta(
[[
\section{<>}\label{sec:<>} % (fold)

% section <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
  s("ssec", fmta(
[[
\subsection{<>}\label{sub:<>} % (fold)

% subsection <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
  s("sssec", fmta(
[[
\subsubsection{<>}\label{ssub:<>} % (fold)

% subsubsection <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
  s("par", fmta(
[[
\paragraph{<>}\label{par:<>} % (fold)

% paragraph <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
  s("subp", fmta(
[[
\subparagraph{<>}\label{subp:<>} % (fold)

% subparagraph <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),

  -- Environments
  s("beg",
    fmta(
[[
\begin{<>}
  <>
\end{<>}
]], {i(1, "environment"), i(2), rep(1)})),

  s("enum",
    fmta(
[[
\begin{enumerate}
  \item <>
\end{enumerate}
]], {i(1)})),

  s("item",
    fmta(
[[
\begin{itemize}
  \item <>
\end{itemize}
]], {i(1)})),

  -- Theorem environments
  s("thm",
    fmta(
[[
\begin{theorem}
  <>
\end{theorem}
]], {i(1)})),

  s("lem",
    fmta(
[[
\begin{lemma}
  <>
\end{lemma}
]], {i(1)})),

  s("proof",
    fmta(
[[
\begin{proof}
  <>
\end{proof}
]], {i(1)})),

  s("def",
    fmta(
[[
\begin{definition}
  <>
\end{definition}
]], {i(1)})),

  -- Figures
  s("fig",
    fmta(
[[
\begin{figure}[<>]
  \centering
  \includegraphics[width=<>\textwidth]{<>}
  \caption{<>}
  \label{fig:<>}
\end{figure}
]], {
  i(1, "htbp"),
  i(2, "0.8"),
  i(3, "", { callbacks = { [-1] = { [events.enter] = trigger_path_cmp } } }),
  i(4, "Caption"),
  f(create_label, {4})
})),

  -- Tables
  s("tab",
    fmta(
[[
\begin{table}[<>]
  \centering
  \begin{tabular}{<>}
    \hline
    <> \\
    \hline
  \end{tabular}
  \caption{<>}
  \label{tab:<>}
\end{table}
]], {
  i(1, "htbp"),
  i(2, "c|c"),
  i(3),
  i(4, "Caption"),
  f(create_label, {4})
})),

  -- Matrix
  s("mat",
    fmta(
[[
\begin{<>matrix}
  <>
\end{<>matrix}
]], {
  c(1, {t(""), t("p"), t("b"), t("B"), t("v"), t("V")}),
  i(2),
  rep(1)
})),

  -- Align environment
  s("ali",
    fmta(
[[
\begin{align<>}
  <>
\end{align<>}
]], {
  c(1, {t(""), t("*")}),
  i(2),
  rep(1)
})),

  -- Cases
  s("cases",
    fmta(
[[
\begin{cases}
  <>, & \text{if } <> \\
  <>, & \text{otherwise}
\end{cases}
]], {i(1), i(2), i(3)})),

  -- Bold, italic, emphasis
  s("bf", fmta("\\textbf{<>}", {i(1)})),
  s("it", fmta("\\textit{<>}", {i(1)})),
  s("em", fmta("\\emph{<>}", {i(1)})),

  -- References
  s("ref", fmta("\\ref{<>}", {i(1)})),
  s("cite", fmta("\\cite{<>}", {i(1)})),
  s("lab", fmta("\\label{<>}", {i(1)})),
  -- Alternate triggers to match friendly-snippets
  s("sub", fmta(
[[
\subsection{<>}\label{sub:<>} % (fold)

% subsection <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
  s("subs", fmta(
[[
\subsubsection{<>}\label{ssub:<>} % (fold)

% subsubsection <> (end)
]], {i(1), f(create_label, {1}), rep(1)})),
}

return snippets, autosnippets
