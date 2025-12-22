#!/usr/bin/env bash
# shellcheck disable=SC2250  # Prefer ${var} style used intentionally

# -----------------------------------------------------------------------------
# POWER SAVER MODE - ASUS TUF F15 (Hyprland/UWSM)
# -----------------------------------------------------------------------------
# Strict mode: catch unset variables and pipe failures
# Note: -e intentionally NOT set to allow graceful degradation
set -uo pipefail

# Require Bash 4.4+ for ${var@Q} and other modern features
if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
    printf 'Error: Bash 4.4+ required (found %s)\n' "${BASH_VERSION}" >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
readonly BRIGHTNESS_LEVEL="1%"
readonly VOLUME_CAP="50"
readonly SUDO_REFRESH_INTERVAL=60  # Refresh sudo every N seconds to prevent timeout

# Script paths
readonly BLUR_SCRIPT="${HOME}/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh"
readonly THEME_SCRIPT="${HOME}/user_scripts/theme_matugen/matugen_config.sh"
readonly TERMINATOR_SCRIPT="${HOME}/user_scripts/battery/process_terminator.sh"
readonly ASUS_PROFILE_SCRIPT="${HOME}/user_scripts/battery/asus_tuf_profile/quiet_profile_and_keyboard_light.sh"
readonly ANIM_SOURCE="${HOME}/.config/hypr/source/animations/disable.conf"
readonly ANIM_TARGET="${HOME}/.config/hypr/source/animations/active/active.conf"

# State (mutable - not readonly)
SWITCH_THEME_LATER=false
TURN_OFF_WIFI=false
SUDO_AUTHENTICATED=false

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

# Check if command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Validate string is a positive integer
is_numeric() {
    [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]
}

# Logging functions using gum
log_step() {
    gum style --foreground 212 ":: $*"
}

log_warn() {
    gum style --foreground 208 "⚠ $*"
}

log_error() {
    gum style --foreground 196 "✗ $*" >&2
}

# Run command quietly, always succeed
run_quiet() {
    "$@" &>/dev/null || true
}

# Spinner wrapper for visual feedback
spin_exec() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- "$@"
}

# Refresh sudo timestamp to prevent timeout during long operations
sudo_keepalive() {
    if [[ "${SUDO_AUTHENTICATED}" == "true" ]]; then
        sudo -vn 2>/dev/null || true
    fi
}

