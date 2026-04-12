#!/bin/bash
# ============================================================
# monitor-listener.sh — Hyprland monitor event listener daemon.
# Runs as a background process started by eww-launcher.sh.
# On startup: caches resolutions and patches windows.yuck.
# On monitor event: compares new resolution to cached value.
# If changed: updates cache and re-patches windows.yuck.
# If unchanged: skips to avoid unnecessary eww reloads.
#
# Exit codes:
#   0 — Daemon exited normally.
#   1 — Missing dependency or Hyprland socket not found.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/eww"

C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RED="\033[0;31m"
C_BLUE="\033[0;34m"
C_RESET="\033[0m"

log_info()    { echo -e "${C_BLUE}[monitor-listener]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[monitor-listener]${C_RESET} $1"; }
log_warning() { echo -e "${C_YELLOW}[monitor-listener]${C_RESET} $1"; }
log_error()   { echo -e "${C_RED}[monitor-listener]${C_RESET} $1"; }

# ── Validate dependencies ────────────────────────────────────

if ! command -v hyprctl &>/dev/null; then
    log_error "hyprctl not found."
    exit 1
fi

if ! command -v socat &>/dev/null; then
    log_error "socat not found."
    exit 1
fi

# ── Helper: read cached resolution ──────────────────────────

read_cache() {
    local index="$1"
    local file="$CACHE_DIR/monitor-$index"
    [ -f "$file" ] && cat "$file" | tr -d '[:space:]' || echo ""
}

# ── Initial startup sequence ─────────────────────────────────

log_info "Starting monitor listener daemon..."

# Cache current resolutions.
"$SCRIPT_DIR/resolution-cacher.sh"

# Store initial resolutions for change detection.
LAST_RES0=$(read_cache 0)
LAST_RES1=$(read_cache 1)

log_info "Initial resolution — monitor 0: $LAST_RES0, monitor 1: $LAST_RES1"

# Patch windows.yuck with initial values.
"$SCRIPT_DIR/resolution-patcher.sh"

# ── Hyprland socket listener ─────────────────────────────────

SOCKET="/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

if [ ! -S "$SOCKET" ]; then
    log_warning "Hyprland socket not found. Monitor change listener disabled."
    exit 1
fi

log_info "Listening for monitor events on $SOCKET..."

socat -u "UNIX-CONNECT:$SOCKET" - 2>/dev/null \
| while read -r event; do

    # Only react to monitor-related Hyprland events.
    if ! echo "$event" | grep -qE \
        "^monitoradded>>|^monitorremoved>>|^monitor>>|^configreloaded>>"; then
        continue
    fi

    log_info "Monitor event: $event"

    # Allow Hyprland to settle before querying new state.
    sleep 0.3

    # Update cache with new resolutions.
    "$SCRIPT_DIR/resolution-cacher.sh"

    # Read new cached values.
    NEW_RES0=$(read_cache 0)
    NEW_RES1=$(read_cache 1)

    # Compare to last known resolutions.
    # Skip patching if nothing has changed to avoid unnecessary reloads.
    if [ "$NEW_RES0" = "$LAST_RES0" ] && [ "$NEW_RES1" = "$LAST_RES1" ]; then
        log_info "Resolution unchanged. Skipping patch."
        continue
    fi

    log_info "Resolution changed — monitor 0: $LAST_RES0 → $NEW_RES0"
    log_info "Resolution changed — monitor 1: $LAST_RES1 → $NEW_RES1"

    # Update last known values.
    LAST_RES0="$NEW_RES0"
    LAST_RES1="$NEW_RES1"

    # Re-patch windows.yuck with new geometry values.
    "$SCRIPT_DIR/resolution-patcher.sh"
done
