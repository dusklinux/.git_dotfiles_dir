#!/usr/bin/env bash
#
# Battery Notification Script - Hardened & Optimized
# For use as a systemd user service
#

# Strict mode (no -e, we handle errors explicitly in daemon loop)
set -uo pipefail

##########################
# CONFIGURATION
##########################
readonly BATTERY_DEVICE="${BATTERY_DEVICE:-}"
readonly CHECK_INTERVAL="${CHECK_INTERVAL:-30}"

# Thresholds (ensure CRITICAL < LOW < FULL)
readonly BATTERY_FULL_THRESHOLD="${BATTERY_FULL_THRESHOLD:-75}"
readonly BATTERY_LOW_THRESHOLD="${BATTERY_LOW_THRESHOLD:-50}"
readonly BATTERY_CRITICAL_THRESHOLD="${BATTERY_CRITICAL_THRESHOLD:-30}"
readonly BATTERY_UNPLUG_THRESHOLD="${BATTERY_UNPLUG_THRESHOLD:-100}"

# Repeat notification timers (minutes)
readonly REPEAT_FULL_MIN="${REPEAT_FULL_MIN:-999}"
readonly REPEAT_LOW_MIN="${REPEAT_LOW_MIN:-3}"
readonly REPEAT_CRITICAL_MIN="${REPEAT_CRITICAL_MIN:-1}"

# Commands & Sounds
readonly CMD_CRITICAL="${CMD_CRITICAL:-systemctl suspend}"
readonly SOUND_LOW="${SOUND_LOW:-/usr/share/sounds/freedesktop/stereo/complete.oga}"
readonly SOUND_CRITICAL="${SOUND_CRITICAL:-/usr/share/sounds/freedesktop/stereo/suspend-error.oga}"

readonly MAX_RETRIES=5

##########################
# RUNTIME STATE
##########################
declare -g RUNNING=true
declare -g CURRENT_DEVICE=""

##########################
# SIGNAL HANDLING
##########################
cleanup() {
    log "Received signal, shutting down gracefully..."
    RUNNING=false
}
trap cleanup SIGTERM SIGINT SIGHUP

##########################
# HELPER FUNCTIONS
##########################

log() {
    printf '[%s] [battery_notify] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
    log "FATAL: $*"
    exit 1
}

is_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

get_icon() {
    local perc="${1:-0}"
    local state="${2:-Discharging}"
    
    # Validate and clamp
    is_integer "$perc" || perc=0
    (( perc > 100 )) && perc=100
    (( perc < 0 )) && perc=0
    
    # Round to nearest 10 for ALL states
    local rounded=$(( (perc + 5) / 10 * 10 ))
    (( rounded > 100 )) && rounded=100
    
    if [[ "$state" == "Charging" ]]; then
        printf '%s' "battery-level-${rounded}-charging-symbolic"
    else
        printf '%s' "battery-level-${rounded}-symbolic"
    fi
}

fn_notify() {
    local urgency="$1"
    local title="$2"
    local body="$3"
    local icon="$4"
    local sound="${5:-}"

    # Ensure DBus session is available
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
    fi

    # Send notification
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -t 5000 -a "Battery Monitor" -i "$icon" \
            "$title" "$body" || log "Warning: notify-send failed"
    else
        log "notify-send unavailable: $title - $body"
    fi

    # Play sound in background (properly detached)
    if [[ -n "$sound" && -f "$sound" ]] && command -v paplay &>/dev/null; then
        paplay "$sound" &>/dev/null &
        disown 2>/dev/null
    fi
}

detect_battery() {
    local dev=""
    
    # Use configured device if set
    if [[ -n "$BATTERY_DEVICE" ]]; then
        if upower -i "$BATTERY_DEVICE" &>/dev/null; then
            printf '%s' "$BATTERY_DEVICE"
            return 0
        fi
        log "Warning: Configured device '$BATTERY_DEVICE' not found"
        return 1
    fi
    
    # Auto-detect
    dev=$(upower -e 2>/dev/null | grep -iE 'BAT|battery' | head -n1)
    
    if [[ -z "$dev" ]]; then
        return 1
    fi
    
    printf '%s' "$dev"
    return 0
}

