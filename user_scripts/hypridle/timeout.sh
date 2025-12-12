#!/bin/bash
#===============================================================================
# HYPRIDLE CONFIGURATION EDITOR
# A TUI tool to configure hypridle timeouts using gum
#===============================================================================

# Strict mode - catch errors early
set -o errexit
set -o nounset
set -o pipefail

#===============================================================================
# CONFIGURATION
#===============================================================================
readonly CONFIG_FILE="${HOME}/.config/hypr/hypridle.conf"
readonly BACKUP_FILE="/tmp/hypridlle.bak"
readonly SCRIPT_NAME="${0##*/}"

# PRESET DEFAULTS
readonly PRESET_DIM="150"      # 2.5 mins
readonly PRESET_LOCK="300"     # 5 mins
readonly PRESET_OFF="330"      # 5.5 mins
readonly PRESET_SUSPEND="600"  # 10 mins

# Listener block signatures (used for matching, not regex)
readonly SIG_DIM="brightnessctl -s set"
readonly SIG_LOCK="loginctl lock-session"
readonly SIG_OFF="dispatch dpms off"
readonly SIG_SUSPEND="systemctl suspend"

# Colors for Gum
readonly C_TEXT="212"    # Pink
readonly C_ACCENT="99"   # Purple
readonly C_WARN="208"    # Orange
readonly C_ERR="196"     # Red
readonly C_OK="35"       # Green

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
    local msg="$1"
    if command -v gum &>/dev/null; then
        gum style --foreground "$C_ERR" "✗ Error: $msg" >&2
    else
        printf '\033[1;31m✗ Error: %s\033[0m\n' "$msg" >&2
    fi
    exit 1
}

warn() {
    gum style --foreground "$C_WARN" "⚠ $1"
}

success() {
    gum style --foreground "$C_OK" "✓ $1"
}

info() {
    gum style --foreground "$C_ACCENT" "$1"
}

# Validate positive integer
is_positive_int() {
    local val="$1"
    [[ -n "$val" && "$val" =~ ^[0-9]+$ && "$val" -gt 0 ]]
}

#===============================================================================
# SETUP & VALIDATION
#===============================================================================

# Must be interactive
if [[ ! -t 0 || ! -t 1 ]]; then
    echo "Error: ${SCRIPT_NAME} must be run in an interactive terminal." >&2
    exit 1
fi

# Check and optionally install gum
if ! command -v gum &>/dev/null; then
    echo "Error: 'gum' is required but not installed."
    read -rp "Install it now via pacman? [y/N] " -n 1 REPLY
    echo
    if [[ "${REPLY:-n}" =~ ^[Yy]$ ]]; then
        echo "Installing gum..."
        if ! sudo pacman -S --needed --noconfirm gum; then
            echo "Failed to install gum." >&2
            exit 1
        fi
        # Verify installation succeeded
        if ! command -v gum &>/dev/null; then
            echo "gum installation appeared to succeed but binary not found." >&2
            exit 1
        fi
        echo "gum installed successfully."
    else
        echo "Cannot continue without gum." >&2
        exit 1
    fi
fi

# Validate config file
[[ -f "$CONFIG_FILE" ]] || die "Config file not found: $CONFIG_FILE"
[[ -r "$CONFIG_FILE" ]] || die "Config file not readable: $CONFIG_FILE"
[[ -w "$CONFIG_FILE" ]] || die "Config file not writable: $CONFIG_FILE"

# Create temp file (after gum check so we can use die())
TEMP_FILE=$(mktemp) || die "Failed to create temporary file"

#===============================================================================
# CORE FUNCTIONS
#===============================================================================

