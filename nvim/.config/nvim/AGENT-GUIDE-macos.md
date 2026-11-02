# Reproducing the Neovim completion + snippet workflow on macOS

A handoff guide for an AI agent. It is self-contained: you do not need the
conversation that produced it. Follow it top to bottom and finish with the
verification checklist in §6.

Target machine: macOS, MacBook Pro. Source machine: Linux, Neovim 0.12.5.

---

## 0. Objective

By the end, Neovim must behave like this:

| Key | Mode | Behaviour |
|---|---|---|
| `<Tab>` | insert | Open the completion menu. If already open, move to the next item. **Never** expands a snippet. |
| `<S-Tab>` | insert | Move to the previous completion item. |
| `<CR>` | insert | Accept the selected completion. |
| `<C-Space>` | insert | Open the completion menu. |
| `<C-e>` | insert | Close the completion menu. |
| `<C-k>` | insert/select | Expand the snippet trigger before the cursor, or jump to the next snippet field. On the last field it exits the snippet. |
| `<C-j>` | insert/select | Jump back to the previous snippet field. |
| `<C-l>` | insert | Step past a closing `)` `]` `}` `"` `'` `` ` `` in front of the cursor and stay in insert mode. Cycles a snippet choice when one is active. |

Canonical flow that must work in a Rust project:

```
type: pri → <Tab> → <Tab> → <CR> → <C-l> → type: ;
```

must produce `println!();` with no `<Esc>` anywhere.

Two behavioural rules:

1. **No autosnippets.** Nothing expands while typing. `mk` stays `mk` until
   `<C-k>`.
2. **Snippets and completion never share a key.** Tab is completion only.

---

## 1. Preconditions

Verify each of these before editing anything:

```bash
nvim --version | head -1      # must be >= 0.12 (0.12.5 on the source machine)
git --version
rg --version
node --version                # needed by some LSPs / treesitter
python3 --version
```

Neovim **must be >= 0.12**:
- `rustaceanvim` v9 (`^9`) refuses to load below 0.12.
- `vim.lsp.config('*', ...)` is used for global LSP capabilities.

If `nvim` is older:

```bash
brew upgrade neovim || brew install neovim
nvim --version | head -1
```

Toolchain (install if missing):

```bash
brew install ripgrep fd node python clang-format
rustup component add rust-analyzer rust-src rustfmt clippy
```

Important: **rust-analyzer must come from rustup, not Mason.** A Mason
rust-analyzer that does not match the project's toolchain causes hard-to-debug
failures. The config deliberately does not install it via Mason.

LSP servers are installed by `mason-lspconfig` on first launch:
`lua_ls`, `pylsp`, `texlab`, `arduino_language_server`, `clangd`.

---

## 2. Locate the config

The source machine has `~/.config/nvim` as a symlink into a dotfiles repo:

```bash
ls -l ~/.config/nvim
# -> lrwxrwxrwx ... /home/cart1503/.config/nvim -> ../dotfiles/nvim/.config/nvim
```

On the Mac, find the real directory and export it:

```bash
INIT=$(python3 -c "import os;print(os.path.realpath(os.path.expanduser('~/.config/nvim')))")
echo "$INIT"
CFG=$(dirname "$INIT")          # this is the directory that contains init.lua
echo "CFG=$CFG"
```

Sanity check: `ls "$CFG/init.lua"` must succeed. Everything below uses `$CFG`.
Keep the shell exported (`export CFG`) if you run commands in separate shells.

Then decide which path you are on:

- **Path A — the dotfiles repo is already synced to this Mac.**
  Check whether the fixes are present:

  ```bash
  grep -c '{baud}'  "$CFG/LuaSnip/arduino.lua"          # expect 0  (bug present if 2)
  grep -c 'snippetType' "$CFG/LuaSnip/tex.lua"          # expect 0
  grep -c 'disallow_fuzzy_matching' "$CFG/lua/plugins/nvim_cmp.lua"  # expect 1
  ```

  If all three already match, skip §3–§5 and go straight to §6.

- **Path B — starting from the pre-fix state.** Apply §3, §4 and §5.

Back up before editing:

```bash
mkdir -p /tmp/nvim-backup
cp "$CFG/LuaSnip/arduino.lua" "$CFG/LuaSnip/tex.lua" \
   "$CFG/lua/plugins/Luasnip.lua" "$CFG/lua/plugins/nvim_cmp.lua" \
   "$CFG/lua/plugins/lsp-config.lua" /tmp/nvim-backup/
