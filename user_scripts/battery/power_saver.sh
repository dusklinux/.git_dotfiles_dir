#!/bin/bash

# -----------------------------------------------------------------------------
# POWER SAVER MODE - ASUS TUF F15 (Hyprland/UWSM)
# -----------------------------------------------------------------------------
# Strict mode: catch unset variables and pipe failures
# Note: -e intentionally NOT set to allow graceful degradation
set -uo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
readonly BRIGHTNESS_LEVEL="1%"
readonly VOLUME_CAP=50

# Script paths
readonly BLUR_SCRIPT="${HOME}/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh"
readonly THEME_SCRIPT="${HOME}/user_scripts/theme_matugen/matugen_config.sh"
readonly TERMINATOR_SCRIPT="${HOME}/user_scripts/battery/process_terminator.sh"
readonly ASUS_PROFILE_SCRIPT="${HOME}/user_scripts/battery/asus_tuf_profile/quiet_profile_and_keyboard_light.sh"
readonly ANIM_SOURCE="${HOME}/.config/hypr/source/animations/disable.conf"
readonly ANIM_TARGET="${HOME}/.config/hypr/source/animations/active/active.conf"

# State
SWITCH_THEME_LATER=false
TURN_OFF_WIFI=false

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------
has_cmd() {
    command -v "$1" &>/dev/null
}

is_numeric() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

log_step() {
    gum style --foreground 212 ":: $*"
}

log_warn() {
    gum style --foreground 208 "⚠ $*"
}

log_error() {
    gum style --foreground 196 "✗ $*" >&2
}

# Run command quietly, never fail
run_quiet() {
    "$@" &>/dev/null || true
}

# Spinner that actually wraps the work
spin_exec() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- "$@"
}