# Extract timeout value for a given signature
# Uses string matching (index()) instead of regex for reliability
get_timeout() {
    local signature="$1"
    
    awk -v sig="$signature" '
    BEGIN { in_block = 0; block = "" }
    
    /^[[:space:]]*listener[[:space:]]*\{?[[:space:]]*$/ {
        in_block = 1
        block = ""
        next
    }
    
    in_block {
        block = block $0 "\n"
        if (/^[[:space:]]*\}[[:space:]]*$/) {
            in_block = 0
            if (index(block, sig) > 0) {
                # Flexible matching: timeout followed by = and digits
                # Handles: timeout=300, timeout = 300, timeout  =  300
                if (match(block, /timeout[[:space:]]*=[[:space:]]*[0-9]+/)) {
                    val = substr(block, RSTART, RLENGTH)
                    gsub(/[^0-9]/, "", val)
                    print val
                    exit
                }
            }
            block = ""
        }
    }
    ' "$CONFIG_FILE" 2>/dev/null
}

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
    
    # Print non-listener lines as-is
    { print }
    
    # Handle unclosed block at EOF
    END {
        if (buffer != "") print buffer
    }
    ' "$CONFIG_FILE" > "$TEMP_FILE"
    
    # Verify output is valid (non-empty and similar size)
    if [[ ! -s "$TEMP_FILE" ]]; then
        die "Generated config is empty - aborting to prevent data loss"
    fi
    
    local orig_size new_size
    orig_size=$(wc -c < "$CONFIG_FILE")
    new_size=$(wc -c < "$TEMP_FILE")
    
    # Sanity check: new file shouldn't be drastically different in size
    if (( new_size < orig_size / 2 )); then
        die "Generated config is suspiciously small (${new_size} vs ${orig_size} bytes) - aborting"
    fi
    
    # Create backup before modifying
    if ! cp -f "$CONFIG_FILE" "$BACKUP_FILE"; then
        warn "Could not create backup at $BACKUP_FILE"
    fi
    
    # Atomic-ish update (mv is atomic on same filesystem)
    if ! mv -f "$TEMP_FILE" "$CONFIG_FILE"; then
        # Try to restore from backup
        if [[ -f "$BACKUP_FILE" ]]; then
            cp -f "$BACKUP_FILE" "$CONFIG_FILE" 2>/dev/null || true
        fi
        die "Failed to update config file"
    fi
    
    # Recreate temp file for potential future use
    TEMP_FILE=$(mktemp) || true
}

show_header() {
    gum style --border normal --margin "1" --padding "1 2" --border-foreground "$C_TEXT" \
        "$(gum style --foreground "$C_TEXT" --bold "HYPRIDLE") $(gum style --foreground "$C_ACCENT" "CONFIGURATION")"
}

prompt_timeout() {
    local current="$1"
    local header="$2"
    local result
    
    while true; do
        result=$(gum input \
            --placeholder "$current" \
            --value "$current" \
            --header "$header" \
            --header.foreground "$C_ACCENT") || {
            # User cancelled (ESC/Ctrl+C)
            echo "$current"
            return
        }
        
        if is_positive_int "$result"; then
            echo "$result"
            return
        elif [[ -z "$result" ]]; then
            # Empty input - keep current value
            echo "$current"
            return
        else
            warn "Please enter a positive integer (got: '$result')"
            sleep 1
        fi
    done
}

#===============================================================================
# MAIN LOGIC
#===============================================================================

