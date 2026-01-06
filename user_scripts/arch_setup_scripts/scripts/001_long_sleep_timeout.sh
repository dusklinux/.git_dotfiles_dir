#!/bin/bash
# To set longer screen timeout during the setup process to prevent the device from going into sleep.
#===============================================================================
# HYPRIDLE CONFIGURATION APPLICATOR
# specific for Arch/Hyprland/UWSM ecosystem
#===============================================================================

# Strict mode - catch errors early
set -o errexit
set -o nounset
set -o pipefail

#===============================================================================
# USER CONFIGURATION
# Modify these values to set your desired timeouts (in seconds)
#===============================================================================

readonly TIMEOUT_DIM=120        # Dim Screen
readonly TIMEOUT_LOCK=2480       # Lock Session
readonly TIMEOUT_OFF=4600       # Screen Off (DPMS)
readonly TIMEOUT_SUSPEND=43200  # System Suspend

#===============================================================================
# SYSTEM CONSTANTS
#===============================================================================
readonly CONFIG_FILE="${HOME}/.config/hypr/hypridle.conf"
readonly BACKUP_FILE="/tmp/hypridle.bak"
readonly SCRIPT_NAME="${0##*/}"

# Listener block signatures (used for matching)
readonly SIG_DIM="brightnessctl -s set"
readonly SIG_LOCK="loginctl lock-session"
readonly SIG_OFF="dispatch dpms off"
readonly SIG_SUSPEND="systemctl suspend"

