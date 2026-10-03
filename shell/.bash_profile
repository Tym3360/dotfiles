# ============================================
# Homebrew
# ============================================
eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================
# Path
# ============================================
export PATH="$HOME/.local/bin:$PATH"

# ============================================
# Bash completion (brew)
# ============================================
if [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]]; then
  . "/opt/homebrew/etc/profile.d/bash_completion.sh"
fi

source ~/git-flow-completion.bash 2>/dev/null

# ============================================
# Atuin
# ============================================
. "$HOME/.atuin/bin/env"

# bashrc handles the rest (prompt, fzf, editor)
source ~/.bashrc