main() {
    # Display header
    show_header
    
    # Load current values with safe defaults
    local CUR_DIM CUR_LOCK CUR_OFF CUR_SUSPEND
    
    CUR_DIM=$(get_timeout "$SIG_DIM")
    CUR_LOCK=$(get_timeout "$SIG_LOCK")
    CUR_OFF=$(get_timeout "$SIG_OFF")
    CUR_SUSPEND=$(get_timeout "$SIG_SUSPEND")
    
    # Apply defaults if parsing failed
    : "${CUR_DIM:=150}"
    : "${CUR_LOCK:=300}"
    : "${CUR_OFF:=310}"
    : "${CUR_SUSPEND:=500}"
    
    # Working copies
    local NEW_DIM="$CUR_DIM"
    local NEW_LOCK="$CUR_LOCK"
    local NEW_OFF="$CUR_OFF"
    local NEW_SUSPEND="$CUR_SUSPEND"
    
    # Interactive editing loop
    while true; do
        clear
        show_header
        
        local choice
        choice=$(gum choose \
            --cursor.foreground="$C_TEXT" \
            --selected.foreground="$C_TEXT" \
            --header "Select a value to edit:" \
            "1. Dim Screen     [${NEW_DIM}s]" \
            "2. Lock Session   [${NEW_LOCK}s]" \
            "3. Screen Off     [${NEW_OFF}s]" \
            "4. System Suspend [${NEW_SUSPEND}s]" \
            "───────────────────────────" \
            "↺ Reset to Defaults" \
            "▶ Apply Changes & Restart" \
            "✗ Exit Without Saving") || {
            # gum choose cancelled
            info "Cancelled."
            exit 0
        }
        
        case "$choice" in
            *"Dim Screen"*)
                NEW_DIM=$(prompt_timeout "$NEW_DIM" "Seconds until screen dims:")
                ;;
            *"Lock Session"*)
                NEW_LOCK=$(prompt_timeout "$NEW_LOCK" "Seconds until session locks:")
                ;;
            *"Screen Off"*)
                NEW_OFF=$(prompt_timeout "$NEW_OFF" "Seconds until screen turns off:")
                ;;
            *"System Suspend"*)
                NEW_SUSPEND=$(prompt_timeout "$NEW_SUSPEND" "Seconds until system suspends:")
                ;;
            *"Reset to Defaults"*)
                # 1. Update working variables
                NEW_DIM="$PRESET_DIM"
                NEW_LOCK="$PRESET_LOCK"
                NEW_OFF="$PRESET_OFF"
                NEW_SUSPEND="$PRESET_SUSPEND"
                
                # 2. Write to config
                echo
                gum spin --spinner dot --title "Resetting & Saving configuration..." -- sleep 0.2
                update_all_timeouts "$NEW_DIM" "$NEW_LOCK" "$NEW_OFF" "$NEW_SUSPEND"
                
                # 3. Restart service
                echo
                if systemctl --user is-active --quiet hypridle 2>/dev/null; then
                    if gum spin --spinner monkey --title "Restarting hypridle service..." -- \
                        systemctl --user restart hypridle; then
                        success "Hypridle restarted successfully!"
                    else
                        gum style --foreground "$C_ERR" "✗ Failed to restart hypridle"
                    fi
                else
                    if gum confirm "Start hypridle now?"; then
                        if gum spin --spinner monkey --title "Starting hypridle service..." -- \
                            systemctl --user start hypridle; then
                            success "Hypridle started successfully!"
                        else
                            gum style --foreground "$C_ERR" "✗ Failed to start hypridle"
                        fi
                    fi
                fi
                
                # 4. Update internal state
                CUR_DIM="$NEW_DIM"
                CUR_LOCK="$NEW_LOCK"
                CUR_OFF="$NEW_OFF"
                CUR_SUSPEND="$NEW_SUSPEND"
                
                echo
                info "Defaults applied successfully."
                sleep 1.5
                ;;
            *"Apply"*)
                # Validate logical order of timeouts
                local warnings=""
                if (( NEW_DIM >= NEW_LOCK )); then
                    warnings+="  • Dim (${NEW_DIM}s) should be < Lock (${NEW_LOCK}s)\n"
                fi
                if (( NEW_LOCK >= NEW_OFF )); then
                    warnings+="  • Lock (${NEW_LOCK}s) should be < Screen Off (${NEW_OFF}s)\n"
                fi
                if (( NEW_OFF >= NEW_SUSPEND )); then
                    warnings+="  • Screen Off (${NEW_OFF}s) should be < Suspend (${NEW_SUSPEND}s)\n"
                fi
                
                if [[ -n "$warnings" ]]; then
                    echo
                    gum style --border double --border-foreground "$C_WARN" --padding "1" --margin "0 1" \
                        "$(gum style --foreground "$C_WARN" --bold "⚠ TIMELINE WARNING")" \
                        "" \
                        "Your timeout order may not make sense:" \
                        "" \
                        "$(printf '%b' "$warnings")" \
                        "Expected order: Dim < Lock < Screen Off < Suspend"
                    
                    echo
                    if ! gum confirm --affirmative="Apply Anyway" --negative="Go Back"; then
                        continue
                    fi
                fi
                
                # Check if anything actually changed
                if [[ "$NEW_DIM" == "$CUR_DIM" && \
                      "$NEW_LOCK" == "$CUR_LOCK" && \
                      "$NEW_OFF" == "$CUR_OFF" && \
                      "$NEW_SUSPEND" == "$CUR_SUSPEND" ]]; then
                    echo
                    info "No values changed. Nothing to do."
                    sleep 1
                    continue
                fi
                
                # Apply all changes in one atomic operation
                echo
                gum spin --spinner dot --title "Writing configuration..." -- sleep 0.2
                update_all_timeouts "$NEW_DIM" "$NEW_LOCK" "$NEW_OFF" "$NEW_SUSPEND"
                
                # Handle service restart
                echo
                if systemctl --user is-active --quiet hypridle 2>/dev/null; then
                    if gum spin --spinner monkey --title "Restarting hypridle service..." -- \
                        systemctl --user restart hypridle; then
                        success "Hypridle restarted successfully!"
                    else
                        gum style --foreground "$C_ERR" "✗ Failed to restart hypridle"
                    fi
                else
                    if gum confirm "Start hypridle now?"; then
                        if gum spin --spinner monkey --title "Starting hypridle service..." -- \
                            systemctl --user start hypridle; then
                            success "Hypridle started successfully!"
                        else
                            gum style --foreground "$C_ERR" "✗ Failed to start hypridle"
                        fi
                    fi
                fi
                
                # Update current state to match new state
                CUR_DIM="$NEW_DIM"
                CUR_LOCK="$NEW_LOCK"
                CUR_OFF="$NEW_OFF"
                CUR_SUSPEND="$NEW_SUSPEND"
                
                echo
                info "Settings applied. Returning to menu..."
                sleep 2
                ;;
            *"Exit"* | *"───"*)
                info "No changes made."
                exit 0
                ;;
        esac
    done
}

# Run main function
main "$@"
