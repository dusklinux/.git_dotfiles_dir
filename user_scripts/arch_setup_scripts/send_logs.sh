#!/usr/bin/env bash
# ==============================================================================
#  ARCH DOTFILES LOG SUBMITTER (FINAL ARCHITECT EDITION)
#  - Robust Error Handling
#  - Secure Temp Files
#  - Hardware + Wayland Environment Reporting
# ==============================================================================

# 1. Strict Safety Settings
set -o errexit   # Exit on error
set -o nounset   # Exit on undeclared variables
set -o pipefail  # Exit if any command in a pipe fails
# Ensure subshells inherit error settings (Bash 4.4+)
shopt -s inherit_errexit 2>/dev/null || true

# --- CONFIGURATION ---
readonly LOG_SOURCE="${HOME:?HOME is not set}/Documents/logs"
readonly UPLOAD_URL="https://0x0.st"

# Runtime variables
TEMP_DIR=""
ARCHIVE_FILE=""

# --- COLORS (Smart TTY Check) ---
RED="" GREEN="" YELLOW="" BLUE="" BOLD="" RESET=""
if [[ -t 1 && -t 2 ]] && command -v tput &>/dev/null; then
    RED=$(tput setaf 1 2>/dev/null) || true
    GREEN=$(tput setaf 2 2>/dev/null) || true
    YELLOW=$(tput setaf 3 2>/dev/null) || true
    BLUE=$(tput setaf 4 2>/dev/null) || true
    BOLD=$(tput bold 2>/dev/null) || true
    RESET=$(tput sgr0 2>/dev/null) || true
fi

# --- UTILITIES ---
log() {
    printf '%s[%s]%s %s\n' "$BLUE" "${1:-INFO}" "$RESET" "${2:-}"
}

die() {
    printf '%sERROR: %s%s\n' "$RED" "${1:-Unknown error}" "$RESET" >&2
    exit 1
}

cleanup() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# --- DEPENDENCY MANAGEMENT ---
check_and_install_deps() {
    local -a deps=("curl" "wl-clipboard" "pciutils")
    local -a to_install=()

    for pkg in "${deps[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if (( ${#to_install[@]} > 0 )); then
        printf '%sInstalling missing dependencies: %s%s\n' "$YELLOW" "${to_install[*]}" "$RESET"
        sudo pacman -S --needed --noconfirm "${to_install[@]}" \
            || die "Failed to install dependencies."
    fi
}

# --- REPORT GENERATOR ---
generate_system_report() {
    log "INFO" "Generating hardware and environment report..."
    
    mkdir -p -- "$LOG_SOURCE" || die "Cannot create log directory"
    local report_file="${LOG_SOURCE}/000_system_hardware_report.txt"

    {
        printf '========================================================\n'
        printf '  DEBUG REPORT: %s\n' "$(date)"
        printf '========================================================\n'
        
        printf '\n[KERNEL]\n'
        uname -sr 2>/dev/null || printf 'N/A\n'

        printf '\n[DISTRO]\n'
        grep -E '^(PRETTY_NAME|ID|BUILD_ID)=' /etc/os-release 2>/dev/null || printf 'N/A\n'

        printf '\n[CPU]\n'
        lscpu 2>/dev/null | grep -E 'Model name|Architecture|Socket|Core|Thread' || printf 'N/A\n'

        printf '\n[GPU]\n'
        lspci -k 2>/dev/null | grep -A2 -E '(VGA|3D)' || printf 'N/A\n'

        printf '\n[RAM]\n'
        free -h 2>/dev/null || printf 'N/A\n'

        printf '\n[STORAGE]\n'
        lsblk -f 2>/dev/null | grep -v loop || printf 'N/A\n'
        printf -- '---\n'
        df -h / /home 2>/dev/null || df -h / 2>/dev/null || printf 'N/A\n'

        if command -v hyprctl &>/dev/null; then
            printf '\n[HYPRLAND]\n'
            hyprctl version 2>/dev/null | head -n1 || printf 'N/A\n'
        fi

        # --- NEW: WAYLAND ENVIRONMENT SECTION ---
        printf '\n[WAYLAND ENVIRONMENT]\n'
        env | grep -E 'WAYLAND|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|QT_QPA_PLATFORM|GBM_BACKEND|LIBVA_DRIVER_NAME|__GLX_VENDOR_LIBRARY_NAME' || printf 'N/A\n'

    } > "$report_file" || die "Cannot write report to disk"
}