```

---

## 3. Fix the broken snippet library (highest priority)

### 3.1 The bug

`$CFG/LuaSnip/arduino.lua` has two independent defects:

1. **A Lua syntax error** — two `s(...)` calls are missing a closing paren, so
   the file fails to compile.
2. **A runtime error** — two `fmt(...)` templates reference `{baud}` but no
   argument supplies it.

This matters far beyond Arduino. LuaSnip loads `$CFG/LuaSnip/` as **one
collection** via `from_lua.load({ paths = ... })`. One file failing to load
aborts the whole collection, so `tex.lua` and `markdown.lua` never load either.

Symptom to look for in `~/.local/state/nvim/luasnip.log`:

```
ERROR | lua-loader: Failed to load .../LuaSnip/arduino.lua
      | : .../arduino.lua:235: unexpected symbol near '}'
ERROR | lua-loader: Could not create collection at .../LuaSnip: ...
```

That log accumulates one copy of this error **per Neovim startup** and is never
shown on screen. On the source machine it had 1476 copies.

### 3.2 Fix it with exact replacements

Apply these three replacements to `$CFG/LuaSnip/arduino.lua`. Use pattern
matching, not line numbers (they shift).

| Find (exactly) | Replace with |
|---|---|
| `}, { delimiters = "{}" }),` | `}, { delimiters = "{}" })),` |
| `Serial.begin({baud});` | `Serial.begin({});` |

Notes:
- The paren fix applies to **2** occurrences: the `sketch` snippet (~line 35)
  and the `ardsetup` snippet in the `cpp` block (~line 255). All other
  `delimiters` lines already end in `})),` — do not touch them.
- The `{baud}` fix applies to **2** occurrences: one in `sketch`, one in
  `ardsetup`. Fixing only the first makes the file parse but still fail at
  runtime with `Missing key 'baud' in format arguments`.

Reference command (idempotent, safe to re-run). It takes the config path as an
argument, so the quoted heredoc is safe:

```bash
python3 - "$CFG" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]) / "LuaSnip" / "arduino.lua"
s = p.read_text()
s = s.replace('}, { delimiters = "{}" }),', '}, { delimiters = "{}" })),')
s = s.replace('Serial.begin({baud});', 'Serial.begin({});')
p.write_text(s)
print("patched", p)
PY
```

Verify:

```bash
grep -c '{baud}' "$CFG/LuaSnip/arduino.lua"                      # must be 0
grep -c 'delimiters = "{}" })),' "$CFG/LuaSnip/arduino.lua"      # must be 10
nvim --headless -u NONE \
  -c "lua print(loadfile('$CFG/LuaSnip/arduino.lua') and 'PARSE OK' or 'PARSE FAIL')" \
  -c 'qa!' | tail -1
```

The `PARSE OK` line is the gate. Do not continue until you see it.

### 3.3 Decide: autosnippets on or off

The source machine runs with **no autosnippets**. `$CFG/LuaSnip/tex.lua`
originally marked 24 snippets as `snippetType = "autosnippet"`, which makes them
fire while typing.

**Do not simply set `enable_autosnippets = false`.** That makes those 24
snippets completely unreachable:

- `ls.expandable()` only searches the `snippets` table, never `autosnippets`.
- `cmp_luasnip` defaults to `show_autosnippets = false`, so they never appear in
  the menu.
- `snippetType` on the snippet **overrides** which table it is returned in
  (`luasnip/session/snippet_collection/init.lua`), so moving the table alone
  does nothing.

Convert them to ordinary snippets instead:

1. Delete every occurrence of `, snippetType = "autosnippet"` in
   `$CFG/LuaSnip/tex.lua` (24 occurrences).
2. Replace the final `return snippets, autosnippets` with:

   ```lua
   return vim.list_extend(snippets, autosnippets)
   ```

3. In `$CFG/lua/plugins/Luasnip.lua`, set:

   ```lua
   enable_autosnippets = false,
   ```

Verify:

```bash
grep -c 'snippetType' "$CFG/LuaSnip/tex.lua"        # must be 0
grep -n 'return vim.list_extend' "$CFG/LuaSnip/tex.lua"
```

### 3.4 Remove duplicate LaTeX triggers

`$CFG/lua/plugins/Luasnip.lua` defines 38 tex snippets inline, and
`$CFG/LuaSnip/tex.lua` defines more. These 13 triggers exist in both, so the menu
shows two identical rows:

```
ali beg bf cite enum it item lem mat proof ref tab thm
```

Delete those 13 definitions from the **inline** block in
`$CFG/lua/plugins/Luasnip.lua` (the `ls.add_snippets("tex", { ... })` block).
Keep the `tex.lua` versions: they are better (`beg` uses `rep(1)` so `\end{}`
tracks what you type into `\begin{}`, and `ali` uses `\begin{align<>}` so it
handles `align*`).

After deleting, exactly **25** inline triggers remain:

```
mm dm eq frac sec2 ssec2 sssec2 fig2 desc tt alpha beta gamma delta eps theta
lambda mu sigma omega sum int lim pmat eqref
```

### 3.5 Resolve collisions created by §3.3

Converting autosnippets to regular snippets creates **5 new duplicates** with
the inline block. Remove these from `$CFG/LuaSnip/tex.lua` (keep the inline
ones — they have better defaults and are what the user has been using):

```
dm int lim sum tt
```

`tt` is special: the inline `tt` is `\texttt{...}` while the revived one was
`\text{...}` (text in math mode). Rename the `tex.lua` one's trigger to `tx` so
both survive.

Verify no duplicates remain (see §6).

---

## 4. Completion configuration

### 4.1 `$CFG/lua/plugins/nvim_cmp.lua`

The global `cmp.setup({ ... })` must contain:

```lua
  completion = {
    autocomplete = false,                    -- completion is opt-in
    completeopt = 'menu,menuone,noinsert',
    keyword_length = 1,
  },
  preselect = cmp.PreselectMode.Item,
  -- prefix/substring matching only; without this `pri` also matches
  -- PartialEq / ParentDir / park_timeout_ms via subsequence matching
  matching = { disallow_fuzzy_matching = true },
