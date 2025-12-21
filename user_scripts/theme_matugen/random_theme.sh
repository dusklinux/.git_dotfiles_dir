#!/usr/bin/env bash
#
# set_random_wallpaper.sh
#
# Selects a random wallpaper, sets it with swww, and updates matugen colors.
# Designed for Arch Linux with Hyprland/UWSM on NVIDIA/Intel hybrid hardware.

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# Configuration
# ══════════════════════════════════════════════════════════════════════════════

readonly WALLPAPER_DIR="${HOME}/Pictures/wallpapers"

# Array eliminates word-splitting issues and shellcheck warnings
readonly -a SWWW_OPTS=(
    --transition-type grow
    --transition-duration 2
    --transition-fps 60
)

# Daemon init: retry count × 0.2s = max wait time (25 × 0.2 = 5 seconds)
readonly DAEMON_INIT_RETRIES=25

# ══════════════════════════════════════════════════════════════════════════════
# Functions
# ══════════════════════════════════════════════════════════════════════════════

die() {
    printf '%s: %s\n' "${0##*/}" "$1" >&2
    exit 1
}

# ══════════════════════════════════════════════════════════════════════════════
# Prerequisite Validation
# ══════════════════════════════════════════════════════════════════════════════

# Removed 'find' and 'shuf' as they are no longer required
for cmd in swww matugen uwsm-app; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: '$cmd'"
done

[[ -d "$WALLPAPER_DIR" ]] || die "Directory does not exist: '$WALLPAPER_DIR'"
[[ -r "$WALLPAPER_DIR" ]] || die "Directory is not readable: '$WALLPAPER_DIR'"

# ══════════════════════════════════════════════════════════════════════════════
# Daemon Initialization
# ══════════════════════════════════════════════════════════════════════════════

if ! swww query >/dev/null 2>&1; then
    # Start daemon via uwsm for proper session/cgroup scoping
    uwsm-app -- swww-daemon >/dev/null 2>&1 &
    
    # Poll for readiness instead of arbitrary sleep
    for ((i = 0; i < DAEMON_INIT_RETRIES; i++)); do
        swww query >/dev/null 2>&1 && break
        sleep 0.2
    done
    
    # Final verification
    swww query >/dev/null 2>&1 || die "swww daemon failed to initialize"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Wallpaper Selection (Bash 5+ Native)
# ══════════════════════════════════════════════════════════════════════════════

# Enable recursive globbing (globstar) and nullglob (empty array if no matches)
shopt -s globstar nullglob nocaseglob

# Load all matching files into an array
# Note: Using immediate expansion is faster than 'find' for typical wallpaper counts (<10k)
wallpapers=( "$WALLPAPER_DIR"/**/*.{jpg,jpeg,png,webp,gif} )

# Check if array is empty
if (( ${#wallpapers[@]} == 0 )); then
    die "No image files found in '$WALLPAPER_DIR'"
fi

# Select a random index using Bash arithmetic
target_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"

[[ -r "$target_wallpaper" ]] || die "Image not readable: '$target_wallpaper'"

# ══════════════════════════════════════════════════════════════════════════════
# Execution
# ══════════════════════════════════════════════════════════════════════════════

# Set wallpaper (blocks until transition completes)
swww img "$target_wallpaper" "${SWWW_OPTS[@]}"

# Generate color scheme asynchronously (setsid fully detaches the process)
    setsid uwsm-app -- matugen --mode dark --type scheme-fruit-salad image "$target_wallpaper" \
    >/dev/null 2>&1 &

exit 0