read_battery() {
    local dev="$1"
    local info state perc
    
    info=$(upower -i "$dev" 2>/dev/null) || return 1
    [[ -z "$info" ]] && return 1
    
    # Extract state (trim all whitespace)
    state=$(awk -F: '/^[[:space:]]*state:/ {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }' <<< "$info")
    
    # Extract percentage (digits only)
    perc=$(awk -F: '/^[[:space:]]*percentage:/ {
        gsub(/[^0-9]/, "", $2)
        print $2
        exit
    }' <<< "$info")
    
    # Validate percentage
    if ! is_integer "$perc"; then
        log "Warning: Invalid percentage '$perc'"
        return 1
    fi
    
    # Normalize state
    case "${state,,}" in
        discharging|not?charging)      state="Discharging" ;;
        charging|pending?charge)       state="Charging" ;;
        fully?charged|full)            state="Full" ;;
        *)                             state="Unknown" ;;
    esac
    
    printf '%s;%s' "$state" "$perc"
    return 0
}

##########################
# STARTUP VALIDATION
##########################
startup_checks() {
    local errors=0
    
    # Required commands
    for cmd in upower date sleep; do
        if ! command -v "$cmd" &>/dev/null; then
            log "Missing required command: $cmd"
            (( errors++ ))
        fi
    done
    
    # Optional commands (warnings only)
    for cmd in notify-send paplay; do
        command -v "$cmd" &>/dev/null || log "Warning: Optional command missing: $cmd"
    done
    
    # Sound file checks
    [[ -n "$SOUND_LOW" && ! -f "$SOUND_LOW" ]] && \
        log "Warning: Sound file not found: $SOUND_LOW"
    [[ -n "$SOUND_CRITICAL" && ! -f "$SOUND_CRITICAL" ]] && \
        log "Warning: Sound file not found: $SOUND_CRITICAL"
    
    # Threshold sanity check
    if (( BATTERY_CRITICAL_THRESHOLD >= BATTERY_LOW_THRESHOLD )); then
        log "Warning: CRITICAL ($BATTERY_CRITICAL_THRESHOLD) >= LOW ($BATTERY_LOW_THRESHOLD)"
    fi
    if (( BATTERY_LOW_THRESHOLD >= BATTERY_FULL_THRESHOLD )); then
        log "Warning: LOW ($BATTERY_LOW_THRESHOLD) >= FULL ($BATTERY_FULL_THRESHOLD)"
    fi
    
    return "$errors"
}

