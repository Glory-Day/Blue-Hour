#!/bin/bash
# ============================================================
# resolution-decider.sh — Resolution decision client.
# Reads monitor resolution from cache, calculates compact_level
# using island-resizer.sh constants, then determines display
# flags using island-renderer.sh and outputs a JSON object.
# Called by defpoll in variables.yuck every 2 seconds.
#
# Output (JSON):
#   form                   — "horizontal" or "vertical"
#   compact_level          — 0 to 3
#   bar_width              — available bar width in pixels
#   os_show_text           — boolean
#   wifi_show_ssid         — boolean
#   time_show_date         — boolean
#   time_date_full         — boolean
#   battery_show_percent   — boolean
#   music_show_text        — boolean
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/eww"

# ── Load middleware libraries ────────────────────────────────

source "$SCRIPT_DIR/lib/island-resizer.sh"
source "$SCRIPT_DIR/lib/island-renderer.sh"

# ── Read monitor resolution from cache ──────────────────────

# Fall back to safe defaults if the cache file does not exist yet.
# This can happen on first boot before resolution-cacher.sh runs.
CACHE_FILE="$CACHE_DIR/monitor-0"

if [ -f "$CACHE_FILE" ]; then
    RAW=$(cat "$CACHE_FILE" | tr -d '[:space:]')
    MON_W=$(echo "$RAW" | cut -dx -f1)
    MON_H=$(echo "$RAW" | cut -dx -f2)
else
    MON_W=1920
    MON_H=1080
fi

# ── Determine bar form ───────────────────────────────────────

# Use vertical bar when the screen height exceeds its width.
if [ "$MON_H" -gt "$MON_W" ]; then
    FORM="vertical"
else
    FORM="horizontal"
fi

# ── Calculate available bar width ───────────────────────────

BAR_WIDTH=$(( MON_W - BAR_MARGIN ))

# ── Detect battery presence ──────────────────────────────────

HAS_BATTERY=false
if ls /sys/class/power_supply/BAT* &>/dev/null 2>&1; then
    HAS_BATTERY=true
fi

# ── Calculate compact_level ──────────────────────────────────

# Count islands and calculate total gap width.
ISLAND_COUNT=6
[ "$HAS_BATTERY" = true ] && ISLAND_COUNT=7
GAPS=$(( ISLAND_COUNT * ISLAND_GAP ))

# Calculate minimum bar width needed at each compact level.
# Music island is excluded — it manages its own visibility.
if [ "$HAS_BATTERY" = true ]; then
    NEED_L0=$(( ISLAND_OS_FULL      + ISLAND_WORKSPACE_FULL + ISLAND_TIME_FULL    + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_FULL    + ISLAND_BATTERY_FULL    + ISLAND_POWER_FULL + GAPS ))
    NEED_L1=$(( ISLAND_OS_COMPACT   + ISLAND_WORKSPACE_FULL + ISLAND_TIME_FULL    + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_FULL    + ISLAND_BATTERY_FULL    + ISLAND_POWER_FULL + GAPS ))
    NEED_L2=$(( ISLAND_OS_COMPACT   + ISLAND_WORKSPACE_FULL + ISLAND_TIME_FULL    + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_COMPACT + ISLAND_BATTERY_FULL    + ISLAND_POWER_FULL + GAPS ))
    NEED_L3=$(( ISLAND_OS_COMPACT   + ISLAND_WORKSPACE_FULL + ISLAND_TIME_COMPACT + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_COMPACT + ISLAND_BATTERY_COMPACT + ISLAND_POWER_FULL + GAPS ))
else
    NEED_L0=$(( ISLAND_OS_FULL      + ISLAND_WORKSPACE_FULL + ISLAND_TIME_FULL    + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_FULL    + ISLAND_POWER_FULL + GAPS ))
    NEED_L1=$(( ISLAND_OS_COMPACT   + ISLAND_WORKSPACE_FULL + ISLAND_TIME_FULL    + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_FULL    + ISLAND_POWER_FULL + GAPS ))
    NEED_L2=$(( ISLAND_OS_COMPACT   + ISLAND_WORKSPACE_FULL + ISLAND_TIME_FULL    + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_COMPACT + ISLAND_POWER_FULL + GAPS ))
    NEED_L3=$(( ISLAND_OS_COMPACT   + ISLAND_WORKSPACE_FULL + ISLAND_TIME_COMPACT + ISLAND_MESSAGES_FULL + ISLAND_NETWORK_COMPACT + ISLAND_POWER_FULL + GAPS ))
fi

if   [ "$BAR_WIDTH" -ge "$NEED_L0" ]; then COMPACT_LEVEL=0
elif [ "$BAR_WIDTH" -ge "$NEED_L1" ]; then COMPACT_LEVEL=1
elif [ "$BAR_WIDTH" -ge "$NEED_L2" ]; then COMPACT_LEVEL=2
elif [ "$BAR_WIDTH" -ge "$NEED_L3" ]; then COMPACT_LEVEL=3
else
    # Too narrow even at level 3. Switch to vertical bar.
    FORM="vertical"
    COMPACT_LEVEL=3
fi

# Vertical bar always uses level 3.
[ "$FORM" = "vertical" ] && COMPACT_LEVEL=3

# ── Calculate display flags ──────────────────────────────────

calc_render_flags "$COMPACT_LEVEL" "$FORM"

# ── Output JSON ──────────────────────────────────────────────

cat << JSONEOF
{
  "form": "$FORM",
  "compact_level": $COMPACT_LEVEL,
  "bar_width": $BAR_WIDTH,
  "os_show_text": $FLAG_OS_SHOW_TEXT,
  "wifi_show_ssid": $FLAG_WIFI_SHOW_SSID,
  "time_show_date": $FLAG_TIME_SHOW_DATE,
  "time_date_full": $FLAG_TIME_DATE_FULL,
  "battery_show_percent": $FLAG_BATTERY_SHOW_PERCENT,
  "music_show_text": $FLAG_MUSIC_SHOW_TEXT
}
JSONEOF
