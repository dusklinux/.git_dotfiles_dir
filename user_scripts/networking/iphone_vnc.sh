#!/usr/bin/env bash

# ==============================================================================
#  Title:        iPhone Headless Link (v4.3 - User Configurable)
#  Description:  Connects iPhone via USB Tethering + VNC to a headless output.
#  Usage:        iphone_link.sh [--log] [--help]
# ==============================================================================

# --- Strict Mode & Safety ---
set -o nounset      # Error on unset variables
set -o pipefail     # Pipe fails on first error
shopt -s nullglob   # Empty glob returns empty

# ==============================================================================
#  USER CONFIGURATION (EDIT ME)
# ==============================================================================

# Default Resolution (WxH). 
# 1080x960 is approx half-height of standard 1080p, leaving room for keyboard.
declare DEFAULT_RES="1080x960"

# Default UI Scale.
# 3.0 makes UI elements large and touch-friendly on phone screens.
declare DEFAULT_SCALE="1.0"

# VNC Port
declare DEFAULT_PORT="5900"

# Max FPS (Keep at 30 to prevent Hybrid GPU crashes)
declare -i DEFAULT_FPS=30

# DHCP Timeout in seconds
declare -i DEFAULT_DHCP_TIMEOUT=30

# Main loop check interval in seconds
declare -i DEFAULT_CHECK_INTERVAL=2

# ==============================================================================
#  INTERNAL CONFIGURATION (DO NOT EDIT BELOW)
# ==============================================================================

# Apply Environment Variable Overrides or fall back to User Config
declare VIRT_RES="${IPHONE_RES:-$DEFAULT_RES}"
declare SCALE="${IPHONE_SCALE:-}"  # If empty, we ask interactively (or use default fallback)
declare VNC_PORT="${IPHONE_PORT:-$DEFAULT_PORT}"
declare -i MAX_FPS="${IPHONE_FPS:-$DEFAULT_FPS}"
declare -i DHCP_TIMEOUT="${IPHONE_DHCP_TIMEOUT:-$DEFAULT_DHCP_TIMEOUT}"
declare -i CHECK_INTERVAL="${IPHONE_CHECK_INTERVAL:-$DEFAULT_CHECK_INTERVAL}"

# --- Constants ---
declare -r SCRIPT_NAME="${0##*/}"
declare -r RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
declare -r LOCKFILE="${RUNTIME_DIR}/iphone_link.lock"
declare -r SUDOERS_FILE="/etc/sudoers.d/iphone_link"
declare -r LOG_FILE="${RUNTIME_DIR}/wayvnc_iphone_$$.log"
declare -r DHCP_PIDFILE="${RUNTIME_DIR}/iphone_dhcpcd.pid"

# --- Runtime State ---
declare RUNNING_HEADLESS_NAME=""
declare -i VNC_PID=0
declare -i DHCP_PID=0
declare LAST_IFACE=""
declare SUDO_PASS=""
declare -i VERBOSE_MODE=0
declare -i LOCK_ACQUIRED=0

# --- Help Menu ---
show_help() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Connects iPhone via USB Tethering + VNC to a Hyprland headless output.

Options:
    --log           Enable verbose debug logging
    -h, --help      Show this help message

Configuration Defaults (Edit script top to change):
    Resolution:     $DEFAULT_RES
    Scale:          $DEFAULT_SCALE
    Port:           $DEFAULT_PORT
    FPS:            $DEFAULT_FPS

Environment Variables (Override defaults):
    IPHONE_RES      Resolution
    IPHONE_SCALE    UI Scale
    IPHONE_PORT     VNC Port
    IPHONE_FPS      Max FPS

Examples:
    # Use defaults
    ./${SCRIPT_NAME}
    
    # Override resolution just for this run
    IPHONE_RES=1920x1080 ./${SCRIPT_NAME}
EOF
    exit 0
}

