#!/bin/bash

# -----------------------------------------------------------------------------
# POWER SAVER MODE - ASUS TUF F15 (Hyprland/UWSM)
# -----------------------------------------------------------------------------

# Stop script on error is NOT set (set -e) because we want to continue 
# even if pkill fails or monitors aren't running.

# Check for gum
if ! command -v gum &> /dev/null; then
    echo "Error: 'gum' is not installed. Please run 'sudo pacman -S gum'"
    exit 1
fi

# Flag to track if we need to switch theme later
SWITCH_THEME_LATER=false

# Visual helpers
log_step() {
    gum style --foreground 212 ":: $1"
}

log_warn() {
    gum style --foreground 208 "!! $1"
}

# Banner
clear
gum style \
    --border double \
    --margin "1" \
    --padding "1 2" \
    --border-foreground 212 \
    --foreground 212 \
    "ASUS TUF F15: POWER SAVER MODE"

# --- 1. Interactive Light Mode Prompt ---
if [ -t 0 ]; then
    echo ""
    gum style --foreground 245 --italic \
        "Rationale: Light mode often allows for lower backlight brightness" \
        "while maintaining readability in well-lit environments."
    
    echo ""
    if gum confirm "Switch to Light Mode?" --affirmative "Yes, switch it" --negative "No, stay dark"; then
        log_step "Theme switch queued for the end of the script."
        SWITCH_THEME_LATER=true
    else
        log_step "Keeping current theme."
    fi
else
    # Fallback for non-interactive usage
    log_step "Non-interactive shell detected. Skipping Light Mode prompt."
fi

# --- 2. Visual Effects ---
echo ""
gum spin --spinner dot --title "Disabling Hyprland effects..." -- sleep 1.5
if [ -f "$HOME/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh" ]; then
    uwsm-app -- "$HOME/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh" off
fi

if command -v hyprshade &> /dev/null; then
    uwsm-app -- hyprshade off
fi
log_step "Visual effects disabled."

# --- 3. User Level Cleanup ---
gum spin --spinner dot --title "Cleaning up resources..." -- sleep 1
# Suppress output of pkill to keep UI clean
pkill btop &> /dev/null || true
pkill nvtop &> /dev/null || true

if command -v playerctl &> /dev/null; then
    playerctl -a pause
fi
log_step "Resource monitors killed & media paused."

# --- 4. Screen & Audio ---
# Brightness
gum spin --spinner points --title "Lowering brightness to 1%..." -- brightnessctl set 1% > /dev/null

# Volume Logic
current_vol=$(pamixer --get-volume)
if [ "$current_vol" -gt 50 ]; then
    gum spin --spinner points --title "Volume is $current_vol%. Lowering to 50%..." -- pamixer --set-volume 50
    log_step "Volume capped at 50%."
else
    log_step "Volume is $current_vol%. Leaving it unchanged."
fi

# --- 5. Hyprland Config ---
gum spin --spinner line --title "Disabling Animations & Reloading Hyprland..." -- \
    sh -c "ln -nfs '$HOME/.config/hypr/source/animations/disable.conf' '$HOME/.config/hypr/source/animations/active/active.conf' && hyprctl reload"
log_step "Hyprland config reloaded."

# --- 6. Root Level Termination (The Critical Part) ---
echo ""
gum style \
    --border normal \
    --border-foreground 196 \
    --padding "0 1" \
    --foreground 196 \
    "PRIVILEGE ESCALATION REQUIRED" \
    "Need root for TLP and Process Terminator."

echo ""

# We CANNOT wrap sudo in gum spin because it hides the password prompt.
# We run sudo -v first to cache credentials interactively.
if sudo -v; then
    # Sudo success - visual spacer
    echo ""
    
    # --- CRITICAL: BLUETOOTH BLOCK ---
    # As per your specific instruction: Block ONLY after authentication 
    # to prevent locking out Bluetooth keyboards during password entry.
    gum spin --spinner globe --title "Blocking Bluetooth..." -- rfkill block bluetooth
    
    # --- TLP ---
    gum spin --spinner globe --title "Activating TLP power saver..." -- sudo tlp power-saver
    
    # --- PROCESS TERMINATOR ---
    TERMINATOR_SCRIPT="$HOME/user_scripts/battery/process_terminator.sh"
    
    if [ -f "$TERMINATOR_SCRIPT" ]; then
        # Using spinner for the terminator script
        gum spin --spinner minidot --title "Running Process Terminator..." -- \
            uwsm-app -- sudo "$TERMINATOR_SCRIPT"
        log_step "High-drain processes terminated."
    else
        log_warn "Error: '$TERMINATOR_SCRIPT' not found."
    fi
else
    log_warn "Authentication failed. Root scripts (and Bluetooth block) were not executed."
fi

# --- 7. Deferred Theme Execution ---
if [ "$SWITCH_THEME_LATER" = true ]; then
    echo ""
    gum style --foreground 212 "Executing detached theme switch..."
    gum style --foreground 240 "If this terminal closes immediately, it is expected behavior."
    
    sleep 1
    
    # Detached execution via Hyprland dispatcher + UWSM
    uwsm-app -- $HOME/user_scripts/swww/theme_switcher.sh --light && sleep 3 && pkill swww-daemon
fi

echo ""
gum style \
    --foreground 46 \
    --bold \
    "DONE: Power Saving Mode Active"
sleep 1
