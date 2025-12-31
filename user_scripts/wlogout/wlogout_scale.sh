#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  wlogout-launch - Dynamic Scaling & Theming Wrapper for Hyprland
#  Optimized by: Elite DevOps & Arch Architect
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 1. Configuration & Constants (Read-Only)
# ──────────────────────────────────────────────────────────────
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wlogout"
readonly LAYOUT_FILE="${CONFIG_DIR}/layout"
readonly ICON_DIR="${CONFIG_DIR}/icons"
readonly MATUGEN_COLORS="${XDG_CONFIG_HOME:-$HOME/.config}/matugen/generated/wlogout-colors.css"
readonly TMP_CSS="/tmp/wlogout-${UID}.css"

# Reference: 1080p @ 1.0 scale settings
readonly REF_HEIGHT=1080
readonly BASE_FONT_SIZE=20
readonly BASE_BUTTON_RAD=20    # Radius for ALL buttons now (Floating Dock style)
readonly BASE_ACTIVE_RAD=25
readonly BASE_MARGIN=50        # Vertical margin for the "floating" look
readonly BASE_HOVER_OFFSET=15  # Expansion size on hover
readonly BASE_COL_SPACING=2   # Gap between buttons (Scaled)

# ──────────────────────────────────────────────────────────────
# 2. Dependency & Environment Checks
# ──────────────────────────────────────────────────────────────
# Check context
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "ERROR: Not running inside Hyprland." >&2
    exit 1
fi

# Check dependencies (removed unused 'envsubst')
for cmd in hyprctl jq wlogout; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required command '$cmd' not found." >&2
        exit 1
    fi
done

# Check layout file
if [[ ! -f "$LAYOUT_FILE" ]]; then
    echo "ERROR: Layout file not found at $LAYOUT_FILE" >&2
    exit 1
fi

# Atomic Toggle: Kill if running and exit
if pkill -x "wlogout"; then
    exit 0
fi

# Ensure cleanup happens on EXIT (Must not use 'exec' later)
trap 'rm -f "$TMP_CSS"' EXIT

