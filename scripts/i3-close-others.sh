#!/usr/bin/env bash
# i3 equivalent of AeroSpace's 'close-all-windows-but-current':
# kills every window on the current workspace except the focused one.
set -euo pipefail

current_ws="$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')"
focused_id="$(i3-msg -t get_tree | jq -r '.. | objects | select(.focused == true) | .id')"

# all window (leaf) container ids on the current workspace, including floating
i3-msg -t get_tree \
| jq -r --arg ws "$current_ws" '
    .. | objects
    | select(.type == "workspace" and .name == $ws)
    | .. | objects
    | select(.window != null)
    | .id' \
| while read -r id; do
    [[ "$id" == "$focused_id" ]] && continue
    i3-msg "[id=\"$id\"] kill" >/dev/null
  done
