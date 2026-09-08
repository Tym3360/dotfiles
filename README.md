# dotfiles
Place to store all the dot files and configuration scripts with GNU Stow

## Packages

| Package | Stows to | Notes |
|---|---|---|
| `nvim` | `~/.config/nvim` | lazy.nvim config, `lazy-lock.json` pins plugins |
| `tmux` | `~/.tmux.conf`, `~/scripts` | prefix C-d |
| `ghostty` | `~/.config/ghostty` | terminal config (Linux path; macOS uses App Support) |
| `herdr` | `~/.config/herdr`, `~/scripts` | agent multiplexer config + workspace-picker |
| `i3` | `~/.config/i3` | tiling WM — port of AeroSpace setup (Ubuntu) |
| `rofi` | `~/.config/rofi` | launcher (Raycast replacement) |
| `waybar` | `~/.config/waybar` | status bar (sketchybar replacement) |

## Usage (fresh machine)

```bash
stow -t ~ nvim tmux ghostty herdr i3 rofi waybar
```

If a package conflicts with existing files, move them away first, then re-stow.
