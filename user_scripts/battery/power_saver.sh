#!/bin/bash

# -----------------------------------------------------------------------------
# POWER SAVER MODE - ASUS TUF F15
# -----------------------------------------------------------------------------

# --- 1. Interactive Light Mode Prompt ---
if [ -t 0 ]; then
    echo "-----------------------------------------------------------------"
    echo "Do you want to switch to Light Mode?"
    echo "Rationale: Light mode often allows for lower backlight brightness"
    echo "while maintaining readability in well-lit environments."
    echo "-----------------------------------------------------------------"
    read -p "Switch to Light Mode? (y/N): " choice
    
    case "$choice" in 
        y|Y ) 
            echo ":: Switching to Light Mode..."
            "$HOME/user_scripts/swww/theme_switcher.sh" --light
            
            # Wait for theme switch to settle before stressing the system
            sleep 2 
            ;;
        * ) 
            echo ":: Keeping current theme."
            ;;
    esac
else
    echo ":: Non-interactive shell detected. Skipping Light Mode prompt."
fi

# --- 2. Connectivity & Hardware ---
echo ":: Blocking Bluetooth..."
rfkill block bluetooth

# --- 3. Visual Effects ---
echo ":: Disabling fancy Hyprland effects..."
if [ -f "$HOME/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh" ]; then
    "$HOME/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh" off
fi

echo ":: Turning off Hyprshade..."
if command -v hyprshade &> /dev/null; then
    hyprshade off
fi

# --- 4. User Level Cleanup ---
echo ":: Stopping resource monitors..."
pkill btop || true
pkill nvtop || true

echo ":: Pausing all media..."
if command -v playerctl &> /dev/null; then
    playerctl -a pause
fi

# --- 5. Screen & Audio ---
echo ":: Lowering brightness to 1%..."
brightnessctl set 1%

echo ":: Checking volume levels..."
current_vol=$(pamixer --get-volume)
if [ "$current_vol" -gt 50 ]; then
    echo ":: Volume is $current_vol%. Lowering to 50%."
    pamixer --set-volume 50
else
    echo ":: Volume is $current_vol%. Leaving it unchanged."
fi

# --- 6. Hyprland Config ---
echo ":: Disabling Animations..."
ln -nfs "$HOME/.config/hypr/source/animations/disable.conf" "$HOME/.config/hypr/source/animations/active/active.conf"
echo ":: Reloading Hyprland configuration..."
hyprctl reload

# --- 7. Root Level Termination (The Critical Part) ---
echo "-----------------------------------------------------------------"
echo ":: PRIVILEGE ESCALATION REQUIRED"
echo ":: We need root to run TLP and the Process Terminator."
echo "-----------------------------------------------------------------"

# Clear the sudo timestamp to force a prompt if you want to be sure, 
# or just run sudo -v to refresh.
if sudo -v; then
    echo ":: Activating TLP power saver..."
    sudo tlp power-saver
    
    # Run your Process Terminator
    TERMINATOR_SCRIPT="$HOME/user_scripts/battery/process_terminator.sh"
    
    if [ -f "$TERMINATOR_SCRIPT" ]; then
        echo ":: Running Process Terminator..."
        sudo "$TERMINATOR_SCRIPT"
    else
        echo "!! Error: '$TERMINATOR_SCRIPT' not found."
    fi
else
    echo "!! Authentication failed. Root scripts were not executed."
fi

echo "-----------------------------------------------------------------"
echo "   Power Saving Mode Active   "
echo "-----------------------------------------------------------------"
