#!/usr/bin/env bash
# This is to auto automatically detect your GPU and set the appropriate Environment Variables
# -----------------------------------------------------------------------------
# Elite DevOps Arch/Hyprland/UWSM GPU Configurator
# -----------------------------------------------------------------------------
# Role:       System Architect
# Objective:  Detect GPU, configure UWSM env vars, and ensure stability.
# Standards:  Bash 5+, Strict Mode, Idempotent Operations.
# -----------------------------------------------------------------------------

# --- 1. STRICT MODE & TRAPS ---
set -euo pipefail
# Inherit error checking in subshells (Bash 4.4+)
shopt -s inherit_errexit 2>/dev/null || true

# --- 2. CONSTANTS ---
readonly BOLD=$'\033[1m'
readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m'
readonly YELLOW=$'\033[33m'
readonly BLUE=$'\033[34m'
readonly RESET=$'\033[0m'

readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm"
readonly ENV_FILE="$CONFIG_DIR/env"
readonly ENV_HYPR_FILE="$CONFIG_DIR/env-hyprland"

# --- 3. LOGGING & CLEANUP ---

log_info()  { printf "%s[INFO]%s %s\n" "${BLUE}${BOLD}" "${RESET}" "$*"; }
log_ok()    { printf "%s[OK]%s %s\n" "${GREEN}${BOLD}" "${RESET}" "$*"; }
log_warn()  { printf "%s[WARN]%s %s\n" "${YELLOW}" "${RESET}" "$*" >&2; }
log_error() { printf "%s[ERROR]%s %s\n" "${RED}${BOLD}" "${RESET}" "$*" >&2; }

# Automatic cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed on line ${1:-unknown}. Exit code: $exit_code"
        log_warn "Attempting to restore backups..."
        # Restore backups if they exist
        [[ -f "${ENV_FILE}.bak" ]] && mv -f "${ENV_FILE}.bak" "$ENV_FILE" 2>/dev/null || true
        [[ -f "${ENV_HYPR_FILE}.bak" ]] && mv -f "${ENV_HYPR_FILE}.bak" "$ENV_HYPR_FILE" 2>/dev/null || true
    else
        # Success - remove backups
        rm -f "${ENV_FILE}.bak" "${ENV_HYPR_FILE}.bak" 2>/dev/null || true
    fi
}
# Pass LINENO to trap to identify where it failed
trap 'cleanup $LINENO' EXIT

# --- 4. PRE-FLIGHT CHECKS ---

preflight_checks() {
    # Privilege Check
    if [[ $EUID -eq 0 ]]; then
        log_error "Do NOT run this script as root/sudo."
        printf "%s  -> This script modifies your user configuration in ~/.config\n" "${YELLOW}" >&2
        printf "  -> Running as root will cause permission errors.\n" >&2
        printf "  -> Run as: %s./configure_uwsm_gpu.sh%s\n" "${BOLD}" "${RESET}" >&2
        exit 1
    fi

    # Dependency Check
    if ! command -v lspci &>/dev/null; then
        log_error "'lspci' command not found."
        printf "Please install pciutils: %ssudo pacman -S pciutils%s\n" "${BOLD}" "${RESET}" >&2
        exit 1
    fi

    # Config Check
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "Config file not found: $ENV_FILE"
        exit 1
    fi
    if [[ ! -f "$ENV_HYPR_FILE" ]]; then
        log_error "Config file not found: $ENV_HYPR_FILE"
        exit 1
    fi
}

# --- 5. GPU DETECTION ---

declare -a GPU_PATHS
declare -a GPU_VENDORS
declare -a GPU_NAMES