# Safe pkill that never fails
safe_pkill() {
    local process_name="$1"
    pkill -x "$process_name" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# DEPENDENCY CHECK
# -----------------------------------------------------------------------------
check_dependencies() {
    if ! has_cmd gum; then
        printf 'Error: gum is not installed. Run: sudo pacman -S gum\n' >&2
        exit 1
    fi

    local -a missing=()
    local -a recommended=(
        uwsm-app
        brightnessctl
        hyprctl
        wpctl
        rfkill
        tlp
        hyprshade
        playerctl
    )

    local cmd
    for cmd in "${recommended[@]}"; do
        has_cmd "$cmd" || missing+=("$cmd")
    done

    if ((${#missing[@]} > 0)); then
        log_warn "Missing optional dependencies: ${missing[*]}"
        log_warn "Some features will be skipped."
        echo
    fi
}

# -----------------------------------------------------------------------------
# SCRIPT EXECUTION HELPERS
# -----------------------------------------------------------------------------

# Run an external script with proper checks
run_script() {
    local script_path="$1"
    local description="$2"
    shift 2
    local -a extra_args=("$@")

    if [[ -x "${script_path}" ]]; then
        if has_cmd uwsm-app; then
            spin_exec "${description}" uwsm-app -- "${script_path}" "${extra_args[@]}"
        else
            spin_exec "${description}" "${script_path}" "${extra_args[@]}"
        fi
        return 0
    elif [[ -f "${script_path}" ]]; then
        log_warn "Script not executable: ${script_path}"
        return 1
    else
        log_warn "Script not found: ${script_path}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# CLEANUP TRAP
# -----------------------------------------------------------------------------
cleanup() {
    # Restore cursor visibility if interrupted during gum spinner
    tput cnorm 2>/dev/null || true
    # Clear any partial gum output
    tput sgr0 2>/dev/null || true
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# INTERACTIVE PROMPTS
# -----------------------------------------------------------------------------
prompt_user_choices() {
    [[ -t 0 ]] || {
        log_step "Non-interactive shell detected. Skipping prompts."
        return
    }

    # Theme Prompt
    echo
    gum style --foreground 245 --italic \
        "Rationale: Light mode often allows for lower backlight brightness" \
        "while maintaining readability in well-lit environments."

    echo
    if gum confirm "Switch to Light Mode?" \
        --affirmative "Yes, switch it" \
        --negative "No, stay dark"; then
        log_step "Theme switch queued for end of script."
        SWITCH_THEME_LATER=true
    else
        log_step "Keeping current theme."
    fi

    # Wi-Fi Prompt
    echo
    if gum confirm "Turn off Wi-Fi to save power?" \
        --affirmative "Yes, disable Wi-Fi" \
        --negative "No, keep connected"; then
        log_step "Wi-Fi disable queued."
        TURN_OFF_WIFI=true
    else
        log_step "Keeping Wi-Fi active."
    fi
}

# -----------------------------------------------------------------------------
# POWER SAVING OPERATIONS
# -----------------------------------------------------------------------------

disable_visual_effects() {
    echo
    if ! has_cmd uwsm-app; then
        log_warn "uwsm-app not found. Skipping visual effects."
        return
    fi

    # Blur/Opacity/Shadow
    if [[ -x "${BLUR_SCRIPT}" ]]; then
        spin_exec "Disabling blur/opacity/shadow..." \
            uwsm-app -- "${BLUR_SCRIPT}" off
    elif [[ -f "${BLUR_SCRIPT}" ]]; then
        log_warn "Blur script not executable: ${BLUR_SCRIPT}"
    fi

    # Hyprshade
    if has_cmd hyprshade; then
        spin_exec "Disabling Hyprshade..." \
            uwsm-app -- hyprshade off
    fi

    log_step "Visual effects disabled."
}

cleanup_user_processes() {
    echo
    # Kill resource monitors (safe_pkill never fails)
    spin_exec "Cleaning up resource monitors..." \
        bash -c 'pkill -x btop 2>/dev/null; pkill -x nvtop 2>/dev/null; exit 0'

    # Pause media
    if has_cmd playerctl; then
        run_quiet playerctl -a pause
    fi
    log_step "Resource monitors killed & media paused."

    # Warp VPN
    if has_cmd warp-cli; then
        spin_exec "Disconnecting Warp..." \
            bash -c 'warp-cli disconnect &>/dev/null || true'
        log_step "Warp disconnected."
    fi
}

set_brightness() {
    if has_cmd brightnessctl; then
        spin_exec "Lowering brightness to ${BRIGHTNESS_LEVEL}..." \
            brightnessctl set "${BRIGHTNESS_LEVEL}" -q
        log_step "Brightness set to ${BRIGHTNESS_LEVEL}."
    else
        log_warn "brightnessctl not found. Skipping brightness."
    fi
}

disable_animations() {
    if ! has_cmd hyprctl; then
        log_warn "hyprctl not found. Skipping animation toggle."
        return
    fi

    if [[ ! -f "${ANIM_SOURCE}" ]]; then
        log_warn "Animation source not found: ${ANIM_SOURCE}"
        return
    fi

    # Create target directory if needed
    local target_dir
    target_dir="$(dirname "${ANIM_TARGET}")"
    if ! mkdir -p "${target_dir}" 2>/dev/null; then
        log_warn "Failed to create directory: ${target_dir}"
        return
    fi

    # Use positional parameters to safely pass paths to sh -c
    spin_exec "Disabling animations & reloading Hyprland..." \
        bash -c 'ln -nfs "$1" "$2" && hyprctl reload' _ "${ANIM_SOURCE}" "${ANIM_TARGET}"
    
    log_step "Hyprland animations disabled."
}

apply_asus_profile() {
    run_script "${ASUS_PROFILE_SCRIPT}" "Applying Quiet Profile & KB Lights..." && \
        log_step "ASUS Quiet profile & lighting applied."
}

# -----------------------------------------------------------------------------
# ROOT LEVEL OPERATIONS
# -----------------------------------------------------------------------------

request_sudo() {
    echo
    gum style \
        --border normal \
        --border-foreground 196 \
        --padding "0 1" \
        --foreground 196 \
        "PRIVILEGE ESCALATION REQUIRED" \
        "Need root for TLP, Wi-Fi, and Process Terminator."

    echo
    # Validate sudo credentials interactively (CANNOT wrap - hides password prompt)
    if sudo -v; then
        SUDO_AUTHENTICATED=true
        return 0
    else
        log_error "Authentication failed. Root operations skipped."
        return 1
    fi
}

block_bluetooth() {
    has_cmd rfkill || {
        log_warn "rfkill not found. Skipping Bluetooth block."
        return
    }

    sudo_keepalive
    spin_exec "Blocking Bluetooth..." sudo rfkill block bluetooth
    sleep 0.5  # Allow device disconnection
    log_step "Bluetooth blocked."
}

block_wifi() {
    [[ "${TURN_OFF_WIFI}" == "true" ]] || return 0

    has_cmd rfkill || {
        log_warn "rfkill not found. Skipping Wi-Fi block."
        return
    }

    sudo_keepalive
    spin_exec "Blocking Wi-Fi (Hardware)..." sudo rfkill block wifi
    sleep 0.5
    log_step "Wi-Fi blocked."
}

cap_volume() {
    has_cmd wpctl || {
        log_warn "wpctl not found. Skipping volume cap."
        return
    }

    local raw_output
    local current_vol

    # Get volume - handle potential failures gracefully
    if ! raw_output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); then
        log_warn "Could not query audio sink."
        return
    fi

    # Parse volume: "Volume: 0.60" -> 60
    current_vol=$(awk '{printf "%.0f", $2 * 100}' <<< "${raw_output}") || current_vol=""

    if ! is_numeric "${current_vol}"; then
        log_warn "Could not parse volume level from: ${raw_output}"
        return
    fi

    if ((current_vol > VOLUME_CAP)); then
        spin_exec "Volume ${current_vol}% → ${VOLUME_CAP}%..." \
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "${VOLUME_CAP}%"
        log_step "Volume capped at ${VOLUME_CAP}%."
    else
        log_step "Volume at ${current_vol}%. No change needed."
    fi
}

activate_tlp() {
    has_cmd tlp || {
        log_warn "tlp not found. Skipping power profile."
        return
    }

    sudo_keepalive
    # REVERTED: Changed 'bat' back to 'power-saver' as requested
    spin_exec "Activating TLP power saver..." sudo tlp power-saver
    log_step "TLP power saver activated."
}

run_process_terminator() {
    [[ -x "${TERMINATOR_SCRIPT}" ]] || {
        if [[ -f "${TERMINATOR_SCRIPT}" ]]; then
            log_warn "Terminator script not executable: ${TERMINATOR_SCRIPT}"
        else
            log_warn "Terminator script not found: ${TERMINATOR_SCRIPT}"
        fi
        return
    }

    sudo_keepalive
    spin_exec "Running Process Terminator..." sudo "${TERMINATOR_SCRIPT}"
    log_step "High-drain processes terminated."
}

perform_root_operations() {
    request_sudo || return

    echo
    block_bluetooth
    block_wifi
    cap_volume
    activate_tlp
    run_process_terminator
}

# -----------------------------------------------------------------------------
# THEME SWITCH (DEFERRED)
# -----------------------------------------------------------------------------

switch_theme_if_queued() {
    if [[ "${SWITCH_THEME_LATER}" != "true" ]]; then
        # Kill swww immediately if not switching theme
        run_quiet pkill swww-daemon
        log_step "swww-daemon terminated."
        return
    fi

    echo

    if ! has_cmd uwsm-app; then
        log_error "uwsm-app required for theme switch but not found."
        return 1
    fi

    if [[ ! -x "${THEME_SCRIPT}" ]]; then
        if [[ -f "${THEME_SCRIPT}" ]]; then
            log_warn "Theme script not executable: ${THEME_SCRIPT}"
        else
            log_warn "Theme script not found: ${THEME_SCRIPT}"
        fi
        return 1
    fi

    gum style --foreground 212 "Executing theme switch..."
    gum style --foreground 240 "(Terminal may close - this is expected)"
    sleep 1

    # Execute theme switch and handle swww-daemon cleanup
    if uwsm-app -- "${THEME_SCRIPT}" --mode light; then
        sleep 3
        run_quiet pkill swww-daemon
        log_step "Theme switched to light mode."
    else
        log_error "Theme switch failed."
        return 1
    fi
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
main() {
    check_dependencies

    # Banner
    clear
    gum style \
        --border double \
        --margin "1" \
        --padding "1 2" \
        --border-foreground 212 \
        --foreground 212 \
        "ASUS TUF F15: POWER SAVER MODE"

    # Interactive prompts (sets SWITCH_THEME_LATER and TURN_OFF_WIFI)
    prompt_user_choices

    # User-level operations (no sudo required)
    disable_visual_effects
    cleanup_user_processes
    set_brightness
    disable_animations
    apply_asus_profile

    # Root-level operations (requires sudo)
    perform_root_operations

    # Deferred theme switch (must be last - may close terminal)
    switch_theme_if_queued

    # Complete
    echo
    gum style \
        --foreground 46 \
        --bold \
        "✓ DONE: Power Saving Mode Active"

    sleep 1
}

main "$@"
