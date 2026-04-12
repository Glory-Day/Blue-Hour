#!/bin/bash
# ============================================================
# network.sh — Network connection status reporter for EWW.
# Checks for an active LAN connection first, then Wi-Fi.
# Returns the connection type, icon alias, name, and status.
#
# Output (JSON):
#   type      — "lan", "wifi", or "none".
#   icon      — SVG icon alias matching a file in icons/.
#   name      — Interface name for LAN, SSID for Wi-Fi.
#   connected — true if any connection is active, false otherwise.
# ============================================================

# ── LAN (Ethernet) check ─────────────────────────────────────

# Iterate over all ethernet-like interfaces and return the first
# one that reports an "up" operational state.
for iface in $(ls /sys/class/net/ 2>/dev/null \
               | grep -E '^(eth|en|eno|enp|ens)'); do
    STATE=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)
    if [ "$STATE" = "up" ]; then
        echo "{\"type\":\"lan\",\"icon\":\"net-lan\",\"name\":\"$iface\",\"connected\":true}"
        exit 0
    fi
done

# ── Wi-Fi check ──────────────────────────────────────────────

# Iterate over all wireless interfaces and return the first
# one that reports an "up" operational state.
for iface in $(ls /sys/class/net/ 2>/dev/null \
               | grep -E '^(wl|wlan)'); do
    STATE=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)
    if [ "$STATE" = "up" ]; then

        # Retrieve the connected SSID using iw.
        # Falls back to the interface name if iw is unavailable.
        SSID=$(iw dev "$iface" info 2>/dev/null \
               | grep -oP '(?<=ssid ).*' \
               | head -c 20)
        [ -z "$SSID" ] && SSID="$iface"

        # Select icon based on signal strength from /proc/net/wireless.
        # Signal is reported as a negative dBm value; higher is stronger.
        SIGNAL=$(awk "/$iface/"'{gsub(/\./, "", $3); print $3}' \
                 /proc/net/wireless 2>/dev/null | head -1)
        SIGNAL="${SIGNAL:-0}"

        if   [ "$SIGNAL" -ge 65 ] 2>/dev/null; then ICON="net-wifi-full"
        elif [ "$SIGNAL" -ge 45 ] 2>/dev/null; then ICON="net-wifi-mid"
        else                                         ICON="net-wifi-low"
        fi

        # Escape any special characters in SSID for safe JSON output.
        SSID_SAFE=$(echo "$SSID" | sed 's/\\/\\\\/g; s/"/\\"/g')

        echo "{\"type\":\"wifi\",\"icon\":\"$ICON\",\"name\":\"$SSID_SAFE\",\"connected\":true}"
        exit 0
    fi
done

# ── No connection ────────────────────────────────────────────

echo '{"type":"none","icon":"net-none","name":"No connection","connected":false}'