# --- Argument Parsing ---
parse_arguments() {
    while (($# > 0)); do
        case "$1" in
            --log)
                VERBOSE_MODE=1
                ;;
            -h|--help)
                show_help
                ;;
            -*)
                die "Unknown option: $1 (use --help for usage)"
                ;;
            *)
                die "Unexpected argument: $1 (use --help for usage)"
                ;;
        esac
        shift
    done
}

# --- Logging ---
log()     { printf '\033[0;34m[iPhone-Link]\033[0m %s\n' "$*"; }
warn()    { printf '\033[0;33m[WARN]\033[0m %s\n' "$*" >&2; }
error()   { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; }
success() { printf '\033[0;32m[SUCCESS]\033[0m %s\n' "$*"; }
debug()   { ((VERBOSE_MODE)) && printf '\033[0;90m[DEBUG]\033[0m %s\n' "$*" >&2; }
die()     { error "$*"; exit 1; }

# --- User Interaction (Scale Selection) ---
select_scale() {
    # 1. Environment Variable (Highest Priority)
    if [[ -n "$SCALE" ]]; then
        log "Using configured scale: $SCALE"
        return 0
    fi

    # 2. Non-interactive fallback
    if [[ ! -t 0 ]]; then
        warn "Non-interactive session detected. Defaulting scale to $DEFAULT_SCALE"
        SCALE="$DEFAULT_SCALE"
        return 0
    fi

    # 3. Interactive Menu with Timeout
    echo ""
    log "Select UI Scale Factor (Auto-selects $DEFAULT_SCALE in 10s):"
    echo "  1) 1.0  (Tiny UI)"
    echo "  2) 2.0  (Standard Retina)"
    echo "  3) 3.0  (Large/Accessibility) [Default]"
    echo "  4) Custom"
    
    local choice
    # Use -t 10 to timeout after 10 seconds if no input
    if ! read -t 10 -r -p "Enter choice [1-4]: " choice; then
        echo ""
        log "Timeout reached. Defaulting to Scale: $DEFAULT_SCALE"
        SCALE="$DEFAULT_SCALE"
        return 0
    fi
    
    case "$choice" in
        1) SCALE="1.0" ;;
        2) SCALE="2.0" ;;
        3) SCALE="3.0" ;;
        4) 
            read -r -p "Enter custom scale (e.g. 1.5): " SCALE
            if [[ ! "$SCALE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                warn "Invalid scale format. Reverting to $DEFAULT_SCALE"
                SCALE="$DEFAULT_SCALE"
            fi
            ;;
        *) 
            log "Using Default Scale: $DEFAULT_SCALE"
            SCALE="$DEFAULT_SCALE" 
            ;;
    esac
    log "Selected Scale: $SCALE"
    echo ""
}

# --- Environment Verification ---
verify_environment() {
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        die "No Wayland display detected. This script requires Hyprland/Wayland."
    fi
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        die "Hyprland not detected. This script requires Hyprland compositor."
    fi
    if [[ ! -d "$RUNTIME_DIR" || ! -w "$RUNTIME_DIR" ]]; then
        die "Runtime directory issue: $RUNTIME_DIR"
    fi
    debug "Environment verified: Hyprland on Wayland"
}

# --- Lockfile Management ---
acquire_lock() {
    if ! touch "$LOCKFILE" 2>/dev/null; then
        die "Cannot create lockfile: $LOCKFILE"
    fi
    exec {LOCK_FD}>"$LOCKFILE"
    if ! flock -n "$LOCK_FD"; then
        die "Another instance is already running."
    fi
    LOCK_ACQUIRED=1
}

release_lock() {
    if ((LOCK_ACQUIRED)) && ((LOCK_FD > 0)); then
        flock -u "$LOCK_FD" 2>/dev/null || true
        exec {LOCK_FD}>&- 2>/dev/null || true
        rm -f "$LOCKFILE" 2>/dev/null || true
        LOCK_ACQUIRED=0
    fi
}

