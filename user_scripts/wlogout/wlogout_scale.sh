#!/bin/bash
#
# wlogout-launch - Dynamic scaling wrapper for wlogout
# Calculates appropriate UI sizes based on current monitor configuration
#

set -euo pipefail

# Kill existing instance if running
if pidof wlogout &>/dev/null; then
    pkill wlogout
    exit 0
fi

# ──────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wlogout"
LAYOUT_FILE="${CONFIG_DIR}/layout"
TMP_CSS="/tmp/wlogout-${UID}-$$.css"

# Reference: Your setup looks good at 1080p with 1.6 scale
# Logical height at that config = 1080 / 1.6 = 675
REF_HEIGHT=675

# Base sizes (tuned for reference resolution)
BASE_FONT=28
BASE_MARGIN=10
BASE_RADIUS=12
BASE_PADDING=16
BASE_HOVER_RADIUS=16

# ──────────────────────────────────────────────────────────────
# Cleanup on exit
# ──────────────────────────────────────────────────────────────
cleanup() {
    rm -f "$TMP_CSS" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ──────────────────────────────────────────────────────────────
# Dependency check
# ──────────────────────────────────────────────────────────────
for cmd in hyprctl jq wlogout; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' not found" >&2
        exit 1
    fi
done

# ──────────────────────────────────────────────────────────────
# Get focused monitor information
# ──────────────────────────────────────────────────────────────
MONITOR_JSON=$(hyprctl monitors -j 2>/dev/null | jq -r '
    (.[] | select(.focused == true)) // .[0] // empty
')

if [[ -z "$MONITOR_JSON" || "$MONITOR_JSON" == "null" ]]; then
    echo "Warning: Could not get monitor info, using defaults" >&2
    SCALE=1.6
    HEIGHT=1080
    WIDTH=1920
else
    SCALE=$(echo "$MONITOR_JSON" | jq -r '.scale // 1')
    HEIGHT=$(echo "$MONITOR_JSON" | jq -r '.height // 1080')
    WIDTH=$(echo "$MONITOR_JSON" | jq -r '.width // 1920')
fi

# ──────────────────────────────────────────────────────────────
# Calculate effective (logical) resolution
# ──────────────────────────────────────────────────────────────
EFF_WIDTH=$(awk "BEGIN {printf \"%.0f\", $WIDTH / $SCALE}")
EFF_HEIGHT=$(awk "BEGIN {printf \"%.0f\", $HEIGHT / $SCALE}")

# Scaling ratio relative to reference
RATIO=$(awk "BEGIN {printf \"%.4f\", $EFF_HEIGHT / $REF_HEIGHT}")

# Clamp ratio to prevent extreme values
RATIO=$(awk "BEGIN {
    r = $RATIO
    if (r < 0.5) r = 0.5
    if (r > 3.0) r = 3.0
    printf \"%.4f\", r
}")

# ──────────────────────────────────────────────────────────────
# Calculate scaled dimensions
# ──────────────────────────────────────────────────────────────
FONT=$(awk "BEGIN {printf \"%.0f\", $BASE_FONT * $RATIO}")
MARGIN=$(awk "BEGIN {printf \"%.0f\", $BASE_MARGIN * $RATIO}")
RADIUS=$(awk "BEGIN {printf \"%.0f\", $BASE_RADIUS * $RATIO}")
PADDING=$(awk "BEGIN {printf \"%.0f\", $BASE_PADDING * $RATIO}")
HOVER_RADIUS=$(awk "BEGIN {printf \"%.0f\", $BASE_HOVER_RADIUS * $RATIO}")

# ──────────────────────────────────────────────────────────────
# Calculate margins to CENTER the button grid
# We want the button area to occupy ~60% width and ~40% height
# ──────────────────────────────────────────────────────────────
MARGIN_H_PCT=20   # Percentage of screen width for left/right margin
MARGIN_V_PCT=30   # Percentage of screen height for top/bottom margin

MARGIN_LEFT=$(awk "BEGIN {printf \"%.0f\", $EFF_WIDTH * $MARGIN_H_PCT / 100}")
MARGIN_RIGHT=$MARGIN_LEFT
MARGIN_TOP=$(awk "BEGIN {printf \"%.0f\", $EFF_HEIGHT * $MARGIN_V_PCT / 100}")
MARGIN_BOTTOM=$MARGIN_TOP

# ──────────────────────────────────────────────────────────────
# Button layout: 3 per row = 2 rows of 3 (balanced grid)
# ──────────────────────────────────────────────────────────────
BUTTONS_PER_ROW=3

# ──────────────────────────────────────────────────────────────
# Generate CSS (GTK-compatible only!)
# ──────────────────────────────────────────────────────────────
cat > "$TMP_CSS" << EOCSS
/*
 * wlogout dynamic CSS
 * Monitor: ${WIDTH}×${HEIGHT} @ scale ${SCALE}
 * Logical: ${EFF_WIDTH}×${EFF_HEIGHT}
 * Ratio: ${RATIO}
 */

* {
    all: unset;
    background-image: none;
}

window {
    background-color: rgba(10, 10, 14, 0.88);
}

button {
    font-family: "Material Symbols Outlined", "Symbols Nerd Font", monospace;
    font-size: ${FONT}pt;

    padding: ${PADDING}pt;
    margin: ${MARGIN}pt;

    background-color: rgba(45, 45, 60, 0.55);
    color: rgba(255, 255, 255, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: ${RADIUS}pt;

    transition: 200ms ease-in-out;
}

button:focus {
    background-color: rgba(60, 60, 80, 0.65);
    color: rgba(255, 255, 255, 0.95);
}

button:hover {
    background-color: rgba(75, 75, 100, 0.70);
    border-radius: ${HOVER_RADIUS}pt;
    color: #FFFFFF;
}

button:active {
    background-color: rgba(95, 95, 120, 0.75);
}

/* ═══════════════════════════════════════════════════════════
   Semantic Colors
   ═══════════════════════════════════════════════════════════ */

#shutdown:hover, #shutdown:focus {
    background-color: rgba(180, 60, 60, 0.55);
    color: #FFDDDD;
}

#reboot:hover, #reboot:focus,
#soft_reboot:hover, #soft_reboot:focus {
    background-color: rgba(180, 130, 50, 0.55);
    color: #FFF0DD;
}

#suspend:hover, #suspend:focus {
    background-color: rgba(50, 120, 180, 0.55);
    color: #DDEEFF;
}

