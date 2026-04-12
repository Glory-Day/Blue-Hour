#!/bin/bash
# ============================================================
# messages.sh — Unread message counter for EWW.
# Reports unread counts for Discord, Gmail, and Slack.
# Each source uses a layered fallback strategy so the script
# works at every stage of the setup process.
#
# Discord fallback order:
#   1. ~/.cache/eww/discord_unread  (written by Vencord plugin)
#   2. 0 (Vesktop running but plugin not yet installed)
#
# Gmail fallback order:
#   1. notmuch count (requires lieer sync to be configured)
#   2. ~/.cache/eww/gmail_unread    (manual override file)
#   3. 0
#
# Slack fallback order:
#   1. Slack API via SLACK_TOKEN in device.conf
#   2. ~/.cache/eww/slack_unread    (manual override file)
#   3. 0
#
# Output (JSON):
#   discord.unread — integer unread count.
#   gmail.unread   — integer unread count.
#   slack.unread   — integer unread count.
# ============================================================

CACHE_DIR="$HOME/.cache/eww"
DEVICE_CONF="$HOME/.config/eww/device.conf"

# Create the cache directory if it does not exist yet.
mkdir -p "$CACHE_DIR"

# Load device.conf to read the Slack API token.
# The token is stored there to keep it out of version control.
SLACK_TOKEN=""
[ -f "$DEVICE_CONF" ] && source "$DEVICE_CONF"

# ── Helper: read integer from cache file ─────────────────────

# Returns the integer stored in a cache file, or 0 if the file
# does not exist or contains a non-integer value.
read_cache() {
    local file="$1"
    if [ -f "$file" ]; then
        local val
        val=$(cat "$file" 2>/dev/null | tr -d '[:space:]')
        [[ "$val" =~ ^[0-9]+$ ]] && echo "$val" && return
    fi
    echo 0
}

# ── Discord ──────────────────────────────────────────────────

# The Vencord plugin writes the unread count to this file.
# Until the plugin is installed the count stays at 0.
DISCORD_COUNT=$(read_cache "$CACHE_DIR/discord_unread")

# ── Gmail ────────────────────────────────────────────────────

GMAIL_COUNT=0

# Attempt to query notmuch if it is installed and a database exists.
if command -v notmuch &>/dev/null && notmuch count &>/dev/null 2>&1; then
    COUNT=$(notmuch count tag:unread and tag:inbox 2>/dev/null)
    [[ "$COUNT" =~ ^[0-9]+$ ]] && GMAIL_COUNT=$COUNT
fi

# Fall back to the cache file if notmuch returned nothing.
if [ "$GMAIL_COUNT" -eq 0 ]; then
    GMAIL_COUNT=$(read_cache "$CACHE_DIR/gmail_unread")
fi

# ── Slack ─────────────────────────────────────────────────────

SLACK_COUNT=0

# Query the Slack API if a token is available in device.conf.
# Uses the users.counts endpoint which returns DM and channel unreads.
if [ -n "$SLACK_TOKEN" ]; then
    RESPONSE=$(curl -sf \
        -H "Authorization: Bearer $SLACK_TOKEN" \
        "https://slack.com/api/users.counts" 2>/dev/null)

    if echo "$RESPONSE" | grep -q '"ok":true'; then
        SLACK_COUNT=$(echo "$RESPONSE" \
            | python3 -c "
import sys, json
d = json.load(sys.stdin)
total = 0
for ch in d.get('channels', []):
    total += ch.get('mention_count', 0)
for im in d.get('ims', []):
    total += im.get('dm_count', 0)
print(total)
" 2>/dev/null || echo 0)
    fi
fi

# Fall back to the cache file if the API call failed or no token exists.
if [ "$SLACK_COUNT" -eq 0 ]; then
    SLACK_COUNT=$(read_cache "$CACHE_DIR/slack_unread")
fi

# ── Output ───────────────────────────────────────────────────

echo "{\"discord\":{\"unread\":$DISCORD_COUNT},\"gmail\":{\"unread\":$GMAIL_COUNT},\"slack\":{\"unread\":$SLACK_COUNT}}"
