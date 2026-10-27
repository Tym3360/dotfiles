# Neovim Keymap Cheat Sheet

> Leaders: `<leader>` = **Space** · `<localleader>` = **`\`**
> Press `<leader>?` at any time for buffer-local keymaps (which-key)
> Press `<leader>` alone and wait — which-key pops up a menu of all prefix maps

---

## Harpoon — jump to key files
| Key | Action |
|---|---|
| `<leader>ha` | Add current file to harpoon list |
| `<leader>hm` | Toggle quick menu (edit list in-place) |
| `<leader>h1..h4` | Jump to file in slot 1–4 |
| `<leader>hn` / `hp` | Next / previous file in list |

## Telescope — find & search
| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (search text) |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |
| `<leader>oh` | Toggle header ↔ source (C/C++) ⚠️ overlaps `<leader>o` opencode group |

## LSP (buffer-local, when LSP attached)
| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gR` | Show references |
| `gr`? | — (use `gR` above) |
| `K` | Hover documentation |
| `<Ctrl-k>` | Signature help |
| `<Space>rn` | Rename symbol |
| `<Space>ca` | Code action (normal + visual) |
| `<Space>D` | Go to type definition |
| `<Space>fm` | Format buffer |

> clang-format also runs automatically on save for `.c/.cpp/.h/.hpp/.cxx/.hxx`

## Debugging (nvim-dap)
| Key | Action |
|---|---|
| `<leader>dc` | Start / continue debug session |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set breakpoint (with condition prompt) |
| `F10` | Step over |
| `F11` | Step into |
| `F12` | Step out |

## Completion (nvim-cmp, insert mode)

| Key | Action |
|---|---|
| `<Tab>` | Open the completion menu; next item if already open; **jump to the next snippet placeholder when inside a snippet** |
| `<S-Tab>` | Previous item, or jump back one placeholder |
| `<Ctrl-Space>` | Open the completion menu |
| `<CR>` | Confirm the selected item (inserts a newline when the menu is closed) |
| `<Ctrl-b>` / `<Ctrl-f>` | Scroll docs up / down |
| `<Ctrl-e>` | Close the completion menu |

Completion is opt-in: nothing pops up as you type, with one exception — inside an
active snippet placeholder the menu appears automatically after **2** typed
characters (VSCode-style).

`<CR>` confirms through `cmp.core:confirm`, so it never re-opens the menu after
accepting. Buffer words match from **2** characters; LSP and snippets match
from 1. Matching is prefix/substring only (no fuzzy subsequence matches).

## Autopairs
| Key | Action |
|---|---|
| `(` `[` `{` `"` `'` | insert the closing pair with the cursor in the middle |
| `<Right>` | step past the closing character |
| `<leader>ap` | toggle autopairs on/off |

No pairing in `markdown`, `tex`, `plaintex`, `bib` (their own bracket handling),
and no `'` pairing in Rust (lifetimes). `<CR>` stays owned by nvim-cmp.

