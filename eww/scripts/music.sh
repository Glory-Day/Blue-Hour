#!/bin/bash
# ============================================================
# music.sh — Music player state reporter for EWW.
# Supports MPD (via playerctl) and YouTube Music (via browser
# tab MPRIS). Spotify is intentionally excluded.
# Returns playing:false when no active player is found so the
# music island hides itself automatically.
#
# Output (JSON):
#   playing  — true if a player is active, false otherwise.
#   title    — track title, truncated to 40 characters.
#   artist   — artist name, truncated to 24 characters.
#   player   — short player name (mpd, firefox, chromium, etc).
#   icon     — SVG icon alias matching a file in icons/.
#   status   — "Playing" or "Paused".
# ============================================================

NULL='{"playing":false,"title":"","artist":"","player":"","icon":"music-idle","status":""}'

# Return early if playerctl is not installed.
if ! command -v playerctl &>/dev/null; then
    echo "$NULL"
    exit 0
fi

# ── Player selection ─────────────────────────────────────────

# Select the most relevant active player using the following priority:
#   1. Any player with status "Playing", excluding Spotify.
#   2. Any player with status "Paused", excluding Spotify.
# Spotify is excluded by filtering it from the player list.

pick_player() {
    local target_status="$1"
    playerctl -l 2>/dev/null \
    | grep -iv "spotify" \
    | while read -r p; do
        local s
        s=$(playerctl -p "$p" status 2>/dev/null)
        if [ "$s" = "$target_status" ]; then
            echo "$p"
            return
        fi
    done
}

PLAYER=$(pick_player "Playing")
[ -z "$PLAYER" ] && PLAYER=$(pick_player "Paused")

if [ -z "$PLAYER" ]; then
    echo "$NULL"
    exit 0
fi

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
if [ "$STATUS" != "Playing" ] && [ "$STATUS" != "Paused" ]; then
    echo "$NULL"
    exit 0
fi

# ── Metadata ─────────────────────────────────────────────────

TITLE=$(playerctl -p "$PLAYER" metadata title 2>/dev/null \
        | head -c 40 | sed 's/\\/\\\\/g; s/"/\\"/g')
ARTIST=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null \
         | head -c 24 | sed 's/\\/\\\\/g; s/"/\\"/g')

# Fall back to albumArtist if artist is empty.
# YouTube Music often omits the artist field in MPRIS metadata.
if [ -z "$ARTIST" ]; then
    ARTIST=$(playerctl -p "$PLAYER" metadata xesam:albumArtist 2>/dev/null \
             | head -c 24 | sed 's/\\/\\\\/g; s/"/\\"/g')
fi

# Fall back to the filename if title is empty.
if [ -z "$TITLE" ]; then
    TITLE=$(playerctl -p "$PLAYER" metadata xesam:url 2>/dev/null \
            | sed 's|.*/||; s/%20/ /g; s/\.[^.]*$//' \
            | head -c 40 | sed 's/"/\\"/g')
fi

# ── YouTube Music detection ──────────────────────────────────

# YouTube Music runs as a browser tab and reports via MPRIS.
# It is identified by checking the page URL for music.youtube.com
# or by finding "YouTube Music" in the track title metadata.
IS_YTM=false
case "$PLAYER" in
    *firefox*|*Firefox*|*chromium*|*chrome*|*Chrome*|*brave*|*Brave*)
        if playerctl -p "$PLAYER" metadata xesam:url 2>/dev/null \
           | grep -qi "music\.youtube\.com"; then
            IS_YTM=true
        elif echo "$TITLE" | grep -qi "youtube music"; then
            IS_YTM=true
        fi
        ;;
esac

# YouTube Music sometimes encodes "Artist - Title" in the title field.
# Split it into separate fields when the artist field is empty.
if [ "$IS_YTM" = true ] && [ -z "$ARTIST" ]; then
    if echo "$TITLE" | grep -q " - "; then
        ARTIST=$(echo "$TITLE" | sed 's/ - .*//' | head -c 24)
        TITLE=$(echo  "$TITLE" | sed 's/^.* - //' | head -c 40)
    fi
fi

# ── Icon selection ───────────────────────────────────────────

if [ "$IS_YTM" = true ]; then
    ICON="music-play"
else
    case "$PLAYER" in
        *mpd*|*MPD*|*mopidy*) ICON="music-play" ;;
        *vlc*)                 ICON="music-play" ;;
        *)                     ICON="music-play" ;;
    esac
fi

# Show the pause icon when the player is paused.
[ "$STATUS" = "Paused" ] && ICON="music-pause"

# ── Player name normalisation ────────────────────────────────

PLAYER_SHORT=$(echo "$PLAYER" \
    | sed 's/\.instance[0-9]*//' \
    | cut -d'.' -f1 \
    | sed 's/chromium-browser/chromium/; s/google-chrome/chrome/')

echo "{\"playing\":true,\"title\":\"$TITLE\",\"artist\":\"$ARTIST\",\"player\":\"$PLAYER_SHORT\",\"icon\":\"$ICON\",\"status\":\"$STATUS\"}"