```

The `<Tab>` mapping must be **completion only**. No `luasnip` calls:

```lua
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { 'i', 's' }),
```

`<S-Tab>` must be completion only as well:

```lua
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
```

Every `buffer` source must trigger at 2 characters. **The key is `option`, not
`opts`** — cmp-buffer reads `params.option`, so `opts` is silently ignored:

```lua
    { name = 'buffer', option = { keyword_length = 2 } },
```

Apply to all three source lists: the global one, the `cpp/c/arduino` filetype
one (keep its `priority = 80`), and the `markdown` one.

### 4.2 `$CFG/lua/plugins/Luasnip.lua` — snippet keys

Replace the whole keymap tail of the plugin config with:

```lua
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
```

Two things that will bite you:

- **`<C-l>` must live in this file, not `init.lua`.** `init.lua` is sourced
  before plugin configs; a mapping there is silently overwritten by this one.
- **Do not use `ls.expand_or_jumpable()` for `<C-k>`.** It accepts
  `jumpable(1)`, which can jump into an unrelated older snippet. Use
  `expand_or_locally_jumpable()`. Same for `<C-j>`: `locally_jumpable(-1)`.

### 4.3 `$CFG/lua/plugins/lsp-config.lua` — global cmp capabilities

At the very top of the `nvim-lspconfig` `config = function()`, add:

```lua
      vim.lsp.config('*', {
        capabilities = require('cmp_nvim_cmp').default_capabilities(),
      })
```

Then **delete** the per-server `capabilities = require('cmp_nvim_cmp').default_capabilities(),`
lines from the `texlab`, `arduino_language_server` and `clangd` blocks — they are
now redundant.

Why: without `snippetSupport` the server never sends snippet syntax, so
completions it provides arrive as flat text. Only those three servers had it
before; `lua_ls`, `pylsp` and `rust-analyzer` did not. rustaceanvim merges
`vim.lsp.config['*']` into its own server table, so this covers Rust too.

Verify: `grep -c default_capabilities "$CFG/lua/plugins/lsp-config.lua"` must
return **1**.

---

## 5. Do not touch these

These are already correct; changing them regresses the setup.

- `snippet.expand = function(args) luasnip.lsp_expand(args.body) end`
- `preselect = cmp.PreselectMode.Item` (the top match is pre-highlighted on
  open, so `<CR>` immediately accepts the best suggestion)
- `view.docs.auto_open = true` (docs preview is wanted)
- `<CR>` = `cmp.mapping.confirm({ select = true, behavior = ConfirmBehavior.Replace })`
- Source order: `nvim_lsp`, `luasnip`, `buffer`, `path`
- friendly-snippets lazy loading, including `exclude = { "latex", "tex" }`

---

## 6. Verification

Run all of these. Each has an expected result; a failure means §3 or §4 was not
applied correctly.

### 6.1 Files parse

```bash
for f in LuaSnip/arduino.lua LuaSnip/tex.lua LuaSnip/markdown.lua \
         lua/plugins/Luasnip.lua lua/plugins/nvim_cmp.lua lua/plugins/lsp-config.lua; do
  timeout 25 nvim --headless -u NONE \
    -c "lua local ok,e=loadfile('$CFG/$f'); io.write((ok and 'OK   ' or 'ERR  ')..'$f'..'\n')" \
    -c 'qa!' 2>&1 | tail -1