## Snippets (LuaSnip)
| Key | Action |
|---|---|
| `<Tab>` | Inside a snippet: jump to the next placeholder |
| `<Ctrl-k>` | Expand the snippet trigger before the cursor, or jump forward |
| `<Ctrl-j>` | Jump back to the previous placeholder |
| `<Ctrl-l>` | Step past a closing `)` `]` `}` `"` `'` `` ` ``; cycles a snippet choice when one is active |

There are **no autosnippets**: nothing expands while you type, so `mk` stays
`mk` until you expand it — either from the completion menu or with `<Ctrl-k>`.
LaTeX / Markdown / Arduino snippets live in `LuaSnip/*.lua`; every other
language comes from friendly-snippets.

## AI helpers
| Key | Mode | Action |
|---|---|---|
| `<leader>ai` | normal | Ask pi |
| `<leader>ai` | visual | Ask pi about selection |
| `<Ctrl-a>` | n/x | Ask opencode about file ("@this") |
| `<Ctrl-x>` | n/x | Execute opencode action… |
| `ga` | n/x | Send file/sel to opencode prompt |
| `<leader>ot` | normal | Toggle opencode terminal |
| `<S-C-u>` / `<S-C-d>` | normal | opencode half page up / down |

## File explorer
| Key | Action |
|---|---|
| `<Ctrl-n>` | Reveal current file in neo-tree (left side) |

## Obsidian (markdown buffers in vault, buffer-local)
| Key | Action |
|---|---|
| `gf` | Follow wiki/link (overridden passthrough) |
| `<leader>ch` | Toggle checkbox on line |
| `<CR>` | Smart action: complete cmp menu / follow link / toggle checkbox — task toggles append the ✅ done date like the Obsidian Tasks plugin |
| `<leader>on` | New note from template (ObsidianNewFromTemplate) |
| `<leader>od` | Create/open today's daily note (ObsidianToday) |
| `<leader>tt` | Tasks: today / overdue (TickTick-style Telescope picker) |
| `<leader>ta` | Tasks: all open, grouped by note |
| `<leader>ti` | Tasks: inbox — open tasks with no due date |
| `<leader>td` | Tasks: completed in the last 30 days |
| `<leader>tw` | Open `Home.md` (the vault homepage) |

Commands also work outside markdown buffers: `:ObsidianTasksToday/All/Inbox/Done`, `:ObsidianTaskToggle`. Your regular nvim dashboard owns startup — open the vault homepage deliberately with `<leader>tw`. The checkbox toggles (`<CR>` on a task line and `<leader>ch`) append a done `✅` date, matching what the Obsidian Tasks plugin writes. |

## Markdown (markdown.nvim; only in `markdown` files)
| Key | Action |
|---|---|
| `gs` + `b/i/c/s` | Toggle bold *(`gsb`)*, italic (`gsi`), code (`gsc`), strikethrough (`gss→line`) |
| `gss` | Toggle inline formatting on whole line |
| `ds` + key | Delete surrounding formatting |
| `cs` + from + to | Change surrounding formatting |
| `gl` | Add link |
| `gx` | Follow link (open in browser) |
| `]c` / `]p` | Go to current / parent heading |
| `]]` / `[[` | Next / previous heading |
| `<leader>mt` | Insert table of contents |
| `<leader>ml` / `<leader>mL` | Add list item below / above |
| `<leader>mr` | Reset list numbering |
| `<leader>mT` | Toggle task |
| `<leader>mb` / `mi` / `mc` / `ms` (visual) | Bold / italic / code / strikethrough |

## Godot projects (buffer/command-local)
| Key | Action |
|---|---|
| `<leader>gb` | Insert C# breakpoint |
| `<leader>gd` | Delete all breakpoints in buffer |
| `<leader>gf` | Find all breakpoints in project (quickfix) |

## Language: Python
| Key | Action |
|---|---|
| `F5` (python buffers) | Save + run with `uv run python` |

> Debugging: `<leader>dc` starts debugpy via `uv run --with debugpy`; the script runs in your project's `.venv` automatically.

## Language: C / C++
| Key | Action |
|---|---|
| `F5` | Save + build (cmake via `:make` when CMakeLists.txt exists) |
| `F6` | Pick & run an executable (prompts for args) |
| `F7` | Save + `make test` |
| `F8` | Compile current single file with `clang++ -std=c++20 -g` |
| `<leader>cm` | Configure CMake build dir with compile_commands.json |

## Language: Rust (rust-analyzer via rustaceanvim)
| Key | Mode | Action |
|---|---|---|
| `F5` | rust | Pick & run a target (`:RustLsp runnables`) |
| `F6` | rust | Pick & run a test (`:RustLsp testables`, background runner) |
| `F7` | rust | Run `cargo clippy` in the background, as flycheck diagnostics |
| `F8` | rust | Format buffer (rust-analyzer, falls back to `rustfmt`) |
| `<leader>rd` | rust | Debug a target (codelldb via DAP, prompt to pick target) |
| `<leader>rc` | rust | Open `Cargo.toml` for the current crate |
| `<leader>rh` | rust | Hover actions (run the hover command a second time) |
| `<leader>re` | rust | Explain the error code under the cursor |
| `<leader>rx` | rust | Expand macro under cursor (floating window) |
| `<leader>rt` | rust | Open this symbol's page on docs.rs |
| `<leader>rp` | rust | Jump to the parent module |
| `<leader>rD` | rust | Render the full diagnostic (borrowck/generics explanations) |

> - **Formatting:** rustfmt runs on save (`vim.g.rust_format_on_save = false` opts out). Neovim's bundled `:RustFmt` from rust.vim is broken with modern rustfmt (`--write-mode` was removed), so `<F8>` and format-on-save use rust-analyzer instead.
> - **Diagnostics:** `rust-analyzer` runs `cargo clippy` after each save, so rustc/clippy lints (unused variables, clippy style) appear as diagnostics. Do **not** add `--all-targets`/`--all-features` to `check.extraArgs`: rust-analyzer already passes them, and cargo aborts on duplicates (silently killing all clippy diagnostics).
> - **Inlay hints** (inferred types, parameter names) are enabled per Rust buffer; toggle with `:lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({bufnr=0}), {bufnr=0})`.
> - **Cargo.toml:** crates.nvim completes versions and features, shows outdated-crate diagnostics/hover, and offers code actions to bump versions.

## Misc
| Key | Mode | Action |
|---|---|---|
| `<Ctrl-z>` | n/i/v | **Disabled** (prevents terminal suspend) |
| `+` / `-` | normal | Increment / decrement number (alias for `Ctrl-a`/`Ctrl-x`) |

---

### Notes & known conflicts
- `<leader>o` is registered as an **opencode group** by which-key, but telescope also binds `<leader>oh` (header toggle). Pressing `<leader>o` may wait for the group menu; if that annoys you, move the C/C++ header toggle to e.g. `<leader>sh`.
- which-key preset is "helix" mode with delay 0, so popups appear instantly.
