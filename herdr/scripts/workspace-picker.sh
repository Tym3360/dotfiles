#!/usr/bin/env bash

# Workspace Picker for Herdr
# Opens a fzf picker to select workspace type, then creates/attaches to workspace

# Configuration
OBSIDIAN_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Tym"
LATEX_PATH="$HOME/Documents/GitHub/Tym_UdeS/LaTeX"
CODE_PATH="$HOME/Documents/GitHub"

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install with: brew install jq"
    exit 1
fi

# Function to get workspace ID by label
get_workspace_id() {
    local label="$1"
    herdr workspace list 2>/dev/null | jq -r --arg label "$label" '.result.workspaces[] | select(.label == $label) | .workspace_id'
}

# Function to create Obsidian workspace (tabs for editor, terminal, file manager)
create_obsidian_workspace() {
    local workspace_label="Obsidian"
    
    # Check if workspace already exists
    local existing_id=$(get_workspace_id "$workspace_label")
    if [ -n "$existing_id" ]; then
        herdr workspace focus "$existing_id" 2>/dev/null
        return 0
    fi
    
    # Create new workspace
    local result=$(herdr workspace create --cwd "$OBSIDIAN_PATH" --label "$workspace_label" --focus 2>/dev/null)
    local workspace_id=$(echo "$result" | jq -r '.result.workspace.workspace_id')
    local tab_id=$(echo "$result" | jq -r '.result.tab.tab_id')
    local pane_id=$(echo "$result" | jq -r '.result.root_pane.pane_id')
    
    if [ -z "$workspace_id" ] || [ "$workspace_id" = "null" ]; then
        echo "Failed to create workspace"
        return 1
    fi
    
    # Rename the tab to "Editor"
    herdr tab rename "$tab_id" "Editor" 2>/dev/null
    
    # Run nvim in the editor pane
    herdr pane run "$pane_id" "nvim" 2>/dev/null
    
    # Create Command line tab
    herdr tab create --workspace "$workspace_id" --cwd "$OBSIDIAN_PATH" --label "Command line" --no-focus 2>/dev/null > /dev/null
    
    # Create Yazi tab
    local yazi_result=$(herdr tab create --workspace "$workspace_id" --cwd "$OBSIDIAN_PATH" --label "Yazi" --no-focus 2>/dev/null)
    local yazi_pane_id=$(echo "$yazi_result" | jq -r '.result.root_pane.pane_id')
    
    # Run yazi in the Yazi pane
    herdr pane run "$yazi_pane_id" "yazi" 2>/dev/null
    
    # Focus the Editor tab
    herdr tab focus "$tab_id" 2>/dev/null
}

# Function to create LaTeX workspace (editor + terminal split)
create_latex_workspace() {
    local session_name="$1"
    local path="$2"
    local workspace_label="$session_name"
    
    # Check if workspace already exists
    local existing_id=$(get_workspace_id "$workspace_label")
    if [ -n "$existing_id" ]; then
        herdr workspace focus "$existing_id" 2>/dev/null
        return 0
    fi
    
    # Create new workspace
    local result=$(herdr workspace create --cwd "$path" --label "$workspace_label" --focus 2>/dev/null)
    local workspace_id=$(echo "$result" | jq -r '.result.workspace.workspace_id')
    local tab_id=$(echo "$result" | jq -r '.result.tab.tab_id')
    local pane_id=$(echo "$result" | jq -r '.result.root_pane.pane_id')
    
    if [ -z "$workspace_id" ] || [ "$workspace_id" = "null" ]; then
        echo "Failed to create workspace"
        return 1
    fi
    
    # Rename the tab
    herdr tab rename "$tab_id" "Editor" 2>/dev/null
    
    # Run nvim in the editor pane
    herdr pane run "$pane_id" "nvim" 2>/dev/null
    
    # Split the pane downwards (terminal)
    herdr pane split "$pane_id" --direction down --ratio 0.3 --no-focus 2>/dev/null > /dev/null
}

# Function to create Code workspace (editor + terminal split)
create_code_workspace() {
    local session_name="$1"
    local path="$2"
    local workspace_label="$session_name"
    
    # Check if workspace already exists
    local existing_id=$(get_workspace_id "$workspace_label")
    if [ -n "$existing_id" ]; then
        herdr workspace focus "$existing_id" 2>/dev/null
        return 0
    fi
    
    # Create new workspace
    local result=$(herdr workspace create --cwd "$path" --label "$workspace_label" --focus 2>/dev/null)
    local workspace_id=$(echo "$result" | jq -r '.result.workspace.workspace_id')
    local tab_id=$(echo "$result" | jq -r '.result.tab.tab_id')
    local pane_id=$(echo "$result" | jq -r '.result.root_pane.pane_id')
    
    if [ -z "$workspace_id" ] || [ "$workspace_id" = "null" ]; then
        echo "Failed to create workspace"
        return 1
    fi
    
    # Rename the tab
    herdr tab rename "$tab_id" "Editor" 2>/dev/null
    
    # Run nvim in the editor pane
    herdr pane run "$pane_id" "nvim" 2>/dev/null
    
    # Split the pane downwards (terminal)
    herdr pane split "$pane_id" --direction down --ratio 0.3 --no-focus 2>/dev/null > /dev/null
}

# Main picker
main() {
    # First, select workspace type
    workspace_type=$(printf "Obsidian\nLaTeX\nCode" | fzf --prompt="Workspace Type > " --height=10 --reverse --border)
    
    [ -z "$workspace_type" ] && exit 0
    
    case "$workspace_type" in
        "Obsidian")
            create_obsidian_workspace
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
                create_latex_workspace "$session_name" "$target_path/$project"
            fi
            ;;
        "Code")
            # Let user pick a specific code project
            project=$(find "$CODE_PATH" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | \
                      xargs -I {} basename {} | \
                      fzf --prompt="Code Project > " --height=20 --reverse --border)
            
            if [ -n "$project" ]; then
                session_name="code-$(echo "$project" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
                create_code_workspace "$session_name" "$CODE_PATH/$project"
            fi
            ;;
    esac
}

main
