#!/bin/bash
# ============================================================
# install.sh — Dotfiles installation script.
# Creates symbolic links from ~/dotfiles to ~/.config for each
# supported application. Initializes required repositories and
# runs first-time setup tasks such as icon generation.
#
# Usage:
#   ./install.sh [--force] [--skip-icons] [--skip-deps]
#
# Options:
#   --force       — Overwrite existing symlinks and config files.
#   --skip-icons  — Skip the icon setup step.
#   --skip-deps   — Skip the dependency check step.
#
# Exit codes:
#   0 — Installation completed successfully.
#   1 — One or more steps failed.
# ============================================================

C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RED="\033[0;31m"
C_BLUE="\033[0;34m"
C_BOLD="\033[1m"
C_RESET="\033[0m"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

# Parse options.
FORCE=false
SKIP_ICONS=false
SKIP_DEPS=false
for arg in "$@"; do
    case "$arg" in
        --force)      FORCE=true ;;
        --skip-icons) SKIP_ICONS=true ;;
        --skip-deps)  SKIP_DEPS=true ;;
    esac
done

# ── Helper functions ─────────────────────────────────────────

log_info()    { echo -e "${C_BLUE}[INFO]${C_RESET}    $1"; }
log_success() { echo -e "${C_GREEN}[OK]${C_RESET}      $1"; }
log_warning() { echo -e "${C_YELLOW}[WARNING]${C_RESET} $1"; }
log_error()   { echo -e "${C_RED}[ERROR]${C_RESET}   $1"; }
log_section() { echo -e "\n${C_BOLD}── $1 ──${C_RESET}"; }

# Create a symbolic link from dotfiles to ~/.config.
# Skips if the link already exists and --force was not passed.
make_link() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ] && [ "$FORCE" = false ]; then
        log_warning "Symlink already exists: $dest (use --force to overwrite)."
        return
    fi

    if [ -e "$dest" ] && [ ! -L "$dest" ] && [ "$FORCE" = false ]; then
        log_warning "File exists and is not a symlink: $dest (use --force to overwrite)."
        return
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    log_success "Linked: $dest → $src"
}

# ── Step 1: Dependency check ─────────────────────────────────

log_section "Dependency check"

# Required packages for the full dotfiles setup.
DEPS=(git eww hyprland hyprlock swww playerctl socat notmuch iw jq)
MISSING=()

if [ "$SKIP_DEPS" = false ]; then
    for dep in "${DEPS[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            MISSING+=("$dep")
            log_warning "Missing: $dep"
        else
            log_success "Found: $dep"
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo ""
        log_warning "Install missing packages with:"
        echo -e "  ${C_YELLOW}sudo pacman -S ${MISSING[*]}${C_RESET}"
        echo ""
        read -rp "Continue anyway? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    fi
else
    log_info "Dependency check skipped."
fi

# ── Step 2: device.conf setup ────────────────────────────────

log_section "Device configuration"

DEVICE_CONF="$HOME/.config/eww/device.conf"
DEVICE_EXAMPLE="$DOTFILES_DIR/eww/device.conf.example"

if [ ! -f "$DEVICE_CONF" ]; then
    mkdir -p "$HOME/.config/eww"
    cp "$DEVICE_EXAMPLE" "$DEVICE_CONF"
    log_success "Created device.conf from example. Please edit $DEVICE_CONF before starting eww."
else
    log_info "device.conf already exists. Skipping."
fi

# ── Step 3: Symbolic links ────────────────────────────────────

log_section "Creating symbolic links"

# Each entry maps a dotfiles source path to its ~/.config destination.
make_link "$DOTFILES_DIR/eww"     "$CONFIG_DIR/eww/config"
make_link "$DOTFILES_DIR/hypr"    "$CONFIG_DIR/hypr"
make_link "$DOTFILES_DIR/wezterm" "$CONFIG_DIR/wezterm"

# ── Step 4: material-icons repository ────────────────────────

log_section "material-icons repository"

MATERIAL_ICONS_DIR="$DOTFILES_DIR/eww/material-icons"

if [ ! -d "$MATERIAL_ICONS_DIR/.git" ]; then
    log_info "Initializing material-icons sparse clone..."
    git clone --filter=blob:none --sparse --no-checkout \
        https://github.com/google/material-design-icons.git \
        "$MATERIAL_ICONS_DIR" --quiet
    cd "$MATERIAL_ICONS_DIR" && git sparse-checkout init --cone && git checkout HEAD
    log_success "material-icons repository initialized."
else
    log_info "material-icons repository already exists. Skipping."
fi

# ── Step 5: Icon setup ────────────────────────────────────────

log_section "Icon setup"

SETUP_ICONS="$DOTFILES_DIR/eww/scripts/icon-installer.sh"

if [ "$SKIP_ICONS" = false ]; then
    if [ -x "$SETUP_ICONS" ]; then
        if [ "$FORCE" = true ]; then
            "$SETUP_ICONS" --force
        else
            "$SETUP_ICONS"
        fi
    else
        log_error "icon-installer.sh not found or not executable at $SETUP_ICONS."
        exit 1
    fi
else
    log_info "Icon setup skipped."
fi

# ── Done ──────────────────────────────────────────────────────

echo ""
echo -e "${C_BOLD}─────────────────────────────────────────${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}Installation complete.${C_RESET}"
echo -e "${C_BOLD}─────────────────────────────────────────${C_RESET}"
echo ""
echo -e "Next steps:"
echo -e "  1. Edit ${C_YELLOW}$DEVICE_CONF${C_RESET} for this machine."
echo -e "  2. Start Hyprland and verify the bar appears."
echo -e "  3. Run ${C_YELLOW}eww logs${C_RESET} if anything looks wrong."
echo ""