detect_gpus() {
    log_info "Scanning for Graphics Processing Units..."

    shopt -s nullglob
    # Scan card0-9 and card10-99. Ignores connectors like card0-HDMI-A-1
    for card in /sys/class/drm/card[0-9] /sys/class/drm/card[1-9][0-9]; do
        # Verify it is a directory and has a vendor ID
        [[ -d "$card" && -r "$card/device/vendor" ]] || continue

        local card_path="/dev/dri/${card##*/}"
        # Read vendor ID (using bash builtin for speed)
        local vendor_id
        vendor_id=$(<"$card/device/vendor")
        # Trim potential whitespace
        vendor_id="${vendor_id//[[:space:]]/}"

        local vendor_name
        case "$vendor_id" in
            "0x8086") vendor_name="intel" ;;
            "0x10de") vendor_name="nvidia" ;;
            "0x1002") vendor_name="amd" ;;
            *)        vendor_name="unknown" ;;
        esac

        # Get Human Readable Name via lspci
        local pretty_name="Unknown Device"
        if [[ -L "$card/device" ]]; then
            local pci_slot
            pci_slot=$(basename "$(readlink "$card/device")")
            # Robust lspci parsing: Expects "Key: Value" format with tabs
            if val=$(lspci -vmm -s "$pci_slot" 2>/dev/null | awk -F$'\t' '/^Device:/{print $2; exit}'); then
                [[ -n "$val" ]] && pretty_name="$val"
            fi
        fi

        GPU_PATHS+=("$card_path")
        GPU_VENDORS+=("$vendor_name")
        GPU_NAMES+=("$pretty_name ($vendor_name)")
    done
    shopt -u nullglob
}

# --- 6. USER SELECTION ---

SELECTED_VENDOR=""
SELECTED_CARD=""

select_gpu() {
    local count=${#GPU_PATHS[@]}
    local choice confirm idx

    if [[ $count -eq 0 ]]; then
        log_warn "No GPU automatically detected via sysfs."
        printf "Please manually select your driver:\n"
        printf "  1) Intel\n  2) AMD\n  3) Nvidia\n"
        
        # Handle Ctrl+D or empty input
        if ! read -rp "Selection [1-3]: " choice; then
             printf "\n"; log_warn "Input cancelled."; exit 1
        fi

        case "$choice" in
            1) SELECTED_VENDOR="intel"; SELECTED_CARD="" ;; 
            2) SELECTED_VENDOR="amd"; SELECTED_CARD="" ;;
            3) SELECTED_VENDOR="nvidia"; SELECTED_CARD="" ;;
            *) log_error "Invalid selection."; exit 1 ;;
        esac

    elif [[ $count -eq 1 ]]; then
        log_ok "Detected: ${GPU_NAMES[0]} at ${GPU_PATHS[0]}"
        
        if ! read -rp "Confirm configuration for this GPU? [Y/n] " confirm; then
            printf "\n"; confirm="n"
        fi
        
        if [[ "${confirm,,}" =~ ^n ]]; then
            log_warn "Operation cancelled by user."; exit 0
        fi
        SELECTED_VENDOR="${GPU_VENDORS[0]}"
        SELECTED_CARD="${GPU_PATHS[0]}"

    else
        log_ok "Multiple GPUs detected:"
        for i in "${!GPU_NAMES[@]}"; do
            printf "  %s%d)%s %s  [%s]\n" "${BOLD}" "$((i+1))" "${RESET}" "${GPU_NAMES[$i]}" "${GPU_PATHS[$i]}"
        done
        
        printf "\n%sWhich GPU should drive the Hyprland Session?%s\n" "${YELLOW}" "${RESET}"
        printf "(Note: Integrated GPU is usually recommended for the compositor on laptops)\n"
        
        if ! read -rp "Select Number [1-$count]: " choice; then
            printf "\n"; log_warn "Input cancelled."; exit 1
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
            idx=$((choice-1))
            SELECTED_VENDOR="${GPU_VENDORS[$idx]}"
            SELECTED_CARD="${GPU_PATHS[$idx]}"
        else
            log_error "Invalid selection '$choice'."
            exit 1
        fi
    fi
}

# --- 7. CONFIGURATION LOGIC ---

# Helper to escape strings for use in sed regex patterns
escape_sed() {
    printf '%s\n' "$1" | sed 's/[][\.*^$(){}?+|/]/\\&/g'
}

