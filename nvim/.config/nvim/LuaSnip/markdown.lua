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

-- Regular snippets
local snippets = {
  -- Team scoring template
  s("equipe",
    fmt(
      [[Equipe {} : {}/9 
1. {}
2. {}
3. {}]], {
        i(1, "?"),  -- Team name/letter
        i(2, "9"),  -- Score nominator
        i(3, "TB"),  -- First point comment
        i(4, "TB"),  -- Second point comment
        i(5, "TB"),  -- Third point comment
      })
  ),
}

-- Auto snippets
local autosnippets = {}

return snippets, autosnippets