# --- Sudo Management (Secure) ---
init_sudo() {
    if sudo -n true 2>/dev/null; then
        debug "Passwordless sudo is active."
        return 0
    fi
    if [[ ! -t 0 ]]; then
        die "Interactive terminal required for password input."
    fi
    log "Sudo privileges required for network configuration."
    local -i attempts=0
    while ((attempts < 3)); do
        IFS= read -rs -p "[sudo] password for $USER: " SUDO_PASS
        printf '\n'
        [[ -z "$SUDO_PASS" ]] && { error "Password empty."; ((attempts++)); continue; }
        if sudo -S -p '' true <<< "$SUDO_PASS" 2>/dev/null; then
            success "Password accepted."
            return 0
        fi
        error "Incorrect password."
        ((attempts++))
    done
    SUDO_PASS=""
    die "Too many failed password attempts."
}

run_sudo() {
    if [[ -n "$SUDO_PASS" ]]; then
        sudo -S -p '' "$@" <<< "$SUDO_PASS" 2>/dev/null
    else
        sudo "$@"
    fi
}

# --- Network & Conflict Fixers ---
fix_network_blockers() {
    local iface="$1"
    log "Scanning for network blockers..."
    if command -v warp-cli &>/dev/null; then
        local warp_status
        warp_status=$(warp-cli status 2>/dev/null) || warp_status=""
        if [[ "$warp_status" == *"Connected"* ]]; then
            warn "Cloudflare Warp is ACTIVE. If connection fails, run: warp-cli disconnect"
        fi
    fi
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        debug "Configuring Firewalld..."
        if ! run_sudo firewall-cmd --zone=trusted --query-interface="$iface" &>/dev/null; then
            run_sudo firewall-cmd --zone=trusted --add-interface="$iface" &>/dev/null || true
        fi
        run_sudo firewall-cmd --add-port="${VNC_PORT}/tcp" &>/dev/null || true
    fi
    if command -v ufw &>/dev/null; then
        local ufw_status
        ufw_status=$(run_sudo ufw status 2>/dev/null) || ufw_status=""
        if [[ "$ufw_status" == *"Status: active"* ]]; then
            if [[ "$ufw_status" != *"$VNC_PORT"* ]]; then
                log "Configuring UFW..."
                run_sudo ufw allow "${VNC_PORT}/tcp" &>/dev/null || true
                run_sudo ufw allow in on "$iface" to any &>/dev/null || true
            fi
        fi
    fi
    if command -v iptables &>/dev/null; then
        local input_header
        input_header=$(run_sudo iptables -L INPUT -n 2>/dev/null | head -1) || input_header=""
        if [[ "$input_header" =~ policy[[:space:]]+(DROP|REJECT) ]]; then
            debug "Opening iptables for $iface..."
            if ! run_sudo iptables -C INPUT -i "$iface" -j ACCEPT 2>/dev/null; then
                run_sudo iptables -I INPUT 1 -i "$iface" -j ACCEPT 2>/dev/null || true
            fi
            if ! run_sudo iptables -C INPUT -p tcp --dport "$VNC_PORT" -j ACCEPT 2>/dev/null; then
                run_sudo iptables -I INPUT 1 -p tcp --dport "$VNC_PORT" -j ACCEPT 2>/dev/null || true
            fi
        fi
    fi
}

