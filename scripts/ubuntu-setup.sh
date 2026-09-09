#!/usr/bin/env bash
# ============================================================================
# ubuntu-setup.sh — Port the Mac workflow (nvim/herdr/ghostty/tiling/etc.)
# to a fresh Ubuntu 24.04 LTS machine.
#
# Usage:
#   chmod +x ubuntu-setup.sh
#   ./ubuntu-setup.sh                 # full install
#   ./ubuntu-setup.sh --with-zettlr   # also install Zettlr
#   ./ubuntu-setup.sh --no-apps       # skip Zen/Obsidian (flatpak) installs
#   ./ubuntu-setup.sh --no-i3         # skip tiling WM (e.g. you use GNOME)
#
# Run it as your normal user; sudo is requested when needed.
# ============================================================================
set -euo pipefail

# ---------------------------------------------------------------- flags ----
WITH_ZETTLR=0
WITH_APPS=1
WITH_I3=1
for arg in "$@"; do
  case "$arg" in
    --with-zettlr) WITH_ZETTLR=1 ;;
    --no-apps)     WITH_APPS=0 ;;
    --no-i3)       WITH_I3=0 ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

# --------------------------------------------------------------- helpers ---
log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
err()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" &>/dev/null; }
sudorun() {
  if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

DOTFILES_REPO="git@github.com:Tym3360/dotfiles.git"
DOTFILES_REPO_HTTPS="https://github.com/Tym3360/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Verify we're on Ubuntu 24.04 (warn only — script is still mostly portable)
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
    log "Warning: this script targets Ubuntu 24.04 (found ${PRETTY_NAME:-unknown}). Continuing anyway…"
  fi
fi

# ============================================================================
log "[1/12] APT base packages"
# ============================================================================
sudorun apt-get update -y
sudorun apt-get install -y \
  build-essential curl wget git ca-certificates unzip jq \
  zsh tmux stow ripgrep fzf fd-find bat zoxide \
  xclip wl-clipboard xdotool \
  cmake pkg-config gettext ninja-build tree-sitter-cli \
  file gnupg software-properties-common

# apt names that differ from their command names
if ! have fd; then sudorun ln -sf "$(command -v fdfind)" /usr/local/bin/fd; fi
if ! have bat; then sudorun ln -sf "$(command -v batcat)" /usr/local/bin/bat; fi
info "base packages done (fzf/ripgrep/zoxide/stow/tmux …)"

# ============================================================================
log "[2/12] Neovim (latest stable from GitHub — apt's 0.9.x is too old)"
# ============================================================================
if have nvim && (( $(nvim --version | head -1 | grep -oE '[0-9]+' | head -1) >= 1 )); then
  info "nvim already installed: $(nvim --version | head -1)"
else
  NVIM_ASSET_URL="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
    | jq -r '.assets[].browser_download_url' \
    | grep -E 'nvim-linux-x86_64\.tar\.gz$|nvim-linux64\.tar\.gz$' | head -1)"
  [[ -n "$NVIM_ASSET_URL" ]] || { err "could not find a nvim release asset (GitHub API rate limit? try again in ~1h)"; exit 1; }
  curl -fsSL "$NVIM_ASSET_URL" -o /tmp/nvim.tar.gz
  sudorun rm -rf /opt/nvim
  sudorun mkdir -p /opt/nvim
  sudorun tar -C /opt/nvim --strip-components=1 -xzf /tmp/nvim.tar.gz
  sudorun ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -f /tmp/nvim.tar.gz
  info "installed $(nvim --version | head -1)"
fi

# ============================================================================
log "[3/12] lazygit (not in 24.04 repos)"
# ============================================================================
if ! have lazygit; then
  LG_TAG="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r '.tag_name' | sed 's/^v//')"
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_TAG}/lazygit_${LG_TAG}_Linux_x86_64.tar.gz" -o /tmp/lg.tgz
  sudorun tar -C /usr/local/bin --strip-components=0 -xzf /tmp/lg.tgz lazygit
  rm -f /tmp/lg.tgz
fi
info "lazygit $(lazygit --version 2>/dev/null | grep -oE 'v[0-9.]+' | head -1 || echo installed)"

# ============================================================================
log "[4/12] yazi (file manager)"
# ============================================================================
if ! have yazi; then
  YZ_URL="$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest \
    | jq -r '.assets[].browser_download_url' \
    | grep -E 'x86_64-unknown-linux-gnu\.zip$' | grep -v '\.ya\.' | head -1)"
  curl -fsSL "$YZ_URL" -o /tmp/yazi.zip
  unzip -o /tmp/yazi.zip -d /tmp/yazi-x
  sudorun install -m 755 /tmp/yazi-x/*/yazi /usr/local/bin/yazi
  sudorun install -m 755 /tmp/yazi-x/*/ya /usr/local/bin/ya || true
  rm -rf /tmp/yazi.zip /tmp/yazi-x
fi
info "yazi $(yazi --version 2>/dev/null | head -1 || echo installed)"

# ============================================================================
log "[5/12] starship prompt"
# ============================================================================
if ! have starship; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
fi
info "starship $(starship --version | head -1)"

