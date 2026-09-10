#!/usr/bin/env bash
# apply-gnome.sh — configure GNOME 46 as the "comfort" tiling session.
# Middle ground: keep the GUI (settings, dock, dialogs) + AeroSpace-style tiling
# via the "Tiling Shell" extension. i3 stays available at the login screen.
#
# Run: ~/dotfiles/scripts/apply-gnome.sh    (must run inside a GNOME session)
set -euo pipefail

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" &>/dev/null; }

# --- sanity: must be a GNOME session ----------------------------------------
if [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]]; then
  echo "This script configures GNOME — run it from inside a GNOME session." >&2
  exit 1
fi

# --- 1. system packages ------------------------------------------------------
log "Installing GNOME tooling"
if [[ $EUID -eq 0 ]]; then
  apt-get update -y && apt-get install -y gnome-tweaks gnome-shell-extension-manager dconf-cli
else
  sudo apt-get update -y && sudo apt-get install -y gnome-tweaks gnome-shell-extension-manager dconf-cli
fi

# --- 2. keyboard: caps lock = escape ----------------------------------------
log "Caps Lock → Escape (system-wide, like Karabiner)"
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
# swap both ways instead: "['caps:swapescape']"

# --- 3. workspaces: 9 persistent, like aerospace -----------------------------
log "Static 1–9 workspaces (AeroSpace persistent-workspaces)"
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 9
gsettings set org.gnome.desktop.wm.preferences workspace-names "['1','2','3','4','5','6','7','8','9']"

# --- 4. window behavior: focus follows mouse off, click to focus -------------
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
gsettings set org.gnome.desktop.wm.preferences action-minimize-effect 'none'

# --- 5. Extensions (installed via GUI — flathub Extension Manager) ----------
log "Installing Extension Manager (flatpak)"
flatpak install -y --noninteractive --system flathub com.mattjakeman.ExtensionManager 2>/dev/null \
  || sudo flatpak install -y --noninteractive --system flathub com.mattjakeman.ExtensionManager

# --- 6. launcher: GNOME built-in Super search (Spotlight analog) ------------
# No extra tooling needed — this just verifies search providers are active.
if gsettings get org.gnome.desktop.search-providers disable-external | grep -q true; then
  log "Re-enabling GNOME search providers (apps, files, calculator)"
  gsettings set org.gnome.desktop.search-providers disable-external false
fi
gsettings set org.gnome.desktop.interface enable-hot-corners false

cat <<'NOTES'

  Next — inside Extension Manager (install tab):
    1. Search "Tiling Shell"  → install.  (AeroSpace-style tiling for GNOME)
       Then open its settings:
         - enable advanced tiling shortcuts
         - map: Super+h/j/k/l → focus left/down/up/right
               Super+Shift+h/j/k/l → move window
               Super+1..9 → move to workspace N
       Note: Super+h is GNOME's "minimize" by default — Extension Manager /
       Settings → Keyboard lets you clear it (or use Super+arrows tiling only).
    2. Optional macOS feel:
       "Dash to Dock"    → macOS-style dock
       "Blur my Shell"   → frosted-glass top bar/overview
       "AppIndicator"    → tray icons support
    3. Launcher: use the built-in GNOME search (press Super and type).
       It's the Spotlight analog. rofi remains installed as the i3-session
       launcher (i3 has no GNOME search).

  Fonts: Settings → Appearance → Fonts → set "Hack Nerd Font" as monospace.
NOTES
log "GNOME configured ✔"
