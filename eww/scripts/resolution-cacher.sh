#!/bin/bash
# ============================================================
# resolution-cacher.sh — Monitor resolution cache writer.
# Reads current monitor resolutions via hyprctl and writes
# them to ~/.cache/eww/monitor-N files as plain text.
# Called by monitor-listener.sh on startup and on resolution
# change events.
#
# Cache file format:
#   ~/.cache/eww/monitor-0  — "990x910"
#   ~/.cache/eww/monitor-1  — "1920x1080"
#
# Exit codes:
#   0 — Cache written successfully.
#   1 — hyprctl not available.
# ============================================================

CACHE_DIR="$HOME/.cache/eww"

C_GREEN="\033[0;32m"
C_RED="\033[0;31m"
C_BLUE="\033[0;34m"
C_RESET="\033[0m"

log_info()    { echo -e "${C_BLUE}[resolution-cacher]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[resolution-cacher]${C_RESET} $1"; }
log_error()   { echo -e "${C_RED}[resolution-cacher]${C_RESET} $1"; }

# ── Validate dependencies ────────────────────────────────────

if ! command -v hyprctl &>/dev/null; then
    log_error "hyprctl not found."
    exit 1
fi

# ── Create cache directory ───────────────────────────────────

mkdir -p "$CACHE_DIR"

# ── Read and cache monitor resolutions ──────────────────────

# Query all connected monitors from Hyprland.
# For each monitor, account for rotation (transform 1,3,5,7).
python3 << 'PYEOF'
import subprocess, json, os

cache_dir = os.path.expanduser("~/.cache/eww")
result = subprocess.run(
    ["hyprctl", "monitors", "-j"],
    capture_output=True, text=True
)

monitors = json.loads(result.stdout)

for i, m in enumerate(monitors):
    t = m.get("transform", 0)
    if t in [1, 3, 5, 7]:
        w, h = m["height"], m["width"]
    else:
        w, h = m["width"], m["height"]

    cache_file = os.path.join(cache_dir, f"monitor-{i}")
    with open(cache_file, "w") as f:
        f.write(f"{w}x{h}")

print(f"Cached {len(monitors)} monitor(s).")
PYEOF

log_success "Monitor resolutions cached to $CACHE_DIR."