# ============================================================================
log "[6/12] Hack Nerd Font"
# ============================================================================
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if [[ ! -e "$FONT_DIR/HackNerdFont-Regular.ttf" ]]; then
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" -o /tmp/hack.zip
  unzip -o /tmp/hack.zip -d /tmp/hack-font
  cp /tmp/hack-font/*.ttf "$FONT_DIR/" 2>/dev/null || true
  rm -rf /tmp/hack.zip /tmp/hack-font
  fc-cache -f "$FONT_DIR" >/dev/null
fi
info "Hack Nerd Font installed"

# ============================================================================
log "[7/12] Ghostty (community PPA)"
# ============================================================================
if ! have ghostty; then
  sudorun add-apt-repository -y ppa:ghostty-ubuntu/ppa
  sudorun apt-get update -y
  sudorun apt-get install -y ghostty
fi
info "ghostty $(ghostty --version 2>/dev/null | head -1 || echo installed)"

# ============================================================================
log "[8/12] Tiling WM: i3 + picom + waybar + rofi"
# ============================================================================
if [[ $WITH_I3 -eq 1 ]]; then
  sudorun apt-get install -y \
    i3 i3lock picom waybar rofi \
    playerctl brightnessctl pavucontrol \
    network-manager-gnome blueman arandr lxpolkit \
    dex xdg-user-dirs-gtk
  info "i3 (with gaps), picom, waybar, rofi installed — configs come from dotfiles"
fi

# ============================================================================
log "[9/12] Homebrew on Linux + herdr + pi-coding-agent"
# ============================================================================
if ! have brew; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
BREW_PREFIX="$(brew --prefix)"
eval "$("$BREW_PREFIX/bin/brew" shellenv)"
brew install herdr pi-coding-agent
info "herdr $(herdr --version 2>/dev/null | head -1 || echo installed)"
info "pi    $(pi --version 2>/dev/null | head -1 || echo installed)"

# ============================================================================
log "[10/12] GUI apps: Zen browser + Obsidian (Flatpak)"
# ============================================================================
if [[ $WITH_APPS -eq 1 ]]; then
  sudorun apt-get install -y flatpak gnome-software-plugin-flatpak
  sudorun flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  # sudo is required: without a polkit agent (i3 session), a user-initiated
  # system install fails with "Deploy not allowed for user"
  sudorun flatpak install -y --noninteractive flathub app.zen_browser.zen
  sudorun flatpak install -y --noninteractive flathub md.obsidian.Obsidian
  info "Zen + Obsidian installed. Re-login for .desktop entries."
fi

# ============================================================================
log "[11/12] Optional: Zettlr"
# ============================================================================
if [[ $WITH_ZETTLR -eq 1 ]] && ! have zettlr; then
  ZT_URL="$(curl -fsSL https://api.github.com/repos/Zettlr/Zettlr/releases/latest \
    | jq -r '.assets[].browser_download_url' | grep -E 'amd64\.deb$' | head -1)"
  curl -fsSL "$ZT_URL" -o /tmp/zettlr.deb
  sudorun apt-get install -y /tmp/zettlr.deb
  rm -f /tmp/zettlr.deb
  info "Zettlr installed"
fi

# ============================================================================
log "[12/12] Dotfiles (stow) + shell"
# ============================================================================
# Clone dotfiles if missing
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null \
    || git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
fi

# Ghostty on Linux reads ~/.config/ghostty/config — the repo already ships
# ghostty/.config/ghostty/config. If it's missing (old checkout), create it.
if [[ ! -f "$DOTFILES_DIR/ghostty/.config/ghostty/config" ]]; then
  mkdir -p "$DOTFILES_DIR/ghostty/.config/ghostty"
  info "NOTE: ghostty config missing from the repo — add one before stowing"
fi

# Stow all packages
STOW_PKGS="nvim tmux ghostty herdr"
[[ $WITH_I3 -eq 1 ]] && STOW_PKGS="$STOW_PKGS i3 rofi waybar"
cd "$DOTFILES_DIR"
for pkg in $STOW_PKGS; do
  if stow -t "$HOME" "$pkg" 2>/dev/null; then
    info "stowed $pkg"
  else
    info "stow $pkg had conflicts — move the conflicting files away and run: stow -t ~ $pkg"
  fi
done
cd - >/dev/null

# Zsh as default shell + starship hook
if ! grep -q "starship" "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" <<'ZSHRC'

# --- added by ubuntu-setup.sh ---
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
ZSHRC
fi
if [[ "$SHELL" != *"zsh" ]]; then
  chsh -s "$(command -v zsh)" || info "chsh failed — run manually: chsh -s \$(which zsh)"
fi

# ============================================================================
log "Done ✔  — manual follow-ups"
# ============================================================================
cat <<'NOTES'

  1. Log out and pick "i3" at the login screen (gear icon).
  2. Check nvim: run `nvim` once so lazy.nvim installs plugins (uses your
     lazy-lock.json from the stowed dotfiles).
  3. Commit & push the new dotfiles packages from the Mac first:
       cd ~/dotfiles && git add ghostty i3 rofi waybar herdr README.md
       git commit -m "add i3/rofi/waybar/ghostty/herdr configs" && git push
  4. Things with no 1:1 port:
       - AeroSpace → i3 config (in ~/dotfiles/i3)
       - Raycast → rofi ($mod+d), basic launcher/clipboard
       - sketchybar → waybar (in ~/dotfiles/waybar)
       - boring·.notch → none
  5. GNOME-only features (screen sharing, etc.) work better under a Wayland
     session; i3 here is X11. If you want Hyprland (Wayland tiling, closest
     modern feel), it requires extra PPA/build effort on 24.04 — ask me.
NOTES
