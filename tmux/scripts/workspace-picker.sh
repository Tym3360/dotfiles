#!/usr/bin/env bash

# Workspace Picker for tmux
# Opens a fzf picker to select workspace type, then creates/attaches to session

# Configuration
OBSIDIAN_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Tym"
LATEX_PATH="$HOME/Documents/GitHub/Tym_UdeS/LaTeX"
CODE_PATH="$HOME/Documents/GitHub"

# Workspace types with descriptions
declare -A WORKSPACES=(
    ["Obsidian"]="$OBSIDIAN_PATH"
    ["LaTeX"]="$LATEX_PATH"
    ["Code"]="$CODE_PATH"
)

# Function to create Obsidian session (single pane with nvim)
create_obsidian_session() {
    local session_name="obsidian"
    local path="$1"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$path"
        tmux send-keys -t "$session_name" "nvim" Enter
    fi
    
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    fi
}

# Function to create LaTeX session (nvim top, terminal bottom)
create_latex_session() {
    local session_name="$1"
    local path="$2"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$path"
        tmux send-keys -t "$session_name" "nvim" Enter
        tmux split-window -t "$session_name" -v -l 30% -c "$path"
        tmux select-pane -t "$session_name:1.1"
    fi
    
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    fi
}

# Function to create Code session (nvim top, terminal bottom)
create_code_session() {
    local session_name="$1"
    local path="$2"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$path"
        tmux send-keys -t "$session_name" "nvim" Enter
        tmux split-window -t "$session_name" -v -l 30% -c "$path"
        tmux select-pane -t "$session_name:1.1"
    fi
    
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    fi
}

# Main picker
main() {
    # First, select workspace type
    workspace_type=$(printf "Obsidian\nLaTeX\nCode" | fzf --prompt="Workspace Type > " --height=10 --reverse --border)
    
    [ -z "$workspace_type" ] && exit 0
    
    case "$workspace_type" in
        "Obsidian")
            create_obsidian_session "$OBSIDIAN_PATH"
            ;;
        "LaTeX")
            # Select LaTeX source folder
            latex_source=$(printf "Default ($LATEX_PATH)\nGitHub ($CODE_PATH)" | fzf --prompt="LaTeX Source > " --height=5 --reverse --border)
            [ -z "$latex_source" ] && exit 0
            
            if [[ "$latex_source" == *"Default"* ]]; then
                target_path="$LATEX_PATH"
            else
                target_path="$CODE_PATH"
            fi
            
            # Let user pick a specific LaTeX project
            project=$(find "$target_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | \
                      xargs -I {} basename {} | \
                      fzf --prompt="LaTeX Project > " --height=20 --reverse --border)
            
            if [ -n "$project" ]; then
                session_name="latex-$(echo "$project" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
                create_latex_session "$session_name" "$target_path/$project"
            fi
            ;;
        "Code")
            # Let user pick a specific code project
            project=$(find "$CODE_PATH" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | \
                      xargs -I {} basename {} | \
                      fzf --prompt="Code Project > " --height=20 --reverse --border)
            
            if [ -n "$project" ]; then
                session_name="code-$(echo "$project" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
                create_code_session "$session_name" "$CODE_PATH/$project"
            fi
            ;;
    esac
}

main
