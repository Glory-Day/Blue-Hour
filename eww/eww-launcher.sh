#!/bin/bash
# ============================================================
# eww-launcher.sh — EWW bar startup script.
# Reads device.conf for monitor count and device type.
# Starts monitor-listener.sh as a background daemon which
# handles resolution caching, patching, and change detection.
# Opens the appropriate bar window for each monitor.
#
# Called by hyprland.conf via exec-once.
#
# Exit codes:
#   0 — All bar instances launched successfully.
#   1 — A required dependency or configuration file is missing.
# ============================================================

C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RED="\033[0;31m"
C_BLUE="\033[0;34m"
C_RESET="\033[0m"

log_info()    { echo -e "${C_BLUE}[eww-launcher]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[eww-launcher]${C_RESET} $1"; }
log_warning() { echo -e "${C_YELLOW}[eww-launcher]${C_RESET} $1"; }
log_error()   { echo -e "${C_RED}[eww-launcher]${C_RESET} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_CONF="$HOME/.config/eww/device.conf"
EWW_CONFIG="$HOME/.config/eww/config"
CACHE_DIR="$HOME/.cache/eww"

# ── Validate dependencies ────────────────────────────────────

if ! command -v eww &>/dev/null; then
    log_error "eww binary not found."
    exit 1
fi

# ── Load device configuration ────────────────────────────────

MONITOR_COUNT=1
DEVICE_TYPE="desktop"
WALLPAPER_PATH="$HOME/wallpapers/default.gif"

if [ -f "$DEVICE_CONF" ]; then
    source "$DEVICE_CONF"
    log_info "Loaded device.conf (type: $DEVICE_TYPE, monitors: $MONITOR_COUNT)."
else
    log_warning "device.conf not found. Using defaults."
fi

# ── Restart eww daemon ───────────────────────────────────────

log_info "Stopping existing eww daemon..."
eww --config "$EWW_CONFIG" kill 2>/dev/null
sleep 2

log_info "Starting eww daemon..."
eww --config "$EWW_CONFIG" daemon
sleep 0.8

# ── Start swww wallpaper ─────────────────────────────────────

if command -v swww &>/dev/null; then
    if [ -f "$WALLPAPER_PATH" ]; then
        swww img "$WALLPAPER_PATH" \
            --transition-type grow \
            --transition-pos center \
            --transition-duration 1.5 \
            2>/dev/null
        log_success "Wallpaper set: $WALLPAPER_PATH."
    else
        log_warning "Wallpaper not found at $WALLPAPER_PATH. Skipping."
    fi
fi

# ── Start monitor-listener daemon ───────────────────────────
# monitor-listener.sh handles:
#   1. Initial resolution caching via resolution-cacher.sh.
#   2. Initial windows.yuck patch via resolution-patcher.sh.
#   3. Ongoing Hyprland socket monitoring for resolution changes.

log_info "Starting monitor-listener daemon..."
"$SCRIPT_DIR/scripts/monitor-listener.sh" &
LISTENER_PID=$!
log_success "monitor-listener started (PID: $LISTENER_PID)."

# Allow monitor-listener to complete initial caching and patching.
sleep 1.5

# ── Launch bar for each monitor ──────────────────────────────

for (( i=0; i<MONITOR_COUNT; i++ )); do
    log_info "Opening bar for monitor $i..."

    # Read cached resolution to determine bar form.
    CACHE_FILE="$CACHE_DIR/monitor-$i"
    if [ -f "$CACHE_FILE" ]; then
        RAW=$(cat "$CACHE_FILE" | tr -d '[:space:]')
        MON_W=$(echo "$RAW" | cut -dx -f1)
        MON_H=$(echo "$RAW" | cut -dx -f2)
    else
        MON_W=1920
        MON_H=1080
    fi

    # Determine bar form from cached resolution.
    if [ "$MON_H" -gt "$MON_W" ]; then
        FORM="vertical"
    else
        FORM="horizontal"
    fi

    # Close any previously open bar windows for this monitor.
    eww --config "$EWW_CONFIG" close "bar-horizontal-$i" 2>/dev/null
    eww --config "$EWW_CONFIG" close "bar-vertical-$i"   2>/dev/null

    # Open the appropriate bar window.
    if [ "$FORM" = "horizontal" ]; then
        eww --config "$EWW_CONFIG" open "bar-horizontal-$i" && \
            log_success "Opened bar-horizontal-$i (${MON_W}x${MON_H})."
    else
        eww --config "$EWW_CONFIG" open "bar-vertical-$i" && \
            log_success "Opened bar-vertical-$i (${MON_W}x${MON_H})."
    fi
done

log_success "EWW launcher complete."