##########################
# MAIN LOOP
##########################
main_loop() {
    local last_state=""
    local last_percentage=999
    local last_full_notified_at=0
    local last_low_notified_at=0
    local last_critical_notified_at=0
    local suspended_once=false
    local consecutive_failures=0
    
    # Pre-declare loop variables (avoid repeated local declarations)
    local reading="" state="" 
    local percentage=0 now=0
    
    # Initial detection with retries
    local retry=0
    while ! CURRENT_DEVICE=$(detect_battery); do
        (( retry++ ))
        if (( retry >= MAX_RETRIES )); then
            die "No battery found after $MAX_RETRIES attempts"
        fi
        log "Detection failed (attempt $retry/$MAX_RETRIES), retrying..."
        sleep 2
    done
    
    log "Monitoring: $CURRENT_DEVICE"
    log "Thresholds: Full=${BATTERY_FULL_THRESHOLD}% Low=${BATTERY_LOW_THRESHOLD}% Critical=${BATTERY_CRITICAL_THRESHOLD}%"

    while $RUNNING; do
        # Read battery status
        if ! reading=$(read_battery "$CURRENT_DEVICE"); then
            (( consecutive_failures++ ))
            log "Read failed (#$consecutive_failures)"
            
            if (( consecutive_failures >= MAX_RETRIES )); then
                log "Too many failures, attempting re-detection..."
                if CURRENT_DEVICE=$(detect_battery); then
                    log "Re-detected: $CURRENT_DEVICE"
                    consecutive_failures=0
                fi
            fi
            
            sleep "$CHECK_INTERVAL"
            continue
        fi
        consecutive_failures=0
        
        # Parse reading
        state="${reading%%;*}"
        percentage="${reading##*;}"
        now=$(date +%s)
        
        # Reset suspend lock when charging
        if [[ "$state" == "Charging" || "$state" == "Full" ]]; then
            suspended_once=false
        fi
        
        # --- STATE TRANSITION ---
        if [[ "$state" != "$last_state" ]]; then
            log "State: '${last_state:-<init>}' -> '$state' ($percentage%)"
            
            case "$state" in
                Charging)
                    fn_notify "normal" "⚡ Charging" \
                        "Battery is charging ($percentage%)" \
                        "$(get_icon "$percentage" "$state")" ""
                    ;;
                Discharging)
                    if (( percentage <= BATTERY_UNPLUG_THRESHOLD )); then
                        fn_notify "normal" "🔋 Unplugged" \
                            "Running on battery ($percentage%)" \
                            "$(get_icon "$percentage" "$state")" ""
                    fi
                    ;;
                Full)
                    fn_notify "normal" "✓ Fully Charged" \
                        "Battery at 100%" \
                        "battery-full-charged-symbolic" ""
                    last_full_notified_at=$now
                    ;;
            esac
            last_state="$state"
        fi
        
        # --- FULL NOTIFICATION (while charging at/above threshold) ---
        if [[ "$state" == "Charging" ]] && (( percentage >= BATTERY_FULL_THRESHOLD )); then
            if (( now - last_full_notified_at >= REPEAT_FULL_MIN * 60 )); then
                fn_notify "normal" "🔋 Battery Full" \
                    "Level: $percentage% - Consider unplugging" \
                    "battery-full-charged-symbolic" ""
                last_full_notified_at=$now
            fi
        fi
        
        # --- LOW NOTIFICATION ---
        if [[ "$state" == "Discharging" ]] && (( percentage <= BATTERY_LOW_THRESHOLD )); then
            if (( last_percentage > BATTERY_LOW_THRESHOLD )) || \
               (( now - last_low_notified_at >= REPEAT_LOW_MIN * 60 )); then
                fn_notify "normal" "⚠️ Battery Low" \
                    "$percentage% remaining" \
                    "$(get_icon "$percentage" "$state")" "$SOUND_LOW"
                last_low_notified_at=$now
            fi
        fi
        
        # --- CRITICAL NOTIFICATION & ACTION ---
        if [[ "$state" == "Discharging" ]] && (( percentage <= BATTERY_CRITICAL_THRESHOLD )); then
            if (( last_percentage > BATTERY_CRITICAL_THRESHOLD )) || \
               (( now - last_critical_notified_at >= REPEAT_CRITICAL_MIN * 60 )); then
                
                fn_notify "critical" "🚨 CRITICAL BATTERY" \
                    "$percentage% - Suspending system!" \
                    "battery-level-0-symbolic" "$SOUND_CRITICAL"
                last_critical_notified_at=$now
                
                # Execute critical command (once per discharge cycle)
                if [[ -n "$CMD_CRITICAL" && "$suspended_once" == false ]]; then
                    log "Executing: $CMD_CRITICAL"
                    sleep 2  # Let user see notification
                    
                    # Use eval to properly handle complex commands
                    if eval "$CMD_CRITICAL"; then
                        log "Critical command succeeded"
                    else
                        log "Critical command failed (exit: $?)"
                    fi
                    suspended_once=true
                fi
            fi
        fi
        
        last_percentage=$percentage
        sleep "$CHECK_INTERVAL"
    done
    
    log "Loop terminated gracefully"
}

##########################
# ENTRY POINT
##########################
main() {
    log "=== Battery Monitor Starting (PID: $$) ==="
    
    if ! startup_checks; then
        die "Startup checks failed"
    fi
    
    main_loop
    
    log "=== Battery Monitor Stopped ==="
    exit 0
}

main "$@"