# -----------------------------------------------------------------------------
# DEPENDENCY CHECK
# -----------------------------------------------------------------------------
check_dependencies() {
    if ! has_cmd gum; then
        echo "Error: 'gum' is not installed. Please run 'sudo pacman -S gum'" >&2
        exit 1
    fi

    local -a missing=()
    # Replaced pamixer with wpctl in recommended list
    local -a recommended=(uwsm-app brightnessctl hyprctl wpctl rfkill tlp)

    for cmd in "${recommended[@]}"; do
        has_cmd "$cmd" || missing+=("$cmd")
    done

    if ((${#missing[@]} > 0)); then
        log_warn "Missing optional dependencies: ${missing[*]}"
        log_warn "Some features will be skipped."
        echo ""
    fi
}

# -----------------------------------------------------------------------------
# CLEANUP TRAP
# -----------------------------------------------------------------------------
cleanup() {
    # Restore cursor if interrupted during gum
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
main() {
    check_dependencies

    # --- Banner ---
    clear
    gum style \
        --border double \
        --margin "1" \
        --padding "1 2" \
        --border-foreground 212 \
        --foreground 212 \
        "ASUS TUF F15: POWER SAVER MODE"

    # --- 1. Interactive Prompts ---
    if [[ -t 0 ]]; then
        # Theme Prompt
        echo ""
        gum style --foreground 245 --italic \
            "Rationale: Light mode often allows for lower backlight brightness" \
            "while maintaining readability in well-lit environments."

        echo ""
        if gum confirm "Switch to Light Mode?" --affirmative "Yes, switch it" --negative "No, stay dark"; then
            log_step "Theme switch queued for end of script."
            SWITCH_THEME_LATER=true
        else
            log_step "Keeping current theme."
        fi

        # Wi-Fi Prompt
        echo ""
        if gum confirm "Turn off Wi-Fi to save power?" --affirmative "Yes, disable Wi-Fi" --negative "No, keep connected"; then
            log_step "Wi-Fi disable queued."
            TURN_OFF_WIFI=true
        else
            log_step "Keeping Wi-Fi active."
        fi
    else
        log_step "Non-interactive shell detected. Skipping prompts."
    fi

    # --- 2. Visual Effects ---
    echo ""
    if has_cmd uwsm-app; then
        if [[ -x "$BLUR_SCRIPT" ]]; then
            spin_exec "Disabling blur/opacity/shadow..." \
                uwsm-app -- "$BLUR_SCRIPT" off
        elif [[ -f "$BLUR_SCRIPT" ]]; then
            log_warn "Blur script not executable: $BLUR_SCRIPT"
        fi

        if has_cmd hyprshade; then
            spin_exec "Disabling Hyprshade..." \
                uwsm-app -- hyprshade off
        fi
        log_step "Visual effects disabled."
    else
        log_warn "uwsm-app not found. Skipping visual effects."
    fi

    # --- 3. User Level Cleanup ---
    echo ""
    spin_exec "Cleaning up resource monitors..." \
        sh -c 'pkill btop 2>/dev/null; pkill nvtop 2>/dev/null; exit 0'

    if has_cmd playerctl; then
        run_quiet playerctl -a pause
    fi
    log_step "Resource monitors killed & media paused."

    # Warp Cleanup
    if has_cmd warp-cli; then
        spin_exec "Disconnecting Warp..." \
             sh -c "warp-cli disconnect >/dev/null 2>&1 || true"
        log_step "Warp disconnected."
    fi

    # --- 4. Screen Brightness ---
    if has_cmd brightnessctl; then
        spin_exec "Lowering brightness to ${BRIGHTNESS_LEVEL}..." \
            brightnessctl set "$BRIGHTNESS_LEVEL" -q
        log_step "Brightness set to ${BRIGHTNESS_LEVEL}."
    else
        log_warn "brightnessctl not found. Skipping brightness."
    fi

    # --- 5. Hyprland Animations ---
    if has_cmd hyprctl; then
        if [[ -f "$ANIM_SOURCE" ]]; then
            mkdir -p "$(dirname "$ANIM_TARGET")"
            spin_exec "Disabling animations & reloading Hyprland..." \
                sh -c "ln -nfs '${ANIM_SOURCE}' '${ANIM_TARGET}' && hyprctl reload"
            log_step "Hyprland animations disabled."
        else
            log_warn "Animation source not found: $ANIM_SOURCE"
        fi
    else
        log_warn "hyprctl not found. Skipping animation toggle."
    fi

    # --- 6. ASUS Hardware Profile (User Level) ---
    # Placed before sudo to ensure hardware profile applies even if sudo is cancelled
    if [[ -x "$ASUS_PROFILE_SCRIPT" ]]; then
        # Use uwsm-app if available to ensure correct DBus/Scope context, else direct
        if has_cmd uwsm-app; then
            spin_exec "Applying Quiet Profile & KB Lights..." \
                uwsm-app -- "$ASUS_PROFILE_SCRIPT"
        else
            spin_exec "Applying Quiet Profile & KB Lights..." \
                "$ASUS_PROFILE_SCRIPT"
        fi
        log_step "ASUS Quiet profile & lighting applied."
    elif [[ -f "$ASUS_PROFILE_SCRIPT" ]]; then
        log_warn "ASUS script found but not executable: $ASUS_PROFILE_SCRIPT"
    else
        # Optional: warn only if you expect it to always be there
        log_warn "ASUS profile script not found: $ASUS_PROFILE_SCRIPT"
    fi

    # --- 7. Root Level Operations ---
    echo ""
    gum style \
        --border normal \
        --border-foreground 196 \
        --padding "0 1" \
        --foreground 196 \
        "PRIVILEGE ESCALATION REQUIRED" \
        "Need root for TLP, Wi-Fi, and Process Terminator."

    echo ""

    # Validate sudo credentials interactively (CANNOT wrap - hides password prompt)
    if sudo -v; then
        echo ""

        # --- Bluetooth Block (AFTER auth for BT keyboard safety) ---
        if has_cmd rfkill; then
            spin_exec "Blocking Bluetooth..." rfkill block bluetooth
            sleep 0.5  # Allow device disconnection
            log_step "Bluetooth blocked."
        else
            log_warn "rfkill not found. Skipping Bluetooth block."
        fi

        # --- Wi-Fi Block ---
        if [[ "$TURN_OFF_WIFI" == true ]]; then
            if has_cmd rfkill; then
                spin_exec "Blocking Wi-Fi (Hardware)..." rfkill block wifi
                sleep 0.5
                log_step "Wi-Fi blocked."
            else
                log_warn "rfkill not found. Skipping Wi-Fi block."
            fi
        fi

        # --- Volume Cap (Using wpctl/WirePlumber) ---
        if has_cmd wpctl; then
            local current_vol
            # Get volume from wpctl (returns float like 0.60), convert to integer (60)
            current_vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}') || current_vol=""

            if is_numeric "$current_vol"; then
                if ((current_vol > VOLUME_CAP)); then
                    spin_exec "Volume ${current_vol}% → ${VOLUME_CAP}%..." \
                        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${VOLUME_CAP}%"
                    log_step "Volume capped at ${VOLUME_CAP}%."
                else
                    log_step "Volume at ${current_vol}%. No change needed."
                fi
            else
                log_warn "Could not read volume level."
            fi
        else
            log_warn "wpctl not found. Skipping volume cap."
        fi

        # --- TLP Power Saver ---
        if has_cmd tlp; then
            spin_exec "Activating TLP power saver..." sudo tlp power-saver
            log_step "TLP power saver activated."
        else
            log_warn "tlp not found. Skipping power profile."
        fi

        # --- Process Terminator ---
        if [[ -x "$TERMINATOR_SCRIPT" ]]; then
            spin_exec "Running Process Terminator..." \
                sudo "$TERMINATOR_SCRIPT"
            log_step "High-drain processes terminated."
        elif [[ -f "$TERMINATOR_SCRIPT" ]]; then
            log_warn "Terminator script not executable: $TERMINATOR_SCRIPT"
        else
            log_warn "Terminator script not found: $TERMINATOR_SCRIPT"
        fi
    else
        log_error "Authentication failed. Root operations skipped."
    fi

    # --- 8. Deferred Theme Switch ---
    if [[ "$SWITCH_THEME_LATER" == true ]]; then
        echo ""

        if [[ -x "$THEME_SCRIPT" ]]; then
            gum style --foreground 212 "Executing theme switch..."
            gum style --foreground 240 "(Terminal may close - this is expected)"
            sleep 1

            # Execute and handle swww-daemon cleanup
            if uwsm-app -- "$THEME_SCRIPT" --mode light; then
                sleep 3
                run_quiet pkill swww-daemon
                log_step "Theme switched to light mode."
            else
                log_error "Theme switch failed."
            fi
        elif [[ -f "$THEME_SCRIPT" ]]; then
            log_warn "Theme script not executable: $THEME_SCRIPT"
        else
            log_warn "Theme script not found: $THEME_SCRIPT"
        fi
    else
        # Kill swww immediately if not switching theme
        run_quiet pkill swww-daemon
        log_step "swww-daemon terminated."
    fi

    # --- Complete ---
    echo ""
    gum style \
        --foreground 46 \
        --bold \
        "✓ DONE: Power Saving Mode Active"

    sleep 1
}

main "$@"