disable_section() {
    local start_marker="$1"
    local end_marker="$2"
    local s_esc e_esc
    s_esc=$(escape_sed "$start_marker")
    e_esc=$(escape_sed "$end_marker")
    
    # Comment out lines starting with 'export' inside the block
    sed -i "/${s_esc}/,/${e_esc}/ s/^[[:space:]]*export /# export /" "$ENV_FILE"
}

enable_section() {
    local start_marker="$1"
    local end_marker="$2"
    local s_esc e_esc
    s_esc=$(escape_sed "$start_marker")
    e_esc=$(escape_sed "$end_marker")
    
    # Uncomment lines: handles "# export", "# # export", etc.
    sed -i "/${s_esc}/,/${e_esc}/ s/^#[#[:space:]]*export /export /" "$ENV_FILE"
}

apply_config() {
    printf "\n%s[CONFIG] Applying configurations for: %s%s\n" "${BLUE}${BOLD}" "${SELECTED_VENDOR^^}" "${RESET}"

    # 1. CREATE BACKUPS (handled by trap if we fail)
    cp -p "$ENV_FILE" "${ENV_FILE}.bak"
    cp -p "$ENV_HYPR_FILE" "${ENV_HYPR_FILE}.bak"

    # 2. UPDATE ENV FILE
    printf "  -> Updating %s...\n" "$ENV_FILE"
    
    # Reset all
    disable_section "### HARDWARE: INTEL ###" "### HARDWARE: AMD ###"
    disable_section "### HARDWARE: AMD ###" "### HARDWARE: NVIDIA ###"
    disable_section "### HARDWARE: NVIDIA ###" "# 6. VIRTUALIZATION"

    # Enable selected
    case "$SELECTED_VENDOR" in
        "intel")
            enable_section "### HARDWARE: INTEL ###" "### HARDWARE: AMD ###"
            ;;
        "amd")
            enable_section "### HARDWARE: AMD ###" "### HARDWARE: NVIDIA ###"
            ;;
        "nvidia")
            enable_section "### HARDWARE: NVIDIA ###" "# 6. VIRTUALIZATION"
            ;;
        *)
            log_warn "Vendor '$SELECTED_VENDOR' unknown. No env sections enabled."
            ;;
    esac

    # 3. UPDATE ENV-HYPRLAND FILE
    printf "  -> Updating %s...\n" "$ENV_HYPR_FILE"

    if [[ -n "$SELECTED_CARD" ]]; then
        # Escape special chars in the path for sed (just in case path has odd chars)
        local card_esc
        card_esc=$(printf '%s\n' "$SELECTED_CARD" | sed 's/[&/\]/\\&/g')

        if grep -q "AQ_DRM_DEVICES" "$ENV_HYPR_FILE"; then
            # Replace existing line
            sed -i "s|^#*[[:space:]]*export AQ_DRM_DEVICES=.*|export AQ_DRM_DEVICES=${card_esc}|" "$ENV_HYPR_FILE"
        else
            # Append if missing
            echo "export AQ_DRM_DEVICES=$SELECTED_CARD" >> "$ENV_HYPR_FILE"
        fi
        printf "     Set AQ_DRM_DEVICES to %s%s%s\n" "${BOLD}" "$SELECTED_CARD" "${RESET}"
    else
        log_warn "No specific card path derived. AQ_DRM_DEVICES untouched."
    fi
}

show_success() {
    printf "\n%s[SUCCESS] Configuration Complete.%s\n" "${GREEN}${BOLD}" "${RESET}"
    printf "UWSM Environment set for: %s%s%s\n" "${BOLD}" "${SELECTED_VENDOR^^}" "${RESET}"
    if [[ -n "$SELECTED_CARD" ]]; then
        printf "Hyprland Bind:            %s%s%s\n" "${BOLD}" "$SELECTED_CARD" "${RESET}"
    fi
    printf "Please restart UWSM/Hyprland for changes to take effect.\n"
}

# --- 8. EXECUTION ---
main() {
    preflight_checks
    detect_gpus
    select_gpu
    apply_config
    show_success
}

main "$@"
exit 0
