#!/bin/bash
# ============================================================
# icon-patcher.sh — Material Icons SVG manager for EWW.
# Fetches a specific icon from the local sparse checkout,
# applies a fill color, and saves it to the icons/ directory.
# Skips already-patched icons by default unless --force is passed.
#
# Usage:
#   icon-patcher.sh [--force] <material-icon-name> <alias> [color]
#
# Arguments:
#   --force             — Overwrite the icon even if it already exists.
#   material-icon-name  — Exact name in material-design-icons repo.
#   alias               — Shortname used in EWW (e.g. wifi, volume).
#   color               — Hex color code to apply (default: #8d96a0).
#
# Exit codes:
#   0 — Patched successfully.
#   2 — Skipped because the icon already exists.
#   1 — Error occurred.
#
# Examples:
#   icon-patcher.sh wifi wifi
#   icon-patcher.sh --force power_settings_new power "#ff7b72"
#   icon-patcher.sh brightness_high brightness "#f0c944"
# ============================================================

# Terminal color codes for output readability.
C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RED="\033[0;31m"
C_CYAN="\033[0;36m"
C_RESET="\033[0m"

# Parse the optional --force flag before positional arguments.
FORCE=false
if [ "$1" = "--force" ]; then
    FORCE=true
    shift
fi

ICON_NAME="$1"
ALIAS="$2"
COLOR="${3:-#8d96a0}"

# Resolve the EWW root directory dynamically based on this script's location.
# This ensures the script works correctly regardless of where dotfiles are placed.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EWW_DIR="$(dirname "$SCRIPT_DIR")"
REPO="$EWW_DIR/material-icons"
ICONS_DIR="$EWW_DIR/icons"

STYLE="materialsymbolsrounded"
SVG_FILE="${ICON_NAME}_24px.svg"
SVG_PATH="symbols/web/${ICON_NAME}/${STYLE}/${SVG_FILE}"
DEST="${ICONS_DIR}/${ALIAS}.svg"

# Validate that required arguments are provided before proceeding.
if [ -z "$ICON_NAME" ] || [ -z "$ALIAS" ]; then
    echo -e "${C_RED}Error: Missing required arguments.${C_RESET}"
    echo "Usage: icon-patcher.sh [--force] <icon-name> <alias> [color]"
    exit 1
fi

# Verify that the material-icons repository has been initialized.
# The repository must be set up by install.sh before this script can run.
if [ ! -d "$REPO" ]; then
    echo -e "${C_RED}Error: material-icons repo not found at $REPO.${C_RESET}"
    echo "Run install.sh first to initialize the repository."
    exit 1
fi

# Create the icons output directory if it does not already exist.
mkdir -p "$ICONS_DIR"

# Skip patching if the icon already exists and --force was not passed.
# This avoids redundant work when re-running setup-icons.sh.
if [ -f "$DEST" ] && [ "$FORCE" = false ]; then
    echo -e "${C_YELLOW}Skipped:  ${ALIAS}.svg (already exists, use --force to overwrite).${C_RESET}"
    exit 2
fi

# Fetch the icon via sparse checkout if it has not been downloaded yet.
# Sparse checkout is used to avoid downloading the entire repository.
if [ ! -f "${REPO}/${SVG_PATH}" ]; then
    echo -e "${C_CYAN}Fetching: ${ICON_NAME} from repository...${C_RESET}"
    cd "$REPO" && git sparse-checkout add "symbols/web/${ICON_NAME}" && git checkout HEAD
    if [ ! -f "${REPO}/${SVG_PATH}" ]; then
        echo -e "${C_RED}Error:    Icon '${ICON_NAME}' not found in repository.${C_RESET}"
        exit 1
    fi
fi

# Copy the SVG to the icons directory and apply the specified fill color.
# Any existing fill attributes are stripped first to prevent duplication.
cp "${REPO}/${SVG_PATH}" "$DEST"
sed -i "s/fill=\"[^\"]*\"//g" "$DEST"
sed -i "s/<svg/<svg fill=\"${COLOR}\"/" "$DEST"

echo -e "${C_GREEN}Patched:  ${ALIAS}.svg (${ICON_NAME}, color: ${COLOR}).${C_RESET}"
exit 0
