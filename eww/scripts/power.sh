#!/bin/bash
# ============================================================
# power.sh — Power menu action handler for EWW.
# Called by eww.yuck button onclick handlers with an action
# argument. Closes the power menu popup before executing
# the requested system action.
#
# Usage:
#   power.sh <action>
#
# Actions:
#   lock      — Lock the screen using hyprlock.
#   suspend   — Suspend the system via systemctl.
#   logout    — Exit Hyprland via hyprctl dispatch exit.
#   reboot    — Reboot the system via systemctl.
#   shutdown  — Power off the system via systemctl.
#
# Exit codes:
#   0 — Action executed successfully.
#   1 — Unknown action provided.
# ============================================================

ACTION="$1"

# Close all power menu popup windows before executing the action.
# This prevents the popup from remaining visible on the lock screen
# or persisting after logout.
eww close popup-power-0 2>/dev/null
eww close popup-power-1 2>/dev/null

case "$ACTION" in
    lock)
        # Use hyprlock as the primary lock screen.
        # Falls back to swaylock if hyprlock is not installed.
        if command -v hyprlock &>/dev/null; then
            hyprlock
        elif command -v swaylock &>/dev/null; then
            swaylock
        fi
        ;;

    suspend)
        # Lock the screen before suspending so the session is
        # protected when the machine wakes up.
        if command -v hyprlock &>/dev/null; then
            hyprlock &
            sleep 0.5
        fi
        systemctl suspend
        ;;

    logout)
        # Exit the Hyprland session cleanly.
        hyprctl dispatch exit
        ;;

    reboot)
        systemctl reboot
        ;;

    shutdown)
        systemctl poweroff
        ;;

    *)
        echo "Error: Unknown action '${ACTION}'."
        echo "Usage: power.sh <lock|suspend|logout|reboot|shutdown>"
        exit 1
        ;;
esac
