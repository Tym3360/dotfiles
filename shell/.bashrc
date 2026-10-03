# ============================================
# Homebrew
# ============================================
eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================
# Editor
# ============================================
export EDITOR='nvim'
export VISUAL='nvim'

# ============================================
# Completions
# ============================================
if [[ -s /opt/homebrew/etc/profile.d/bash_completion.sh ]]; then
  . "/opt/homebrew/etc/profile.d/bash_completion.sh"
fi

# ============================================
# Shell integrations
# ============================================
eval "$(starship init bash)"
eval "$(zoxide init bash)"
eval "$(fzf --bash)"

# Atuin
. "$HOME/.atuin/bin/env"

# Ghostty shell integration
if [[ $TERM == "xterm-ghostty" ]]; then
  source "/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/bash/ghostty.bash"
fi

# ============================================
# Aliases
# ============================================
alias ls='eza --group-directories-first'
alias ll='eza -la --group-directories-first --git'
alias lg='lazygit'
