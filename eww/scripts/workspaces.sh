#!/bin/bash
# ============================================================
# workspaces.sh — Hyprland workspace state reporter for EWW.
# Uses deflisten to stream real-time updates via the Hyprland
# IPC socket instead of polling. Outputs a JSON object whenever
# the active workspace or workspace list changes.
#
# Output (JSON):
#   active     — ID of the currently focused workspace.
#   workspaces — Sorted array of existing workspace IDs (max 10).
#
# Exit codes:
#   0 — Stream ended normally.
#   1 — Hyprland socket not found.
# ============================================================

# ── Helper: emit current workspace state ─────────────────────

emit_state() {
    # Read the active workspace ID from hyprctl.
    ACTIVE=$(hyprctl activeworkspace -j 2>/dev/null \
             | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('id', 1))
" 2>/dev/null || echo 1)

    # Read all existing workspace IDs, clamped to a maximum of 10.
    # Workspaces beyond 10 are ignored to keep the island compact.
    WS=$(hyprctl workspaces -j 2>/dev/null \
         | python3 -c "
import sys, json
data = json.load(sys.stdin)
ids = sorted(set(w['id'] for w in data if 1 <= w['id'] <= 10))
print(json.dumps(ids))
" 2>/dev/null || echo "[1]")

    echo "{\"active\":$ACTIVE,\"workspaces\":$WS}"
}

# ── Initial state output ─────────────────────────────────────

# Emit the current state immediately so eww has data on startup
# before any socket events have been received.
emit_state

# ── Real-time socket listener ────────────────────────────────

# Connect to the Hyprland IPC socket and listen for events.
# Re-emit the workspace state whenever a relevant event occurs.
SOCKET="/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

if [ ! -S "$SOCKET" ]; then
    exit 1
fi

socat -u "UNIX-CONNECT:$SOCKET" - 2>/dev/null \
| while read -r event; do
    # React to workspace focus changes, workspace creation and
    # destruction, and monitor focus changes.
    if echo "$event" | grep -qE \
        "^workspace>>|^createworkspace>>|^destroyworkspace>>|^focusedmon>>"; then
        # Small delay to allow hyprctl state to settle after the event.
        sleep 0.05
        emit_state
    fi
done
