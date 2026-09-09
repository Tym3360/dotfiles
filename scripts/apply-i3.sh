#!/usr/bin/env bash
# apply-i3.sh — configure i3/rofi/waybar from this dotfiles repo.
# Run from anywhere:  ~/dotfiles/scripts/apply-i3.sh
#
# Safe to re-run: clones the repo if missing, stows the WM packages,
# and reloads i3 + waybar if a session is already running.
set -euo pipefail

DOTFILES_REPO="git@github.com:Tym3360/dotfiles.git"
DOTFILES_REPO_HTTPS="https://github.com/Tym3360/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" &>/dev/null; }

# --- 1. repo ---------------------------------------------------------------
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  log "Cloning dotfiles"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null \
    || git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
else
  log "Updating dotfiles"
  git -C "$DOTFILES_DIR" pull --ff-only || log "pull failed — keeping local copy"
fi

# --- 2. packages (skip this script's own deps if they're already there) ----
if ! have stow || ! have i3 || ! have rofi || ! have waybar; then
  log "Installing missing system packages (i3 rofi waybar stow …)"
  if [[ $EUID -eq 0 ]]; then
    apt-get update -y && apt-get install -y \
      i3 i3lock picom polybar rofi stow jq xdg-user-dirs-gtk
  else
    sudo apt-get update -y && sudo apt-get install -y \
      i3 i3lock picom polybar rofi stow jq xdg-user-dirs-gtk
  fi
fi

# --- 3. stow the WM packages ------------------------------------------------
log "Stowing i3 rofi polybar"
cd "$DOTFILES_DIR"
for pkg in i3 rofi waybar polybar; do
  # unstow first so updated configs replace older symlinks cleanly
  stow -t "$HOME" -D "$pkg" 2>/dev/null || true
  stow -t "$HOME" "$pkg" && echo "    stowed $pkg"
done
cd - >/dev/null

# --- 4. scripts executable --------------------------------------------------
chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null || true

# --- 5. reload if a session is live -----------------------------------------
if [[ -n "${I3SOCK:-}" ]] || i3-msg -t get_version &>/dev/null; then
  log "Reloading i3"
  i3-msg reload
  pgrep -x waybar >/dev/null && { pkill -x waybar; sleep 0.3; }
  (setsid waybar &>/dev/null &) 2>/dev/null || true
  log "i3 reloaded ✔"
else
  log "No running i3 session — config is stowed and ready."
  echo "
    Start it by logging out and choosing 'i3' at the login screen
    (or run:  i3  from within a session).
  "
fi
