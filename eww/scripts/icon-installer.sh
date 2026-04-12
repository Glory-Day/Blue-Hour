#!/bin/bash
# ============================================================
# setup-icons.sh — Batch icon setup script for EWW widgets.
# Calls icon-patcher.sh for each required icon definition.
# Already-patched icons are skipped unless --force is passed.
# Failed icons are tracked and reported in the final summary.
#
# Usage:
#   setup-icons.sh [--force] [--retry-failed]
#
# Options:
#   --force          — Overwrite all icons even if they already exist.
#   --retry-failed   — Only process icons that failed in the last run.
#
# Exit codes:
#   0 — All icons processed successfully.
#   1 — One or more icons failed to patch.
# ============================================================

# Terminal color codes for output readability.
C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RED="\033[0;31m"
C_BLUE="\033[0;34m"
C_BOLD="\033[1m"
C_RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHER="$SCRIPT_DIR/icon-patcher.sh"
EWW_DIR="$(dirname "$SCRIPT_DIR")"
FAILED_LOG="$EWW_DIR/.icon-setup-failed"

# Parse options before processing icon definitions.
FORCE=false
RETRY_FAILED=false
for arg in "$@"; do
    case "$arg" in
        --force)        FORCE=true ;;
        --retry-failed) RETRY_FAILED=true ;;
    esac
done

# Verify that icon-patcher.sh exists and is executable.
if [ ! -x "$PATCHER" ]; then
    echo -e "${C_RED}Error: icon-patcher.sh not found or not executable at $PATCHER.${C_RESET}"
    exit 1
fi

# ============================================================
# Icon definitions.
# Format: "material-icon-name alias hex-color"
# Adding a new icon only requires a new line in this array.
# ============================================================
ICONS=(
    # OS island.
    "computer                  os-arch           #58a6ff"

    # Network icons — green for connected, muted for disconnected.
    "wifi                      net-wifi-full     #3fb950"
    "wifi_2_bar                net-wifi-mid      #3fb950"
    "wifi_1_bar                net-wifi-low      #d29922"
    "wifi_off                  net-wifi-off      #6e7681"
    "settings_ethernet         net-lan           #3fb950"
    "signal_disconnected       net-none          #6e7681"

    # Battery icons — color reflects charge level.
    "battery_full              bat-full          #3fb950"
    "battery_5_bar             bat-high          #3fb950"
    "battery_3_bar             bat-mid           #d29922"
    "battery_1_bar             bat-low           #f85149"
    "battery_alert             bat-critical      #f85149"
    "battery_charging_full     bat-charging      #d29922"

    # Music island.
    "play_arrow                music-play        #bc8cff"
    "pause                     music-pause       #bc8cff"
    "music_note                music-idle        #6e7681"

    # Messages island.
    "chat_bubble               msg-discord       #5865f2"
    "mail                      msg-gmail         #f85149"
    "forum                     msg-slack         #e8d5b0"

    # Power menu.
    "power_settings_new        power             #f85149"
    "lock                      power-lock        #58a6ff"
    "bedtime                   power-suspend     #8b949e"
    "logout                    power-logout      #8b949e"
    "restart_alt               power-reboot      #ffa657"
    "cancel                    power-shutdown    #f85149"

    # Stub popup trigger icons.
    "calendar_today            popup-calendar    #58a6ff"
    "monitoring                popup-system      #3fb950"
    "notifications             popup-notify      #d29922"
)

# When --retry-failed is passed, filter the icon list down to
# only those that failed in the previous run.
if [ "$RETRY_FAILED" = true ]; then
    if [ ! -f "$FAILED_LOG" ]; then
        echo -e "${C_YELLOW}No failed icon log found. Running full setup instead.${C_RESET}"
    else
        FAILED_ALIASES=$(cat "$FAILED_LOG")
        FILTERED=()
        for entry in "${ICONS[@]}"; do
            ALIAS=$(echo "$entry" | awk '{print $2}')
            if echo "$FAILED_ALIASES" | grep -qx "$ALIAS"; then
                FILTERED+=("$entry")
            fi
        done
        ICONS=("${FILTERED[@]}")
        echo -e "${C_BLUE}Retrying ${#ICONS[@]} previously failed icon(s).${C_RESET}"
    fi
fi

# Counters for the final summary report.
TOTAL=${#ICONS[@]}
COUNT_SUCCESS=0
COUNT_SKIPPED=0
COUNT_FAILED=0
FAILED_ALIASES=()

echo -e "${C_BOLD}Setting up EWW icons (${TOTAL} total)...${C_RESET}\n"

# Process each icon definition and track results by exit code.
# Exit code 0 = success, 2 = skipped, 1 = error.
for i in "${!ICONS[@]}"; do
    entry="${ICONS[$i]}"
    ICON_NAME=$(echo "$entry" | awk '{print $1}')
    ALIAS=$(echo "$entry"     | awk '{print $2}')
    COLOR=$(echo "$entry"     | awk '{print $3}')
    INDEX=$((i + 1))

    echo -e "${C_BLUE}[${INDEX}/${TOTAL}]${C_RESET} Processing ${ALIAS}..."

    if [ "$FORCE" = true ]; then
        "$PATCHER" --force "$ICON_NAME" "$ALIAS" "$COLOR"
    else
        "$PATCHER" "$ICON_NAME" "$ALIAS" "$COLOR"
    fi

    case $? in
        0) COUNT_SUCCESS=$((COUNT_SUCCESS + 1)) ;;
        2) COUNT_SKIPPED=$((COUNT_SKIPPED + 1)) ;;
        *)
            COUNT_FAILED=$((COUNT_FAILED + 1))
            FAILED_ALIASES+=("$ALIAS")
            ;;
    esac
done

# Write failed aliases to log so --retry-failed can reference them later.
# Clear the log if there were no failures this run.
if [ ${#FAILED_ALIASES[@]} -gt 0 ]; then
    printf "%s\n" "${FAILED_ALIASES[@]}" > "$FAILED_LOG"
else
    rm -f "$FAILED_LOG"
fi

# Print the final summary report.
echo ""
echo -e "${C_BOLD}─────────────────────────────${C_RESET}"
echo -e "${C_BOLD}Icon setup summary${C_RESET}"
echo -e "${C_BOLD}─────────────────────────────${C_RESET}"
echo -e "  ${C_GREEN}Patched : ${COUNT_SUCCESS}${C_RESET}"
echo -e "  ${C_YELLOW}Skipped : ${COUNT_SKIPPED}${C_RESET}"
echo -e "  ${C_RED}Failed  : ${COUNT_FAILED}${C_RESET}"
echo -e "${C_BOLD}─────────────────────────────${C_RESET}"

if [ ${#FAILED_ALIASES[@]} -gt 0 ]; then
    echo -e "\n${C_RED}Failed icons:${C_RESET}"
    for alias in "${FAILED_ALIASES[@]}"; do
        echo -e "  ${C_RED}• ${alias}${C_RESET}"
    done
    echo -e "\nRun with ${C_YELLOW}--retry-failed${C_RESET} to retry only the failed icons."
    exit 1
fi

echo -e "\n${C_GREEN}All icons have been set up successfully.${C_RESET}"
exit 0