# ──────────────────────────────────────────────────────────────
# 3. Monitor Detection & Math (Hardened)
# ──────────────────────────────────────────────────────────────
# Robust jq query: Focused -> First Available -> Default Fallback
MON_DATA=$(hyprctl monitors -j 2>/dev/null | jq -r '
    (first(.[] | select(.focused)) // .[0] // {height: 1080, scale: 1}) 
    | "\(.height) \(.scale)"
')

# Default if jq fails entirely
if [[ -z "$MON_DATA" ]]; then
    MON_DATA="1080 1"
fi

read -r HEIGHT SCALE <<< "$MON_DATA"

# Sanity check: prevent division by zero in awk
if [[ "$SCALE" == "0" || "$SCALE" == "0.0" || -z "$SCALE" ]]; then
    SCALE=1
fi

# Calculate all dynamic values in one awk pass
# Uses ternary operators for clamping ratio (0.5 to 2.0)
CALC_VARS=$(awk -v h="$HEIGHT" -v s="$SCALE" -v rh="$REF_HEIGHT" \
                -v f="$BASE_FONT_SIZE" -v br="$BASE_BUTTON_RAD" \
                -v ar="$BASE_ACTIVE_RAD" -v m="$BASE_MARGIN" \
                -v ho="$BASE_HOVER_OFFSET" -v cs="$BASE_COL_SPACING" '
BEGIN {
    ratio = (h / s) / rh;
    ratio = (ratio < 0.5) ? 0.5 : (ratio > 2.0 ? 2.0 : ratio);
    
    printf "%d %d %d %d %d %d", 
        int(f * ratio), int(br * ratio), int(ar * ratio), 
        int(m * ratio), int(ho * ratio), int(cs * ratio)
}')

read -r FONT_SIZE BTN_RAD ACT_RAD MARGIN HOVER_OFFSET COL_SPACING <<< "$CALC_VARS"

# Calculate the "shrunk" margin for hover state
HOVER_MARGIN=$(( MARGIN - HOVER_OFFSET ))

# ──────────────────────────────────────────────────────────────
# 4. CSS Generation
# ──────────────────────────────────────────────────────────────
cat > "$TMP_CSS" <<EOF
/* Import Matugen Colors */
@import url("file://${MATUGEN_COLORS}");

/* Base Window Configuration */
window {
    background-color: rgba(0, 0, 0, 0.5);
    font-family: "JetBrainsMono Nerd Font", "Roboto", sans-serif;
    font-size: ${FONT_SIZE}px;
}

/* Button Configuration */
button {
    /* Theme Integration: @secondary_container (Dark Blue/Purple) */
    color: @on_secondary_container;
    background-color: @secondary_container;
    
    outline-style: none;
    border: none;
    border-radius: ${BTN_RAD}px;
    box-shadow: none;
    text-shadow: none;
    
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;

    /* Animation: Snappy Bounce Effect */
    transition: 
        background-size 0.3s cubic-bezier(.55, 0.0, .28, 1.682),
        margin 0.3s cubic-bezier(.55, 0.0, .28, 1.682),
        border-radius 0.3s cubic-bezier(.55, 0.0, .28, 1.682),
        background-color 0.3s ease;
}

button:focus {
    /* Keyboard Focus: @tertiary_container for contrast */
    background-color: @tertiary_container;
    color: @on_tertiary_container;
    background-size: 30%;
}

button:hover {
    /* Hover: @primary for maximum pop */
    background-color: @primary;
    color: @on_primary;
    background-size: 40%;
    border-radius: ${ACT_RAD}px;
}

/* ──────────────────────────────────────────────────────────────
   Specific Button Logic
   ────────────────────────────────────────────────────────────── */

#lock {
    background-image: image(url("${ICON_DIR}/lock_white.png"), url("/usr/share/wlogout/icons/lock.png"));
    margin: ${MARGIN}px 0;
}
button:hover#lock { margin: ${HOVER_MARGIN}px 0; }

#logout {
    background-image: image(url("${ICON_DIR}/logout_white.png"), url("/usr/share/wlogout/icons/logout.png"));
    margin: ${MARGIN}px 0;
}
button:hover#logout { margin: ${HOVER_MARGIN}px 0; }

#suspend {
    background-image: image(url("${ICON_DIR}/suspend_white.png"), url("/usr/share/wlogout/icons/suspend.png"));
    margin: ${MARGIN}px 0;
}
button:hover#suspend { margin: ${HOVER_MARGIN}px 0; }

#shutdown {
    background-image: image(url("${ICON_DIR}/shutdown_white.png"), url("/usr/share/wlogout/icons/shutdown.png"));
    margin: ${MARGIN}px 0;
}
button:hover#shutdown { margin: ${HOVER_MARGIN}px 0; }

#soft-reboot {
    background-image: image(url("${ICON_DIR}/soft-reboot_white.png"), url("/usr/share/wlogout/icons/reboot.png"));
    margin: ${MARGIN}px 0;
}
button:hover#soft-reboot { margin: ${HOVER_MARGIN}px 0; }

#reboot {
    background-image: image(url("${ICON_DIR}/reboot_white.png"), url("/usr/share/wlogout/icons/reboot.png"));
    margin: ${MARGIN}px 0;
}
button:hover#reboot { margin: ${HOVER_MARGIN}px 0; }
EOF

# ──────────────────────────────────────────────────────────────
# 5. Launch
# ──────────────────────────────────────────────────────────────
# NOTE: We do NOT use 'exec' here. We want bash to wait for wlogout
# to finish so that the 'trap' above can clean up the CSS file.
wlogout \
    --layout "$LAYOUT_FILE" \
    --css "$TMP_CSS" \
    --protocol layer-shell \
    --buttons-per-row 6 \
    --column-spacing "$COL_SPACING" \
    --row-spacing 0 \
    "$@"
