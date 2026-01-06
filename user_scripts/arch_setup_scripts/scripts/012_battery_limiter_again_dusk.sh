#!/usr/bin/env bash
# this is a personal script to reenable battery limiter after installing asusctl from the aur
# -----------------------------------------------------------------------------
# Battery Charge Limiter
# Context: Arch Linux / Hyprland / UWSM
# Description: Sets battery charge thresholds safely.
# -----------------------------------------------------------------------------

set -euo pipefail

# Configuration
readonly LIMIT=60
readonly SEARCH_PATH="/sys/class/power_supply"
# Note: Some older kernels or ThinkPads might use 'charge_stop_threshold'
readonly THRESHOLD_FILE="charge_control_end_threshold"

# Helper function for logging
log() {
    local type="$1"
    local message="$2"
    case "$type" in
        INFO)  printf "\e[34m[INFO]\e[0m  %s\n" "$message" ;;
        OK)    printf "\e[32m[OK]\e[0m    %s\n" "$message" ;;
        WARN)  printf "\e[33m[WARN]\e[0m  %s\n" "$message" ;;
        ERR)   printf "\e[31m[ERROR]\e[0m %s\n" "$message" >&2 ;;
    esac
}

main() {
    # 1. Enforce Root
    if [[ $EUID -ne 0 ]]; then
       log ERR "This script must be run as root. Please use sudo."
       exit 1
    fi

    # 2. Detect Batteries
    # Enable nullglob so the pattern expands to nothing if no matches are found
    shopt -s nullglob
    local batteries=("$SEARCH_PATH"/BAT*)
    shopt -u nullglob

    # 3. Handle No Batteries
    if (( ${#batteries[@]} == 0 )); then
        log INFO "No batteries detected in $SEARCH_PATH."
        log OK "System configuration check complete. No changes made."
        exit 0
    fi

    # 4. Iterate and Apply
    local changes_made=0
    
    for bat in "${batteries[@]}"; do
        local bat_name
        bat_name=$(basename "$bat")
        local target="$bat/$THRESHOLD_FILE"

        if [[ -f "$target" ]]; then
            # Attempt to write
            if echo "$LIMIT" > "$target"; then
                # Verify the write (Read-after-write check)
                local current_val
                current_val=$(cat "$target")
                
                if [[ "$current_val" -eq "$LIMIT" ]]; then
                    log OK "Battery ($bat_name): Limit successfully set to ${LIMIT}%."
                    # FIX: Use +=1 to avoid (( 0 )) evaluating to exit code 1 under set -e
                    ((changes_made+=1))
                else
                    log WARN "Battery ($bat_name): Wrote limit but kernel reports ${current_val}%."
                fi
            else
                log ERR "Battery ($bat_name): Failed to write to $target."
            fi
        else
            log WARN "Battery ($bat_name): Threshold file '$THRESHOLD_FILE' not found. Skipping."
        fi
    done

    # 5. Final Status
    if (( changes_made > 0 )); then
        log OK "Battery limit application complete."
    else
        log INFO "Script finished. No thresholds were updated (hardware might not support it)."
    fi
}

main