# --- PAYLOAD ENGINE ---
prepare_payload() {
    log "PROCESS" "Staging logs from $LOG_SOURCE..."
    
    TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles_debug.XXXXXX") \
        || die "Cannot create temporary directory"
    ARCHIVE_FILE="${TEMP_DIR}/debug_logs.tar.gz"
    
    [[ -d "$LOG_SOURCE" ]] || die "Log directory missing: $LOG_SOURCE"
    
    local -a files
    shopt -s nullglob
    files=("$LOG_SOURCE"/*)
    shopt -u nullglob
    
    (( ${#files[@]} > 0 )) || die "No logs found in $LOG_SOURCE"
    
    local staging="${TEMP_DIR}/logs"
    mkdir -p -- "$staging"
    cp -r -- "$LOG_SOURCE"/. "$staging/" || die "Failed to stage logs"

    log "PACK" "Compressing archive..."
    tar -czf "$ARCHIVE_FILE" -C "$TEMP_DIR" logs || die "Compression failed"
}

# --- HELP ---
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -a, --auto    Skip confirmation prompt
    -h, --help    Show this help message

Collects logs from ~/Documents/logs, generates a hardware/env report,
and uploads to 0x0.st for sharing in GitHub issues.
EOF
}

# --- MAIN ---
main() {
    local auto_mode=0

    while (( $# > 0 )); do
        case "$1" in
            -a|--auto)   auto_mode=1 ;;
            -h|--help)   show_help; exit 0 ;;
            --)          shift; break ;;
            -*)          die "Unknown option: $1" ;;
            *)           die "Unexpected argument: $1" ;;
        esac
        shift
    done

    check_and_install_deps
    generate_system_report
    prepare_payload
    
    local file_size
    file_size=$(du -h "$ARCHIVE_FILE" | cut -f1)
    
    if (( auto_mode == 0 )); then
        printf '\n%s--- PAYLOAD READY ---%s\n' "$YELLOW" "$RESET"
        printf 'File:    %s\n' "$ARCHIVE_FILE"
        printf 'Size:    %s\n' "$file_size"
        printf 'Content: Logs + Hardware/Env Report\n'
        printf '%s---------------------%s\n' "$YELLOW" "$RESET"
        
        read -rp "Upload to 0x0.st? [y/N]: " choice
        [[ "${choice,,}" == "y" ]] || { log "INFO" "Aborted."; exit 0; }
    fi

    log "UPLOAD" "Uploading..."
    
    local response url
    if ! response=$(curl -sS --fail --connect-timeout 30 --max-time 120 \
            -F "file=@${ARCHIVE_FILE}" "$UPLOAD_URL" 2>&1); then
        die "Upload failed: ${response:-Connection error}"
    fi
    
    read -r url <<< "$response"
    
    [[ "$url" == http* ]] || die "Invalid server response: $response"
    
    local clip_msg=""
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy &>/dev/null; then
        printf '%s' "$url" | wl-copy 2>/dev/null && clip_msg=" (Copied to clipboard)"
    fi

    printf '\n%s======================================================%s\n' "$GREEN" "$RESET"
    printf ' %sSUCCESS!%s%s\n' "$BOLD" "$RESET" "$clip_msg"
    printf ' URL: %s%s%s%s\n' "$BLUE" "$BOLD" "$url" "$RESET"
    printf '\n Paste the link into your gitHub issue or in the discord server.\n'
    printf '%s======================================================%s\n' "$GREEN" "$RESET"
}

main "$@"