#lock:hover, #lock:focus {
    background-color: rgba(50, 170, 150, 0.55);
    color: #DDFFFA;
}

#logout:hover, #logout:focus {
    background-color: rgba(130, 60, 180, 0.55);
    color: #F0DDFF;
}
EOCSS

# ──────────────────────────────────────────────────────────────
# Debug output
# ──────────────────────────────────────────────────────────────
if [[ "${DEBUG:-}" == "1" ]]; then
    echo "═══════════════════════════════════════════"
    echo "Monitor:     ${WIDTH}×${HEIGHT} @ scale ${SCALE}"
    echo "Logical:     ${EFF_WIDTH}×${EFF_HEIGHT}"
    echo "Ratio:       ${RATIO}"
    echo "───────────────────────────────────────────"
    echo "Font:        ${FONT}pt"
    echo "Padding:     ${PADDING}pt"
    echo "Margin:      ${MARGIN}pt"
    echo "Radius:      ${RADIUS}pt / ${HOVER_RADIUS}pt"
    echo "───────────────────────────────────────────"
    echo "Layout:      ${BUTTONS_PER_ROW} per row"
    echo "Margins:     T:${MARGIN_TOP} B:${MARGIN_BOTTOM} L:${MARGIN_LEFT} R:${MARGIN_RIGHT}"
    echo "═══════════════════════════════════════════"
fi

# ──────────────────────────────────────────────────────────────
# Launch wlogout with calculated parameters
# ──────────────────────────────────────────────────────────────
exec wlogout \
    --layout "$LAYOUT_FILE" \
    --css "$TMP_CSS" \
    --buttons-per-row "$BUTTONS_PER_ROW" \
    --margin-top "$MARGIN_TOP" \
    --margin-bottom "$MARGIN_BOTTOM" \
    --margin-left "$MARGIN_LEFT" \
    --margin-right "$MARGIN_RIGHT" \
    "$@"
