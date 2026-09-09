#!/usr/bin/env bash
# Launch polybar on the primary monitor (called from the i3 config).
# Usage: ~/.config/polybar/launch.sh
set -euo pipefail

# terminate already running bar instances
killall -q polybar 2>/dev/null || true
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done

# detect battery names (some laptops use BAT1/ACAD etc.)
PB_BATTERY="$(ls /sys/class/power_supply | grep -m 1 '^BAT' || echo BAT0)"
PB_ADAPTER="$(ls /sys/class/power_supply | grep -m 1 -E '^(AC|ACAD|ADP|ACPI)' || echo AC)"

# primary monitor via xrandr; note: $2 is exactly "connected" or "disconnected",
# so substring matching would catch disconnected outputs — compare fields
MONITOR="$(xrandr --query | awk '$2 == "connected" && $3 == "primary" {print $1}')"
[[ -n "$MONITOR" ]] || MONITOR="$(xrandr --query | awk '$2 == "connected" {print $1; exit}')"

export MONITOR PB_BATTERY PB_ADAPTER
polybar --reload main &
