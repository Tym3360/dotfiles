vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Make rustup proxies (cargo, rustc, rust-analyzer, rustfmt, clippy) reachable.
-- ~/.cargo/env is only sourced from ~/.profile and ~/.bashrc, so Neovim
-- started from a shell that does not read those (e.g. fish) would otherwise
-- not find rust-analyzer.
do
  local cargo_bin = vim.fn.expand("~/.cargo/bin")
  local path = vim.env.PATH or ""
  if vim.fn.isdirectory(cargo_bin) == 1 and not path:find(cargo_bin, 1, true) then
    vim.env.PATH = cargo_bin .. ":" .. path
  end
end

-- Setup lazy.nvim
require("config.lazy")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.keymap.set('n', '<F5>', ':w<CR>:!uv run python %<CR>', { buffer = true, desc = "Run Python file with uv" })
  end
})

-- Rust filetype settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    -- rustfmt default indentation
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = true

    -- Only map F5 inside an actual Cargo project (single .rs files support LSP
    -- but have nothing to `cargo run`).
    if vim.fs.find("Cargo.toml", { upward = true })[1] then
      vim.keymap.set('n', '<F5>', function()
        vim.cmd("write")
        vim.cmd("!cargo run 2>&1")
      end, { buffer = true, desc = "Run Rust project with cargo" })
    end
  end
})

-- Rust filetype settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    -- rustfmt default indentation
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = true

    -- Only map F5 inside an actual Cargo project (single .rs files support LSP
    -- but have nothing to `cargo run`).
    if vim.fs.find("Cargo.toml", { upward = true })[1] then
      vim.keymap.set('n', '<F5>', function()
        vim.cmd("write")
        vim.cmd("!cargo run 2>&1")
      end, { buffer = true, desc = "Run Rust project with cargo" })
    end
  end
})

-- C/C++ filetype settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = true

    -- Only set the cmake makeprg if a CMakeLists.txt is reachable from this file.
    -- Otherwise (single-file projects) leave :make pointing at plain make.
    if vim.fs.find("CMakeLists.txt", { upward = true })[1] then
      vim.bo.makeprg = "cmake --build build -j$(sysctl -n hw.ncpu) 2>&1"
    end

    vim.keymap.set('n', '<F5>', function()
      vim.cmd("write")
      vim.cmd("make")
    end, { buffer = true, desc = "Build C++ project" })

    vim.keymap.set('n', '<F6>', function()
      vim.cmd("write")

      -- Collect candidate executables, most recent first:
      --   1) anything executable under build/    (CMake workflow)
      --   2) same-stem binary in cwd             (F8 single-file workflow: main.cpp -> ./main)
      local candidates = {}
      local build_dir = vim.fn.getcwd() .. "/build"
      if vim.fn.isdirectory(build_dir) == 1 then
        local files = vim.fn.systemlist(
          "find " .. vim.fn.shellescape(build_dir) ..
          " -maxdepth 2 -type f -perm -100 " ..
          "-not -name '*.o' -not -name 'CMakeCache.txt' " ..
          "-not -name '*.cmake' -not -name 'Makefile' 2>/dev/null"
        )
        for _, f in ipairs(files) do table.insert(candidates, f) end
      end

      local stem = vim.fn.expand('%:r')  -- main.cpp -> main
      if stem ~= "" then
        local st = (vim.uv or vim.loop).fs_stat(stem)
        if st and st.type == "file" and bit.band(st.mode, 73) ~= 0 then  -- 0o111 = 73
          table.insert(candidates, stem)
        end
      end

      -- Newest first, deduplicated.
      table.sort(candidates, function(a, b)
        local ma = (vim.uv or vim.loop).fs_stat(a).mtime.sec
        local mb = (vim.uv or vim.loop).fs_stat(b).mtime.sec
        return ma > mb
      end)
      local seen, unique = {}, {}
      for _, f in ipairs(candidates) do
        if not seen[f] then seen[f] = true; table.insert(unique, f) end
      end

      local default = unique[1] or ""
      local exe = vim.fn.input("Run executable: ", default, "file")
      if exe == "" then
        if default == "" then
          vim.notify(
            "No executable found. Press F5 (CMake) or F8 (single file) to build first.",
            vim.log.levels.WARN)
        end
        return
      end

      local args = vim.fn.input("Args: ", "")
      vim.cmd("!" .. vim.fn.shellescape(exe) .. " " .. args)
    end, { buffer = true, desc = "Run C++ executable" })

    vim.keymap.set('n', '<F7>', function()
      vim.cmd("write")
      vim.cmd("make test")
    end, { buffer = true, desc = "Run C++ tests" })

    vim.keymap.set('n', '<F8>', function()
      vim.cmd("write")
      local src = vim.fn.expand('%')
      local out = vim.fn.expand('%:r')
      vim.cmd("!clang++ -std=c++20 -Wall -Wextra -O0 -g " .. src .. " -o " .. out)
      vim.notify("Compiled " .. out, vim.log.levels.INFO)
    end, { buffer = true, desc = "Compile single C++ file with clang++" })

    vim.keymap.set('n', '<leader>cm', function()
      vim.fn.mkdir("build", "p")
      vim.fn.system("cmake -S " .. vim.fn.getcwd() .. " -B " .. vim.fn.getcwd() .. "/build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
      vim.notify("CMake configured", vim.log.levels.INFO)
    end, { buffer = true, desc = "Configure CMake project" })
  end
})

-- Run clang-format on save for C/C++ files (falls back gracefully if missing).
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp", "*.cxx", "*.hxx" },
  callback = function()
    if vim.fn.executable("clang-format") == 1 then
      vim.lsp.buf.format({ async = false })
    end
  end,
})

-- Prevent accidental terminal suspension (Ctrl-Z) while editing.
vim.keymap.set({ 'n', 'i', 'v' }, '<C-z>', '<Nop>', { silent = true, desc = 'Disable suspend' })