# ANSI Colors (using ANSI-C quoting)
readonly C_RED=$'\033[1;31m'
readonly C_GREEN=$'\033[1;32m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_BLUE=$'\033[1;34m'
readonly C_BOLD=$'\033[1m'
readonly C_RESET=$'\033[0m'

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================
TEMP_FILE=""

cleanup() {
    if [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

# Trap multiple signals for robust cleanup
trap cleanup EXIT INT TERM HUP

die() {
    printf "${C_RED}✗ Error: %s${C_RESET}\n" "$1" >&2
    exit 1
}

warn() {
    printf "${C_YELLOW}⚠ %s${C_RESET}\n" "$1"
}

success() {
    printf "${C_GREEN}✓ %s${C_RESET}\n" "$1"
}

info() {
    printf "${C_BLUE}%s${C_RESET}\n" "$1"
}

#===============================================================================
# CORE LOGIC
#===============================================================================

# Update all timeout values in a single atomic pass
update_all_timeouts() {
    local dim_val="$1"
    local lock_val="$2"
    local off_val="$3"
    local susp_val="$4"
    
    awk -v dim_sig="$SIG_DIM" -v dim_val="$dim_val" \
        -v lock_sig="$SIG_LOCK" -v lock_val="$lock_val" \
        -v off_sig="$SIG_OFF" -v off_val="$off_val" \
        -v susp_sig="$SIG_SUSPEND" -v susp_val="$susp_val" '
    BEGIN { in_block = 0; buffer = "" }
    
    /^[[:space:]]*listener[[:space:]]*\{?[[:space:]]*$/ {
        in_block = 1
        buffer = $0
        next
    }
    
    in_block {
        buffer = buffer "\n" $0
        if (/^[[:space:]]*\}[[:space:]]*$/) {
            in_block = 0
            new_val = ""
            
            if (index(buffer, dim_sig) > 0) new_val = dim_val
            else if (index(buffer, lock_sig) > 0) new_val = lock_val
            else if (index(buffer, off_sig) > 0) new_val = off_val
            else if (index(buffer, susp_sig) > 0) new_val = susp_val
            
            if (new_val != "") {
                gsub(/timeout[[:space:]]*=[[:space:]]*[0-9]+/, "timeout = " new_val, buffer)
            }
            print buffer
            buffer = ""
        }
        next
    }
    
    { print }
    
    END {
        if (buffer != "") print buffer
    }
    ' "$CONFIG_FILE" > "$TEMP_FILE"
    
    # Safety Checks
    if [[ ! -s "$TEMP_FILE" ]]; then
        die "Generated config is empty - aborting to prevent data loss"
    fi
    
    local orig_size new_size
    orig_size=$(wc -c < "$CONFIG_FILE")
    new_size=$(wc -c < "$TEMP_FILE")
    
    if (( new_size < orig_size / 2 )); then
        die "Generated config is suspiciously small (${new_size} vs ${orig_size} bytes) - aborting"
    fi
    
    # Backup
    if ! cp -f "$CONFIG_FILE" "$BACKUP_FILE"; then
        warn "Could not create backup at $BACKUP_FILE"
    fi
    
    # Atomic Move
    if ! mv -f "$TEMP_FILE" "$CONFIG_FILE"; then
        if [[ -f "$BACKUP_FILE" ]]; then
            cp -f "$BACKUP_FILE" "$CONFIG_FILE" 2>/dev/null || true
        fi
        die "Failed to update config file"
    fi
    
    # Recreate temp file variable handle for cleanup
    TEMP_FILE=$(mktemp) || true
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    # 1. Validation (Fail fast before showing UI)
    [[ -f "$CONFIG_FILE" ]] || die "Config file not found: $CONFIG_FILE"
    [[ -w "$CONFIG_FILE" ]] || die "Config file not writable: $CONFIG_FILE"
    
    # Create temp file early to ensure write access
    TEMP_FILE=$(mktemp) || die "Failed to create temporary file"

    # 2. Logic Sanity Check (Pre-flight)
    if (( TIMEOUT_DIM >= TIMEOUT_LOCK )) || \
       (( TIMEOUT_LOCK >= TIMEOUT_OFF )) || \
       (( TIMEOUT_OFF >= TIMEOUT_SUSPEND )); then
        warn "Timeline logic check failed!" 
        warn "Expected: Dim < Lock < Off < Suspend"
        # We allow continuation, but warn prominently
    fi

    # 3. User Interface
    clear
    printf "${C_YELLOW}${C_BOLD}>>> SETUP POWER CONFIGURATION NOTICE <<<${C_RESET}\n"
    echo "------------------------------------------------------------------------"
    printf "To ensure the installation/setup process completes without interruption:\n\n"
    
    printf "  1. ${C_GREEN}Screen Protection:${C_RESET} The screen WILL dim and turn off to save battery.\n"
    printf "     (This prevents battery drain if running on an unplugged laptop).\n"
    printf "     If you are on a desktop PC, this is fine and harmless.\n\n"
    
    printf "  2. ${C_RED}No System Sleep:${C_RESET} The system WILL NOT suspend (sleep).\n"
    printf "     This ensures long-running compilations are not killed by idle timers.\n\n"
    
    printf "${C_BLUE}NOTE:${C_RESET} These are temporary settings for the setup phase.\n"
    printf "This will later automatically revert to the defaults or you can customize\n"
    printf "these timeouts later by running: ${C_BOLD}~/user_scripts/hypridle/timeout.sh${C_RESET}\n"
    echo "------------------------------------------------------------------------"
    printf "${C_BOLD}PROPOSED CONFIGURATION:${C_RESET}\n"
    printf "Target Config: ${C_BLUE}%s${C_RESET}\n" "$CONFIG_FILE"
    echo
    printf "%-15s : ${C_GREEN}%s${C_RESET} s\n" "Dim Screen" "$TIMEOUT_DIM"
    printf "%-15s : ${C_GREEN}%s${C_RESET} s\n" "Lock Session" "$TIMEOUT_LOCK"
    printf "%-15s : ${C_GREEN}%s${C_RESET} s\n" "Screen Off" "$TIMEOUT_OFF"
    printf "%-15s : ${C_GREEN}%s${C_RESET} s\n" "System Suspend" "$TIMEOUT_SUSPEND"
    echo "------------------------------------------------------------------------"
    printf "${C_BOLD}Press [Enter] to apply these settings and proceed...${C_RESET}"
    read -r
    echo

    # 4. Apply Changes
    info "Writing configuration..."
    update_all_timeouts "$TIMEOUT_DIM" "$TIMEOUT_LOCK" "$TIMEOUT_OFF" "$TIMEOUT_SUSPEND"
    success "Configuration saved successfully."

    # 5. Service Handling (Automated)
    # Check if the unit file exists on disk (even if not loaded) to determine if installed
    if systemctl --user list-unit-files hypridle.service &>/dev/null; then
        if systemctl --user is-active --quiet hypridle; then
            info "Restarting hypridle service..."
            systemctl --user restart hypridle && success "Hypridle restarted." || warn "Failed to restart hypridle."
        else
            info "Starting hypridle service..."
            systemctl --user start hypridle && success "Hypridle started." || warn "Failed to start hypridle."
        fi
    else
        # Service not found - likely not installed yet. This is expected behavior in setup phase.
        warn "Hypridle service not found (likely not installed yet)."
        info "Config file updated. Service will use new settings when installed/started later."
    fi
}

main "$@"
