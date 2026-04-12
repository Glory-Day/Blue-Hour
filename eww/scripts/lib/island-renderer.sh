#!/bin/bash
# ============================================================
# island-renderer.sh — Island display flag calculator.
# Determines what each island should show based on the current
# compact_level and bar form (horizontal or vertical).
# Source this file and call calc_render_flags() to populate
# the display flag variables.
#
# Usage:
#   source "$(dirname "$0")/lib/island-renderer.sh"
#   calc_render_flags "$compact_level" "$form"
#
# Output variables (set in the calling scope):
#   FLAG_OS_SHOW_TEXT          — Show "Arch" text next to icon.
#   FLAG_WIFI_SHOW_SSID        — Show Wi-Fi SSID or "LAN" label.
#   FLAG_TIME_SHOW_DATE        — Show date alongside time.
#   FLAG_TIME_DATE_FULL        — Show full date vs abbreviated.
#   FLAG_BATTERY_SHOW_PERCENT  — Show battery percentage label.
#   FLAG_MUSIC_SHOW_TEXT       — Show track title and artist.
# ============================================================

calc_render_flags() {
    local level="$1"
    local form="$2"

    # Vertical bar always shows icons only regardless of level.
    # All text labels are hidden to fit the narrow bar width.
    if [ "$form" = "vertical" ]; then
        FLAG_OS_SHOW_TEXT=false
        FLAG_WIFI_SHOW_SSID=false
        FLAG_TIME_SHOW_DATE=false
        FLAG_TIME_DATE_FULL=false
        FLAG_BATTERY_SHOW_PERCENT=false
        FLAG_MUSIC_SHOW_TEXT=false
        return
    fi

    # Horizontal bar: flags determined by compact_level.
    # Each level progressively hides more content.

    # Level 0: All islands shown in full.
    if [ "$level" -eq 0 ]; then
        FLAG_OS_SHOW_TEXT=true
        FLAG_WIFI_SHOW_SSID=true
        FLAG_TIME_SHOW_DATE=true
        FLAG_TIME_DATE_FULL=true
        FLAG_BATTERY_SHOW_PERCENT=true
        FLAG_MUSIC_SHOW_TEXT=true
        return
    fi

    # Level 1: OS text hidden. Everything else full.
    if [ "$level" -eq 1 ]; then
        FLAG_OS_SHOW_TEXT=false
        FLAG_WIFI_SHOW_SSID=true
        FLAG_TIME_SHOW_DATE=true
        FLAG_TIME_DATE_FULL=true
        FLAG_BATTERY_SHOW_PERCENT=true
        FLAG_MUSIC_SHOW_TEXT=true
        return
    fi

    # Level 2: OS text and Wi-Fi SSID hidden.
    if [ "$level" -eq 2 ]; then
        FLAG_OS_SHOW_TEXT=false
        FLAG_WIFI_SHOW_SSID=false
        FLAG_TIME_SHOW_DATE=true
        FLAG_TIME_DATE_FULL=false
        FLAG_BATTERY_SHOW_PERCENT=true
        FLAG_MUSIC_SHOW_TEXT=true
        return
    fi

    # Level 3: Maximum compact. Icons only across all islands.
    FLAG_OS_SHOW_TEXT=false
    FLAG_WIFI_SHOW_SSID=false
    FLAG_TIME_SHOW_DATE=false
    FLAG_TIME_DATE_FULL=false
    FLAG_BATTERY_SHOW_PERCENT=false
    FLAG_MUSIC_SHOW_TEXT=false
}
