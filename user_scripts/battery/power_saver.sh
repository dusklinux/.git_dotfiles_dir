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
readonly THEME_SCRIPT="${HOME}/user_scripts/swww/theme_switcher.sh"
readonly TERMINATOR_SCRIPT="${HOME}/user_scripts/battery/process_terminator.sh"
readonly ANIM_SOURCE="${HOME}/.config/hypr/source/animations/disable.conf"
readonly ANIM_TARGET="${HOME}/.config/hypr/source/animations/active/active.conf"

# State
SWITCH_THEME_LATER=false

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
    local -a recommended=(uwsm-app brightnessctl hyprctl pamixer rfkill tlp)

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

    # --- 1. Interactive Light Mode Prompt ---
    if [[ -t 0 ]]; then
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
    else
        log_step "Non-interactive shell detected. Skipping Light Mode prompt."
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

    # --- 6. Root Level Operations ---
    echo ""
    gum style \
        --border normal \
        --border-foreground 196 \
        --padding "0 1" \
        --foreground 196 \
        "PRIVILEGE ESCALATION REQUIRED" \
        "Need root for TLP and Process Terminator."

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

        # --- Volume Cap ---
        if has_cmd pamixer; then
            local current_vol
            current_vol=$(pamixer --get-volume 2>/dev/null) || current_vol=""

            if is_numeric "$current_vol"; then
                if ((current_vol > VOLUME_CAP)); then
                    spin_exec "Volume ${current_vol}% → ${VOLUME_CAP}%..." \
                        pamixer --set-volume "$VOLUME_CAP"
                    log_step "Volume capped at ${VOLUME_CAP}%."
                else
                    log_step "Volume at ${current_vol}%. No change needed."
                fi
            else
                log_warn "Could not read volume level."
            fi
        else
            log_warn "pamixer not found. Skipping volume cap."
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

    # --- 7. Deferred Theme Switch ---
    if [[ "$SWITCH_THEME_LATER" == true ]]; then
        echo ""

        if [[ -x "$THEME_SCRIPT" ]]; then
            gum style --foreground 212 "Executing theme switch..."
            gum style --foreground 240 "(Terminal may close - this is expected)"
            sleep 1

            # Execute and handle swww cleanup
            if uwsm-app -- "$THEME_SCRIPT" --light; then
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