done
```

Expect six lines of `OK`. Any `ERR` line names the file and the parse error.

### 6.2 Loader produces no errors

```bash
LOG="$HOME/.local/state/nvim/luasnip.log"
before=$(stat -f %m "$LOG" 2>/dev/null || echo 0)
sleep 6 | nvim --headless "$CFG/README.md" -c 'qa!' >/dev/null 2>&1
after=$(stat -f %m "$LOG" 2>/dev/null || echo 0)
[ "$before" = "$after" ] && echo "no new loader errors" || echo "FAIL: check $LOG"
```

(On Linux use `stat -c %Y`. The `stat -f %m` form is the macOS one.)

### 6.3 Snippet counts and no duplicates

Create `/tmp/snipcheck.lua`:

```lua
local ls = require('luasnip')
local out = {}
for _, ft in ipairs({'tex','markdown','arduino','cpp'}) do
  local r = ls.get_snippets(ft, {type='snippets'})
  local a = ls.get_snippets(ft, {type='autosnippets'})
  local seen, dup = {}, {}
  for _, s in ipairs(r) do
    local t = tostring(s.trigger)
    if seen[t] then dup[#dup+1] = t else seen[t] = true end
  end
  out[#out+1] = string.format("%-9s regular=%-3d auto=%-3d dups=%s",
    ft, #r, #a, #dup == 0 and "none" or table.concat(dup, ","))
end
vim.fn.writefile(out, '/tmp/snipcheck.txt')
```

Then open a `.tex` file in that config and run it:

```bash
printf '\\documentclass{article}\n\\begin{document}\nx\n\\end{document}\n' > /tmp/t.tex
sleep 8 | nvim --headless /tmp/t.tex -c "luafile /tmp/snipcheck.lua" >/dev/null 2>&1
cat /tmp/snipcheck.txt
```

Expected:

```
tex       regular=73  auto=0    dups=none
markdown  regular=1   auto=0    dups=none
arduino   regular=21  auto=0    dups=none
cpp       regular=1   auto=0    dups=none
```

(`arduino` counts may differ by ±0 if the Mac has extra snippets; `dups` must be
`none` and `auto` must be `0` on every line.)

### 6.4 Interactive: Rust flow

Needs a real cargo project and **~20 seconds** for rust-analyzer to attach.

```bash
cargo new /tmp/rustprobe && cd /tmp/rustprobe
```

In Neovim on `src/main.rs`, inside `fn main() { ... }` on an empty line:

1. type `pri`
2. `<Tab>`   → completion menu opens; `print!(…)`, `println!(…)`, `print`, `println` present, and **no** `PartialEq` / `ParentDir` / `park_timeout_ms`
3. `<Tab>`   → moves to the next item
4. `<CR>`    → inserts `println!()` with the cursor inside the parentheses
5. `<C-l>`   → cursor moves past `)`
6. type `;`  → line is now `println!();`

Assertions:
- Step 2 must not show fuzzy junk.
- Step 5 must move the cursor exactly one character right.
- Nothing in this flow may require `<Esc>`.

### 6.5 Interactive: snippet fields

In a `.tex` file:

1. type `beg`
2. `<C-k>` → expands to `\begin{environment}` with `environment` selected
3. type `env`
4. `<C-k>` → moves to the next field
5. type `body`
6. `<C-k>` → exits the snippet, cursor after `\end{env}`

Also: type `mk`, `<C-k>` → `$$` with the cursor in the middle, and **nothing may
happen when you type `mk` without `<C-k>`** (no autosnippets).

### 6.6 `<C-l>` on other languages

In Python or Lua, accept any completion that leaves you inside `()`, press
`<C-l>`, and confirm the cursor lands after the `)`. For nested text like
`foo(bar[baz])`, each press steps one closer.

---

## 7. macOS-specific adjustments

These differ from the Linux source machine. Apply as needed.

### 7.1 Arduino CLI config path

`$CFG/lua/plugins/lsp-config.lua` currently points at the Linux path:

```lua
"-cli-config", vim.fn.expand("~/.arduino15/arduino-cli.yaml"),
```

On macOS arduino-cli stores its config at `~/Library/Arduino15/arduino-cli.yaml`.
Verify the file exists, then use a platform-aware path:

```lua
"-cli-config", vim.fn.expand(
  vim.fn.has("mac") == 1 and "~/Library/Arduino15/arduino-cli.yaml"
                         or  "~/.arduino15/arduino-cli.yaml"),
