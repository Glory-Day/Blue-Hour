#!/bin/bash
# ============================================================
# resolution-patcher.sh — EWW window geometry injector.
# Reads monitor resolutions from cache files and injects
# calculated pixel values into modules/windows.yuck by
# replacing {{PLACEHOLDER}} tokens from the template.
# Called by monitor-listener.sh after resolution-cacher.sh
# updates the cache.
#
# Exit codes:
#   0 — Patch applied successfully.
#   1 — Missing cache, template, or dependency.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EWW_DIR="$(dirname "$SCRIPT_DIR")"
WINDOWS_FILE="$EWW_DIR/modules/windows.yuck"
TEMPLATE_FILE="$EWW_DIR/templates/windows.yuck.template"
CACHE_DIR="$HOME/.cache/eww"
EWW_CONFIG="$HOME/.config/eww/config"

C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RED="\033[0;31m"
C_BLUE="\033[0;34m"
C_RESET="\033[0m"

log_info()    { echo -e "${C_BLUE}[resolution-patcher]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[resolution-patcher]${C_RESET} $1"; }
log_warning() { echo -e "${C_YELLOW}[resolution-patcher]${C_RESET} $1"; }
log_error()   { echo -e "${C_RED}[resolution-patcher]${C_RESET} $1"; }

# ── Load island-resizer for BAR_MARGIN constant ──────────────

source "$SCRIPT_DIR/lib/island-resizer.sh"

# ── Validate template ────────────────────────────────────────

if [ ! -f "$TEMPLATE_FILE" ]; then
    log_error "Template not found at $TEMPLATE_FILE."
    exit 1
fi

# ── Fixed bar dimensions ─────────────────────────────────────

readonly BAR_H_HEIGHT=40
readonly BAR_V_WIDTH=52

# ── Read monitor resolutions from cache ──────────────────────

# Fall back to safe defaults if cache files do not exist.
read_cache() {
    local index="$1"
    local file="$CACHE_DIR/monitor-$index"
    if [ -f "$file" ]; then
        cat "$file" | tr -d '[:space:]'
    else
        echo "1920x1080"
    fi
}

RES0=$(read_cache 0)
RES1=$(read_cache 1)

W0=$(echo "$RES0" | cut -dx -f1)
H0=$(echo "$RES0" | cut -dx -f2)
W1=$(echo "$RES1" | cut -dx -f1)
H1=$(echo "$RES1" | cut -dx -f2)

# ── Calculate bar dimensions ─────────────────────────────────

BAR_H_WIDTH_0=$(( W0 - BAR_MARGIN ))
BAR_H_WIDTH_1=$(( W1 - BAR_MARGIN ))
BAR_V_HEIGHT_0=$(( H0 - BAR_MARGIN ))
BAR_V_HEIGHT_1=$(( H1 - BAR_MARGIN ))

log_info "Monitor 0: ${W0}x${H0} → bar ${BAR_H_WIDTH_0}x${BAR_H_HEIGHT}px"
log_info "Monitor 1: ${W1}x${H1} → bar ${BAR_H_WIDTH_1}x${BAR_H_HEIGHT}px"

# ── Inject values into windows.yuck ─────────────────────────

# Read the template and replace all placeholders.
# The template is never modified — windows.yuck is regenerated.
sed \
    -e "s/{{BAR_H_WIDTH_0}}/$BAR_H_WIDTH_0/g" \
    -e "s/{{BAR_H_WIDTH_1}}/$BAR_H_WIDTH_1/g" \
    -e "s/{{BAR_H_HEIGHT}}/$BAR_H_HEIGHT/g"   \
    -e "s/{{BAR_V_WIDTH}}/$BAR_V_WIDTH/g"     \
    -e "s/{{BAR_V_HEIGHT_0}}/$BAR_V_HEIGHT_0/g" \
    -e "s/{{BAR_V_HEIGHT_1}}/$BAR_V_HEIGHT_1/g" \
    "$TEMPLATE_FILE" > "$WINDOWS_FILE"

log_success "Patched $WINDOWS_FILE."

# ── Reload EWW to apply new geometry ─────────────────────────

if eww --config "$EWW_CONFIG" ping &>/dev/null 2>&1; then
    eww --config "$EWW_CONFIG" reload 2>/dev/null && \
        log_success "EWW reloaded." || \
        log_warning "EWW reload failed. Manual restart may be needed."
else
    log_warning "EWW daemon not running. Skipping reload."
fi
