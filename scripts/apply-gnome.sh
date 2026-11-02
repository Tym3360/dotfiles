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

# --- 2. keyboard: French Canadian layout + caps lock = escape ----------------
log "Caps Lock → Escape (system-wide, like Karabiner)"
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
# swap both ways instead: "['caps:swapescape']"
log "Keyboard layout → French Canadian (xkb 'ca')"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'ca')]"
gsettings set org.gnome.desktop.input-sources mru-sources "[('xkb', 'ca')]"

# --- 3. workspaces: 9 persistent, like aerospace -----------------------------
log "Static 1–9 workspaces (AeroSpace persistent-workspaces)"
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 9
gsettings set org.gnome.desktop.wm.preferences workspace-names "['1','2','3','4','5','6','7','8','9']"

# --- 3b. Super+1..9 → switch workspace, Super+Shift+1..9 → move window -------
# Ubuntu Dock owns Super+N by default (launches dock apps) — take it back.
log "Super+1..9 → workspaces (AeroSpace-style)"
gsettings set org.gnome.shell.extensions.dash-to-dock hotkeys-show-dock false
for i in 1 2 3 4 5 6 7 8 9; do
  # Ubuntu Dock app hotkeys AND GNOME Shell core both claim Super+N — take it back
  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-$i "[]"
  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-$i "[]"
  gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Shift><Super>$i']"
done
# keep the Home bindings as bonus
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1', '<Super>Home']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>1', '<Shift><Super>Home']"
# free Super+h (minimize) and Super+l (lock-screen → Ctrl+Alt+l) for tiling use
gsettings set org.gnome.desktop.wm.keybindings minimize "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Ctrl><Alt>l']"

# --- 3c. Forge: i3-style dynamic tiling --------------------------------------
# Forge auto-tiles every new window into a BSP layout (like i3) — no manual
# tiling needed. Tiling Assistant (manual tiling) is disabled to avoid conflicts.
log "Forge tiling extension (i3-style auto-tiling)"
if ! gnome-extensions info forge@jmmaranan.com &>/dev/null; then
  v=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=forge@jmmaranan.com&shell_version=46" \
      | grep -o '"version_tag": [0-9]*' | grep -o '[0-9]*' | tail -1)
  curl -sL -o /tmp/forge.zip "https://extensions.gnome.org/download-extension/forge@jmmaranan.com.shell-extension.zip?version_tag=$v"
  gnome-extensions install /tmp/forge.zip --force || true
  gdbus call --session --dest org.gnome.Shell.Extensions \
    --object-path /org/gnome/Shell/Extensions \
    --method org.gnome.Shell.Extensions.InstallRemoteExtension "forge@jmmaranan.com" 2>/dev/null || true
  sleep 2
fi
gnome-extensions enable forge@jmmaranan.com 2>/dev/null || true
gnome-extensions disable tiling-assistant@ubuntu.com 2>/dev/null || true
# focus border: blue instead of Forge's default red
FORGE_SD=~/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas
gsettings --schemadir $FORGE_SD set org.gnome.shell.extensions.forge focus-border-color 'rgba(80, 140, 255, 1)'
# persist enabled set: forge in, tiling-assistant out
gsettings set org.gnome.shell enabled-extensions \
  "['ding@rastersoft.com', 'ubuntu-dock@ubuntu.com', 'forge@jmmaranan.com']"
gsettings set org.gnome.shell.extensions.dash-to-dock ubuntu-dock-fixed-position 'left' 2>/dev/null || true

# --- 4. window behavior: focus follows mouse off, click to focus -------------
gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
gsettings set org.gnome.desktop.wm.preferences action-minimize-effect 'none'

# --- 5. Extensions -----------------------------------------------------------
# Ubuntu's Tiling Assistant (tiling-assistant@ubuntu.com) is preinstalled on
# Ubuntu 24.04 and is enabled — the config above drives it.
# If you prefer "Tiling Shell" instead, install it via Extension Manager (GUI).

# --- 6. launcher: GNOME built-in Super search (Spotlight analog) ------------
# No extra tooling needed — this just verifies search providers are active.
if gsettings get org.gnome.desktop.search-providers disable-external | grep -q true; then
  log "Re-enabling GNOME search providers (apps, files, calculator)"
  gsettings set org.gnome.desktop.search-providers disable-external false
fi
gsettings set org.gnome.desktop.interface enable-hot-corners false

# --- 7. Super+Space → open GNOME search/overview ----------------------------
# Spotlight muscle memory. Two steps: free the combo from input-source
# switching, then rebind the overview toggle.
log "Rebinding Super+Space → GNOME search/overview"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
if gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>space']" 2>/dev/null; then
  info "Super+Space now opens the overview/search"
else
  info "this GNOME version has no toggle-overview key — Super alone still opens search"
fi

cat <<'NOTES'

  Next — extension notes:
    1. Tiling = Forge (installed above, i3-style auto-tiling):
         - every new window auto-tiles into the BSP layout (no manual tiling)
         - Super+1..9 → switch workspace, Super+Shift+1..9 → move window
         - Super+Up / Super+Down → toggle maximize (Forge handles maximized state)
         - drag windows to edges/onto each other to reposition in the tree
         - right-click Forge icon in top bar → Settings for gaps, decoration,
           floating rules etc.
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
