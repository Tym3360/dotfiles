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
| `rofi` | `~/.config/rofi` | launcher — **i3 sessions only**; the GNOME session uses the built-in Super search (Spotlight analog, chosen over rofi) |
| `waybar` | `~/.config/waybar` | status bar — **Wayland only** (kept for future Hyprland; Ubuntu 24.04's package has no X11 backend) |
| `polybar` | `~/.config/polybar` | status bar for i3/X11 (launch via `launch.sh`, i3 autostarts it) |
| `scripts/` | `~/scripts` | helpers (`apply-i3.sh`, `apply-gnome.sh`, `i3-close-others.sh`, `ubuntu-setup.sh`) |

## Usage (fresh machine)

```bash
stow -t ~ nvim tmux ghostty herdr i3 rofi waybar
```

If a package conflicts with existing files, move them away first, then re-stow.