# --- Sudoers Automation ---
setup_sudoers() {
    if sudo -n ip link show lo &>/dev/null; then return 0; fi
    if run_sudo test -f "$SUDOERS_FILE" 2>/dev/null; then return 0; fi

    printf '\n'
    log "Optional: Create permanent sudo rule?"
    printf '%s\n' "This avoids asking for the password next time."
    local reply
    read -r -p "Create $SUDOERS_FILE? (y/N): " reply
    if [[ ! "${reply:-}" =~ ^[Yy]$ ]]; then return 0; fi

    log "Creating $SUDOERS_FILE..."
    local ip_path dhcp_path
    ip_path=$(command -v ip) || die "ip not found"
    dhcp_path=$(command -v dhcpcd) || die "dhcpcd not found"
    local fw_path="" ufw_path="" ipt_path="" pkill_path=""
    fw_path=$(command -v firewall-cmd 2>/dev/null) || true
    ufw_path=$(command -v ufw 2>/dev/null) || true
    ipt_path=$(command -v iptables 2>/dev/null) || true
    pkill_path=$(command -v pkill 2>/dev/null) || true
    
    local cmds="$ip_path, $dhcp_path"
    [[ -n "$fw_path" ]] && cmds+=", $fw_path"
    [[ -n "$ufw_path" ]] && cmds+=", $ufw_path"
    [[ -n "$ipt_path" ]] && cmds+=", $ipt_path"
    [[ -n "$pkill_path" ]] && cmds+=", $pkill_path"
    
    local rule="${USER} ALL=(ALL) NOPASSWD: ${cmds}"
    local temp_sudoers
    temp_sudoers=$(mktemp) || die "Failed to create temp file"
    printf '%s\n' "$rule" > "$temp_sudoers"
    chmod 440 "$temp_sudoers"
    
    if ! visudo -c -f "$temp_sudoers" &>/dev/null; then
        rm -f "$temp_sudoers"
        error "Sudoers syntax check failed."
        return 1
    fi
    
    if run_sudo cp "$temp_sudoers" "$SUDOERS_FILE" && \
       run_sudo chmod 440 "$SUDOERS_FILE" && \
       run_sudo chown root:root "$SUDOERS_FILE"; then
        rm -f "$temp_sudoers"
        success "Rule created!"
        return 0
    else
        rm -f "$temp_sudoers"
        error "Failed to install rule."
        return 1
    fi
}

