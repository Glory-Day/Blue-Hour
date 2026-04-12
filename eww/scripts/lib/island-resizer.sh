#!/bin/bash
# ============================================================
# island-resizer.sh — Island minimum width constants.
# Defines the minimum pixel width each island requires in
# full and compact display modes.
# Source this file to load constants into the calling script.
#
# Usage:
#   source "$(dirname "$0")/lib/island-resizer.sh"
#
# All values are in pixels and based on the default font size
# of 13px defined in styles/_variables.scss.
# Update these values if EWW_FONT_SIZE changes in device.conf.
# ============================================================

# ── OS island ────────────────────────────────────────────────
# Full:    icon + "Arch" text.
# Compact: icon only.
readonly ISLAND_OS_FULL=80
readonly ISLAND_OS_COMPACT=36

# ── Workspace island ─────────────────────────────────────────
# Does not change between full and compact modes.
# Width depends on number of active workspaces (max 10).
# A safe maximum of 10 dots is used for calculation.
readonly ISLAND_WORKSPACE_FULL=110
readonly ISLAND_WORKSPACE_COMPACT=110

# ── Time-Date island ─────────────────────────────────────────
# Full:    HH:MM · Day, Mon DD
# Compact: HH:MM only (date hidden).
readonly ISLAND_TIME_FULL=160
readonly ISLAND_TIME_COMPACT=70

# ── Music island ─────────────────────────────────────────────
# Music island is excluded from compact_level calculations.
# It uses its own visibility (playing/paused) independently.
# When visible it shows icon only in compact mode.
readonly ISLAND_MUSIC_FULL=36
readonly ISLAND_MUSIC_COMPACT=36

# ── Messages island ──────────────────────────────────────────
# Shows icon + badge for Discord, Gmail, Slack.
# Does not change between full and compact modes.
readonly ISLAND_MESSAGES_FULL=90
readonly ISLAND_MESSAGES_COMPACT=90

# ── Network island (part of System island) ───────────────────
# Full:    icon + SSID name or "LAN".
# Compact: icon only.
readonly ISLAND_NETWORK_FULL=120
readonly ISLAND_NETWORK_COMPACT=36

# ── Battery island (part of System island, laptop only) ──────
# Full:    icon + percentage.
# Compact: icon only.
readonly ISLAND_BATTERY_FULL=70
readonly ISLAND_BATTERY_COMPACT=36

# ── Power island ─────────────────────────────────────────────
# Does not change between full and compact modes.
readonly ISLAND_POWER_FULL=36
readonly ISLAND_POWER_COMPACT=36

# ── Gap between islands ──────────────────────────────────────
# Matches $island-gap in styles/_variables.scss converted to px.
readonly ISLAND_GAP=7

# ── Bar margin ───────────────────────────────────────────────
# Subtracted from monitor width to get available bar width.
# Accounts for bar padding and hyprland.conf gaps_out.
readonly BAR_MARGIN=16
