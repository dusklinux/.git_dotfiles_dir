#!/bin/bash
#
# wlogout-launch - Dynamic scaling wrapper with Matugen Integration
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
ICON_DIR="${CONFIG_DIR}/icons"
MATUGEN_COLORS="$HOME/.config/matugen/generated/wlogout-colors.css"
TMP_CSS="/tmp/wlogout-${UID}-$$.css"

# Reference: 1080p @ 1.6 scale (Logical height ~675px)
REF_HEIGHT=675

# Base sizes (tuned for reference resolution)
BASE_FONT=20        
BASE_MARGIN=6       # Gap between the bar and the screen edge
BASE_HOVER_MOVE=4   # How much the button "pops" up
BASE_RADIUS=20      # Corner roundness
BASE_ACTIVE_RAD=20  

# ──────────────────────────────────────────────────────────────
# Cleanup & Dependency Check
# ──────────────────────────────────────────────────────────────
cleanup() { rm -f "$TMP_CSS" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

for cmd in hyprctl jq wlogout; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' not found" >&2
        exit 1
    fi
done

# ──────────────────────────────────────────────────────────────
# Get Monitor & Calculate Scale
# ──────────────────────────────────────────────────────────────
MONITOR_JSON=$(hyprctl monitors -j 2>/dev/null | jq -r '(.[] | select(.focused == true)) // .[0] // empty')

if [[ -z "$MONITOR_JSON" || "$MONITOR_JSON" == "null" ]]; then
    SCALE=1; HEIGHT=1080; WIDTH=1920
else
    SCALE=$(echo "$MONITOR_JSON" | jq -r '.scale // 1')
    HEIGHT=$(echo "$MONITOR_JSON" | jq -r '.height // 1080')
    WIDTH=$(echo "$MONITOR_JSON" | jq -r '.width // 1920')
fi

# Calculate Logical Resolution & Ratio
EFF_WIDTH=$(awk "BEGIN {printf \"%.0f\", $WIDTH / $SCALE}")
EFF_HEIGHT=$(awk "BEGIN {printf \"%.0f\", $HEIGHT / $SCALE}")
RATIO=$(awk "BEGIN {printf \"%.4f\", $EFF_HEIGHT / $REF_HEIGHT}")

# Clamp Ratio (0.5 - 3.0)
RATIO=$(awk "BEGIN {r = $RATIO; if (r < 0.5) r = 0.5; if (r > 3.0) r = 3.0; printf \"%.4f\", r}")

# ──────────────────────────────────────────────────────────────
# Calculate Scaled Variables
# ──────────────────────────────────────────────────────────────
FONT=$(awk "BEGIN {printf \"%.0f\", $BASE_FONT * $RATIO}")
MARGIN=$(awk "BEGIN {printf \"%.0f\", $BASE_MARGIN * $RATIO}")
HOVER_MOVE=$(awk "BEGIN {printf \"%.0f\", $BASE_HOVER_MOVE * $RATIO}")
RADIUS=$(awk "BEGIN {printf \"%.0f\", $BASE_RADIUS * $RATIO}")
ACTIVE_RADIUS=$(awk "BEGIN {printf \"%.0f\", $BASE_ACTIVE_RAD * $RATIO}")

# ──────────────────────────────────────────────────────────────
# CSS Injection (Matugen Integrated & Glitch Fix & Blur)
# ──────────────────────────────────────────────────────────────
cat > "$TMP_CSS" << EOCSS
@import url("file://${MATUGEN_COLORS}");

* {
    background-image: none;
    font-family: "JetBrainsMono Nerd Font", "Roboto", sans-serif;
    font-size: ${FONT}px;
}

window {
    /* Updated for Blur:
       We use a static RGBA here because Matugen's @scrim is solid black (#000000).
       0.5 alpha allows the background to bleed through for Hyprland's blur.
    */
    background-color: rgba(0, 0, 0, 0.5);
}

button {
    color: @on_surface;
    background-color: @surface_container_highest; 
    
    /* Critical Fixes for Artifacts */
    outline-style: none;
    border: 1px solid transparent; 
    background-clip: border-box;   
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
    box-shadow: none;
    text-shadow: none;

    /* Start with imperceptible radius to prime the renderer */
    border-radius: 1px;

    /* Surgical transition */
    transition: 
        background-color 0.2s ease-in-out,
        background-size 0.2s ease-in-out,
        border-radius 0.2s ease-in-out,
        margin 0.2s ease-in-out;
}

button:focus {
    background-color: @secondary_container;
    color: @on_secondary_container;
    background-size: 30%;
}

button:hover {
    background-color: @primary;
    color: @on_primary;
    background-size: 35%;
    border-radius: ${ACTIVE_RADIUS}px;
}

/* ─── Animation & Margins per button ─── */

/* Lock: Left rounded corners */
#lock {
    background-image: image(url("${ICON_DIR}/lock_white.png"));
    border-radius: ${RADIUS}px 1px 1px ${RADIUS}px;
    margin : ${MARGIN}px 0px ${MARGIN}px ${MARGIN}px;
}
button:hover#lock {
    margin : ${HOVER_MOVE}px 0px ${HOVER_MOVE}px ${MARGIN}px;
}

/* Logout: Flat */
#logout {
    background-image: image(url("${ICON_DIR}/logout_white.png"));
    margin : ${MARGIN}px 0px ${MARGIN}px 0px;
}
button:hover#logout {
    margin : ${HOVER_MOVE}px 0px ${HOVER_MOVE}px 0px;
}

/* Suspend: Flat */
#suspend {
    background-image: image(url("${ICON_DIR}/suspend_white.png"));
    margin : ${MARGIN}px 0px ${MARGIN}px 0px;
}
button:hover#suspend {
    margin : ${HOVER_MOVE}px 0px ${HOVER_MOVE}px 0px;
}

/* Shutdown: Flat */
#shutdown {
    background-image: image(url("${ICON_DIR}/shutdown_white.png"));
    margin : ${MARGIN}px 0px ${MARGIN}px 0px;
}
button:hover#shutdown {
    margin : ${HOVER_MOVE}px 0px ${HOVER_MOVE}px 0px;
}

/* Soft-reboot: Flat */
#soft-reboot {
    background-image: image(url("${ICON_DIR}/soft-reboot_white.png"));
    margin : ${MARGIN}px 0px ${MARGIN}px 0px;
}
button:hover#soft-reboot {
    margin : ${HOVER_MOVE}px 0px ${HOVER_MOVE}px 0px;
}

/* Reboot: Right rounded corners */
#reboot {
    background-image: image(url("${ICON_DIR}/reboot_white.png"));
    border-radius: 1px ${RADIUS}px ${RADIUS}px 1px;
    margin : ${MARGIN}px ${MARGIN}px ${MARGIN}px 0px;
}
button:hover#reboot {
    margin : ${HOVER_MOVE}px ${MARGIN}px ${HOVER_MOVE}px 0px;
}
EOCSS

# ──────────────────────────────────────────────────────────────
# Launch
# ──────────────────────────────────────────────────────────────
exec wlogout \
    --layout "$LAYOUT_FILE" \
    --css "$TMP_CSS" \
    --buttons-per-row 6 \
    --column-spacing 0 \
    --row-spacing 0 \
    "$@"