# --- Dependency Check ---
check_dependencies() {
    local -A dependencies=(
        ["hyprctl"]="hyprland"
        ["wayvnc"]="wayvnc"
        ["dhcpcd"]="dhcpcd"
        ["ip"]="iproute2"
        ["usbmuxd"]="usbmuxd"
        ["ss"]="iproute2"
        ["flock"]="util-linux"
        ["awk"]="gawk"
    )
    local -A pkgs_needed=()
    for cmd in "${!dependencies[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            local pkg="${dependencies[$cmd]}"
            log "Missing command: $cmd (package: $pkg)"
            pkgs_needed["$pkg"]=1
        fi
    done
    if ((${#pkgs_needed[@]} > 0)); then
        local -a to_install=("${!pkgs_needed[@]}")
        log "Installing: ${to_install[*]}"
        if ! run_sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
            die "Installation failed."
        fi
    fi
    if ! systemctl is-active --quiet usbmuxd 2>/dev/null; then
        log "Starting usbmuxd..."
        run_sudo systemctl start usbmuxd || warn "Failed to start usbmuxd"
    fi
}

# --- Cleanup ---
cleanup() {
    local exit_code=$?
    trap - SIGINT SIGTERM EXIT
    if ((VNC_PID > 0)) || [[ -n "$RUNNING_HEADLESS_NAME" ]]; then
        log "Cleaning up..."
    fi
    if ((VNC_PID > 0)); then
        kill "$VNC_PID" 2>/dev/null || true
        wait "$VNC_PID" 2>/dev/null || true
    fi
    if ((DHCP_PID > 0)); then
        run_sudo kill "$DHCP_PID" 2>/dev/null || true
    fi
    if [[ -f "$DHCP_PIDFILE" ]]; then
        local stored_pid
        stored_pid=$(<"$DHCP_PIDFILE") 2>/dev/null || true
        if [[ -n "$stored_pid" ]] && kill -0 "$stored_pid" 2>/dev/null; then
            run_sudo kill "$stored_pid" 2>/dev/null || true
        fi
        rm -f "$DHCP_PIDFILE" 2>/dev/null || true
    fi
    if [[ -n "$RUNNING_HEADLESS_NAME" ]]; then
        log "Removing virtual display..."
        hyprctl output remove "$RUNNING_HEADLESS_NAME" &>/dev/null || true
    fi
    release_lock
    [[ -f "$LOG_FILE" ]] && ((VERBOSE_MODE == 0)) && rm -f "$LOG_FILE"
    SUDO_PASS=""
    exit "$exit_code"
}

# --- Helpers ---
get_iphone_iface() {
    local iface_path iface_name driver_link
    for iface_path in /sys/class/net/*; do
        [[ -e "$iface_path" ]] || continue
        iface_name="${iface_path##*/}"
        [[ "$iface_name" == "lo" || "$iface_name" == wl* || "$iface_name" == wlan* ]] && continue
        driver_link=$(readlink -f "$iface_path/device/driver" 2>/dev/null) || continue
        if [[ "$driver_link" == *"ipheth"* ]]; then
            printf '%s' "$iface_name"
            return 0
        fi
    done
    return 1
}

get_ip_address() {
    local iface="$1"
    local -i retries=0
    local -i max_retries=50
    local ip_addr=""
    while ((retries < max_retries)); do
        ip_addr=$(ip -4 -o addr show "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
        if [[ -n "$ip_addr" ]]; then
            printf '%s' "$ip_addr"
            return 0
        fi
        sleep 0.5
        ((retries++))
        if ((retries % 10 == 0)); then
            debug "Waiting for IP... ($retries/$max_retries)"
        fi
    done
    return 1
}

get_headless_monitors() {
    if command -v jq &>/dev/null; then
        hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' 2>/dev/null
    else
        hyprctl monitors -j 2>/dev/null | grep -oE '"name":[[:space:]]*"HEADLESS-[0-9]+"' | sed 's/"name":[[:space:]]*"//;s/"$//'
    fi
}

ensure_display_exists() {
    if [[ -n "$RUNNING_HEADLESS_NAME" ]]; then
        if get_headless_monitors | grep -qx "$RUNNING_HEADLESS_NAME"; then
            return 0
        fi
        RUNNING_HEADLESS_NAME=""
    fi
    
    local existing
    existing=$(get_headless_monitors | tail -1)
    
    if [[ -n "$existing" ]]; then
        RUNNING_HEADLESS_NAME="$existing"
        log "Adopting existing display: $RUNNING_HEADLESS_NAME"
    else
        log "Creating new headless display..."
        if ! hyprctl output create headless &>/dev/null; then
            error "Failed to create headless output."
            return 1
        fi
        sleep 1.0
        RUNNING_HEADLESS_NAME=$(get_headless_monitors | tail -1)
        if [[ -z "$RUNNING_HEADLESS_NAME" ]]; then
            error "Creation failed - no display found."
            return 1
        fi
        log "Created display: $RUNNING_HEADLESS_NAME"
    fi
    
    # APPLY RESOLUTION AND SCALE
    debug "Setting: $RUNNING_HEADLESS_NAME @ $VIRT_RES (Scale: $SCALE)"
    if ! hyprctl keyword monitor "${RUNNING_HEADLESS_NAME},${VIRT_RES},auto,${SCALE}" &>/dev/null; then
        warn "Failed to set monitor config."
    fi
    return 0
}

setup_connection() {
    local iface="$1"
    log "Configuring interface: $iface"
    
    if ! ip link show "$iface" 2>/dev/null | grep -q "state UP"; then
        run_sudo ip link set "$iface" up || { error "Failed to up interface"; return 1; }
        run_sudo pkill -f "dhcpcd.*[[:space:]]${iface}$" 2>/dev/null || true
        sleep 0.5
        debug "Starting DHCP..."
        run_sudo dhcpcd -4 -w -t "$DHCP_TIMEOUT" --pidfile "$DHCP_PIDFILE" "$iface" &>/dev/null &
        sleep 1
        if [[ -f "$DHCP_PIDFILE" ]]; then
            DHCP_PID=$(<"$DHCP_PIDFILE") 2>/dev/null || DHCP_PID=0
        else
            DHCP_PID=$!
        fi
    fi

    log "Waiting for Hotspot IP..."
    local bind_ip
    if ! bind_ip=$(get_ip_address "$iface"); then
        error "IP Timeout. Is Personal Hotspot ON?"
        return 1
    fi
    log "Obtained IP: $bind_ip"
    
    fix_network_blockers "$iface"
    ensure_display_exists || return 1

    log "Starting WayVNC on $bind_ip:$VNC_PORT..."
    local pids
    pids=$(ss -tlnp 2>/dev/null | awk -v port="$VNC_PORT" '$4 ~ ":"port"$" {print $0}' | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u)
    [[ -n "$pids" ]] && for pid in $pids; do kill "$pid" 2>/dev/null || true; done
    
    local -a vnc_args=("$bind_ip" "$VNC_PORT" "--max-fps=$MAX_FPS" "--output=$RUNNING_HEADLESS_NAME")
    if ((VERBOSE_MODE)); then
        wayvnc "${vnc_args[@]}" 2>&1 | tee "$LOG_FILE" &
    else
        wayvnc "${vnc_args[@]}" >"$LOG_FILE" 2>&1 &
    fi
    VNC_PID=$!

    local -i verify=0
    while ((verify < 5)); do
        sleep 0.5
        if ! kill -0 "$VNC_PID" 2>/dev/null; then
            error "WayVNC died."
            [[ -f "$LOG_FILE" ]] && cat "$LOG_FILE" >&2
            return 1
        fi
        if ss -tln 2>/dev/null | grep -q ":${VNC_PORT}[[:space:]]"; then break; fi
        ((verify++))
    done
    
    if ((verify >= 5)); then error "WayVNC bind failed."; kill "$VNC_PID" 2>/dev/null; return 1; fi

    success "═══════════════════════════════════════════════════════════"
    success " VNC Ready! $bind_ip:$VNC_PORT"
    success " Display: $RUNNING_HEADLESS_NAME @ $VIRT_RES (Scale: $SCALE)"
    success "═══════════════════════════════════════════════════════════"
    return 0
}

# --- Main ---
main() {
    parse_arguments "$@"
    verify_environment
    acquire_lock
    trap cleanup SIGINT SIGTERM EXIT
    
    init_sudo
    check_dependencies
    setup_sudoers
    select_scale # Ask user for scale preference
    
    log "Daemon active. Monitoring..."
    ((VERBOSE_MODE)) && log "VERBOSE LOGGING ENABLED"
    ensure_display_exists
    
    local current_iface=""
    while true; do
        current_iface=$(get_iphone_iface) || current_iface=""
        if [[ -n "$current_iface" ]]; then
            if [[ "$current_iface" != "$LAST_IFACE" ]]; then
                log "iPhone detected: $current_iface"
                if setup_connection "$current_iface"; then
                    LAST_IFACE="$current_iface"
                else
                    warn "Setup failed. Retrying..."
                    LAST_IFACE=""
                    ((VNC_PID > 0)) && kill "$VNC_PID" 2>/dev/null
                    sleep "$CHECK_INTERVAL"
                fi
            else
                if ((VNC_PID > 0)) && ! kill -0 "$VNC_PID" 2>/dev/null; then
                    error "VNC crashed. Restarting..."
                    LAST_IFACE=""
                    VNC_PID=0
                fi
            fi
        else
            if [[ -n "$LAST_IFACE" ]]; then
                log "iPhone disconnected."
                ((VNC_PID > 0)) && kill "$VNC_PID" 2>/dev/null
                ((DHCP_PID > 0)) && run_sudo kill "$DHCP_PID" 2>/dev/null
                LAST_IFACE=""
                VNC_PID=0
                DHCP_PID=0
            fi
        fi
        sleep "$CHECK_INTERVAL"
    done
}

main "$@"
