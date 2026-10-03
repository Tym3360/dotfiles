# ============================================
# Homebrew (first, so everything else resolves)
# ============================================
eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================
# Path
# ============================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="$(brew --prefix)/opt/llvm/bin:$PATH"

# ============================================
# Editor
# ============================================
export EDITOR='nvim'
export VISUAL='nvim'

# ============================================
# Completions
# ============================================
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
autoload -Uz compinit
compinit

# ============================================
# Zsh options & history (Atuin takes over storage)
# ============================================
setopt AUTO_CD               # cd by typing a directory name
setopt CORRECT               # spelling correction for commands
setopt SHARE_HISTORY         # share history between sessions

# ============================================
# Shell integrations
# ============================================
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# Atuin: history replacement, binds Ctrl+R and Up
. "$HOME/.atuin/bin/env"   # adds ~/.atuin/bin to PATH first
eval "$(atuin init zsh)"

# ============================================
# fzf
# ============================================
export FZF_DEFAULT_OPTS="
--height 60%
--layout=reverse
--border
--inline-info
--preview-window right:60%:wrap
--bind 'ctrl-/:toggle-preview'
--bind 'ctrl-u:preview-page-up'
--bind 'ctrl-d:preview-page-down'
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
--color=border:#89b4fa
"

if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules'
fi

if command -v bat &> /dev/null; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
else
  export FZF_CTRL_T_OPTS="--preview 'cat {}'"
fi

# ============================================
# Aliases
# ============================================
# eza (ls replacement) — global defaults live in ~/.config/eza/{config.yml,theme.yml}
alias ls='eza'
alias ll='eza -l --header --icons --git'
alias la='eza -la --header --icons --git'
alias lt='eza -l --sort=oldest --header --icons --git'
alias tree='eza --tree --git-ignore'

# Git
alias lg='lazygit'
alias gcb='git checkout $(git branch -a | fzf | sed "s/remotes\/origin\///" | sed "s/^\* //" | xargs)'
alias gshow='git show $(git log --oneline | fzf | awk "{print \$1}")'
alias glog='git log --oneline --graph --decorate | fzf --preview "git show --color=always {1}" --bind "enter:execute(git show {1} | less -R)"'

# Interactive fzf helpers
alias fh='eval $(history | fzf | sed "s/^[ ]*[0-9]*[ ]*//")'
alias fkill='kill -9 $(ps aux | fzf -m | awk "{print \$2}")'

# Docker helpers
alias dps='docker ps -a | fzf --header-lines=1 | awk "{print \$1}"'
alias dkill='docker kill $(docker ps -a | fzf --header-lines=1 | awk "{print \$1}")'
alias dlogs='docker logs -f $(docker ps -a | fzf --header-lines=1 | awk "{print \$1}")'

alias cb='nocorrect cb'

# ============================================
# Functions
# ============================================

# Search file contents and open in editor
fag() {
  local file
  file=$(rg --line-number --color=always "$1" 2>/dev/null | fzf --ansi --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}' --preview-window '+{2}/2' | cut -d':' -f1)
  [ -n "$file" ] && nvim "$file"
}

# Interactive git add
gaf() {
  git ls-files -m -o --exclude-standard | fzf -m --preview 'git diff --color=always {} | head -200' | xargs git add
}

# Find and replace in multiple files
frep() {
  if [ $# -ne 2 ]; then
    echo "Usage: frep <search> <replace>"
    return 1
  fi
  rg -l "$1" 2>/dev/null | fzf -m --preview "rg --color=always -C 3 '$1' {}" | xargs sed -i '' "s/$1/$2/g"
}

# yazi: quit with cd-on-quit support
function y() {
  local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
  command rm -f -- "$tmp"
}

# ============================================
# Startup
# ============================================
fastfetch