```

If arduino-cli is not installed at all, either install it
(`brew install arduino-cli`) or leave the block alone — the LSP simply will not
attach to `.ino` files.

### 7.2 rust-analyzer

Do **not** install rust-analyzer through Mason. Use:

```bash
rustup component add rust-analyzer
rust-analyzer --version
```

If a stale Mason copy exists, remove it, otherwise PATH order decides which one
runs:

```bash
ls ~/.local/share/nvim/mason/packages/ | grep -i rust
```

`$CFG/init.lua` prepends `~/.cargo/bin` to `PATH` at startup, which is what makes
the rustup proxy win.

### 7.3 vimtex / texlab forward search

The config already expects `skim`:

```lua
forwardSearch = { executable = "skim", ... }
```

Install it (`brew install --cask skim`) or change it to `open -a Skim` style /
your PDF viewer. Only affects `\lv`-style forward search, not completion.

### 7.4 Other references to check

```bash
grep -rn "sysctl\|skim\|arduino15\|osascript\|pbcopy" "$CFG" --include=*.lua
```

- `init.lua` uses `cmake --build build -j$(sysctl -n hw.ncpu)` — correct on
  macOS, keep.
- Clipboard: Neovim picks up `pbcopy` automatically; nothing to do.
- `clang-format` on save is guarded by `vim.fn.executable("clang-format")`, so a
  missing binary is harmless.

### 7.5 First launch

On first start Mason installs `lua_ls`, `pylsp`, `texlab`,
`arduino_language_server`, `clangd`. Expect several minutes of network activity.
Confirm with:

```
:Mason
:LspInfo
```

---

## 8. Rollback

```bash
cp /tmp/nvim-backup/arduino.lua       "$CFG/LuaSnip/arduino.lua"
cp /tmp/nvim-backup/tex.lua           "$CFG/LuaSnip/tex.lua"
cp /tmp/nvim-backup/Luasnip.lua       "$CFG/lua/plugins/Luasnip.lua"
cp /tmp/nvim-backup/nvim_cmp.lua      "$CFG/lua/plugins/nvim_cmp.lua"
cp /tmp/nvim-backup/lsp-config.lua    "$CFG/lua/plugins/lsp-config.lua"
```

If the repo is under git, `git checkout -- nvim/.config/nvim` is equivalent.

---

## 9. Known limitations (do not try to "fix" these)

1. **`println!` is ranked second behind `print!` for the input `pri`.**
   Both are equal-scoring prefix matches; cmp breaks the tie by length. There is
   no reordering that fixes this without breaking other cases. `recently_used`
   promotes `println!` to first after the first accept, and typing `printl`
   disambiguates immediately.

2. **rust-analyzer needs ~15–20s to attach on a cold start.** During that window
   `<Tab>` only finds friendly-snippets entries, or nothing. This is not a bug.

3. **`completeopt` is `menu,popup` at runtime**, not the
   `menu,menuone,noinsert` written in the config. nvim-cmp never applies it
   globally. Harmless because cmp draws its own view.

4. **`<C-l>` steps one closer per press.** That is intentional; nesting takes
   one press per level.

---

## 10. Definition of done

- [ ] `nvim --version` is >= 0.12
- [ ] All six config files report `OK` from `loadfile`
- [ ] `luasnip.log` gains no new errors on startup
- [ ] tex has 0 autosnippets and 0 duplicate triggers
- [ ] `pri` + `<Tab>` shows a clean menu (no `PartialEq`, `ParentDir`, `prefetch_*`)
- [ ] `pri`/`<Tab>`/`<Tab>`/`<CR>`/`<C-l>`/`;` yields `println!();`
- [ ] `<Tab>` never expands a snippet
- [ ] `<C-k>` walks snippet fields and exits on the last one
- [ ] typing `mk` in a `.tex` file does nothing until `<C-k>`
- [ ] `grep -c default_capabilities` on `lsp-config.lua` returns 1
