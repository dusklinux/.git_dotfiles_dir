#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: configure_skel.sh
# Description: Stages dotfiles into /etc/skel with smart permissions.
# Context: Arch Linux ISO (Chroot Environment)
# -----------------------------------------------------------------------------

# =============================================================================
# STRICT MODE & SETTINGS
# =============================================================================
set -euo pipefail
# inherit_errexit: Ensures subshells inherit -e
# nullglob: glob patterns that match nothing expand to nothing
shopt -s inherit_errexit nullglob 2>/dev/null || true

# =============================================================================
# VISUALS & LOGGING
# =============================================================================
# Only use colors if connected to a terminal
if [[ -t 1 ]]; then
    declare -r BLUE=$'\033[0;34m'
    declare -r GREEN=$'\033[0;32m'
    declare -r RED=$'\033[0;31m'
    declare -r YELLOW=$'\033[0;33m'
    declare -r BOLD=$'\033[1m'
    declare -r NC=$'\033[0m'
else
    declare -r BLUE="" GREEN="" RED="" YELLOW="" BOLD="" NC=""
fi

log_info()    { printf "%s[INFO]%s %s\n" "$BLUE" "$NC" "$*"; }
log_warn()    { printf "%s[WARN]%s %s\n" "$YELLOW" "$NC" "$*" >&2; }
log_success() { printf "%s[SUCCESS]%s %s\n" "$GREEN" "$NC" "$*"; }
log_error()   { printf "%s[ERROR]%s %s\n" "$RED" "$NC" "$*" >&2; }
die()         { log_error "$*"; exit 1; }

# =============================================================================
# CONFIGURATION
# =============================================================================
# Format: "SOURCE :: DESTINATION"
# Note: Destinations must be explicit filenames or full directory paths.
#       The script uses 'cp -T' so it will NOT auto-nest directories.

declare -a COPY_TASKS=(
    # 0. User Scripts Directory (Directory contents)
    # "dusky/user_scripts/ :: /etc/skel/Documents/user_scripts"

    # 1. Deployment Script (Script -> Executable)
    "deploy_dotfiles.sh :: /etc/skel/deploy_dotfiles.sh"

    # 2. Zsh Config (Config -> Not Executable)
    "dusky/.zshrc :: /etc/skel/.zshrc"

    # 3. Network Manager Script (New Addition)
    "dusky/user_scripts/network_manager/nmcli_wifi_no_gum.sh :: /etc/skel/wifi_connect.sh"
)

# Files matching these patterns will be forced to be executable (755)
declare -a EXEC_PATTERNS=("*.sh" "*.bash" "*.pl" "*.py" "deploy_*")

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

check_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        die "This script must be run as root to modify /etc/skel."
    fi
}

preflight_confirmation() {
    printf "\n%s[CRITICAL CHECK]%s Verify Environment:\n" "$RED" "$NC"
    printf "Have you switched to the chroot environment by running: %sarch-chroot /mnt%s ?\n" "$BLUE" "$NC"
    
    local user_conf
    read -r -p "Type 'yes' to proceed, or anything else to exit: " user_conf

    if [[ "${user_conf,,}" != "yes" ]]; then
        printf "\n%s[ABORTING]%s You must be inside the chroot environment.\n" "$RED" "$NC"
        printf "Please run:\n    %sarch-chroot /mnt%s\n\n" "$BLUE" "$NC"
        exit 1
    fi
}

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

# Trims whitespace from start/end of a string
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}" # trim leading
    s="${s%"${s##*[![:space:]]}"}" # trim trailing
    printf '%s' "$s"
}

# Applies 755 to dirs/scripts, 644 to files
smart_permissions() {
    local target="$1"
    
    # 1. Set Ownership to root
    chown -R root:root -- "$target"

    if [[ -d "$target" ]]; then
        # It's a directory
        # Set all directories to 755 (rwx-rx-rx)
        find "$target" -type d -exec chmod 755 {} +
        # Set all files to 644 (rw-r--r--) initially
        find "$target" -type f -exec chmod 644 {} +
        
        # Make specific patterns executable
        for pat in "${EXEC_PATTERNS[@]}"; do
            find "$target" -type f -name "$pat" -exec chmod 755 {} + 2>/dev/null || true
        done
    else
        # It's a file
        local basename="${target##*/}"
        local is_exec=0
        
        # Check against patterns
        for pat in "${EXEC_PATTERNS[@]}"; do
            # shellcheck disable=SC2053
            if [[ "$basename" == $pat ]]; then
                is_exec=1
                break
            fi
        done

        if [[ $is_exec -eq 1 ]]; then
            chmod 755 -- "$target"
        else
            chmod 644 -- "$target"
        fi
    fi
}

deploy_item() {
    local source_path="$1"
    local dest_path="$2"

    # Safety: Ensure destination is actually inside /etc/skel or /root (optional)
    # This prevents accidents like writing to /etc/passwd if config is wrong
    if [[ "$dest_path" != /etc/skel* ]]; then
        log_warn "Destination '$dest_path' is not inside /etc/skel. Skipping for safety."
        return
    fi

    if [[ ! -e "$source_path" ]]; then
        log_warn "Source not found: $source_path"
        return
    fi

    # Create parent dir
    local dest_parent
    dest_parent=$(dirname "$dest_path")
    if [[ ! -d "$dest_parent" ]]; then
        mkdir -p -- "$dest_parent"
    fi

    log_info "Copying: $source_path -> $dest_path"

    # cp flags:
    # -r: recursive
    # -f: force
    # -P: no-dereference (preserve symlinks as links)
    # -T: no-target-directory (treat dest as a file/exact dir, not a container)
    cp -rfPT -- "$source_path" "$dest_path"

    # Apply smart permissions
    smart_permissions "$dest_path"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    check_root
    preflight_confirmation

    # Ensure skel exists
    if [[ ! -d "/etc/skel" ]]; then
        mkdir -p /etc/skel
    fi

    log_info "Starting Skeleton Configuration..."

    for task in "${COPY_TASKS[@]}"; do
        # 1. Split string by delimiter
        local src="${task%% :: *}"
        local dest="${task##* :: }"

        # 2. Trim whitespace
        src=$(trim "$src")
        dest=$(trim "$dest")

        # 3. Run
        if [[ -n "$src" && -n "$dest" ]]; then
            deploy_item "$src" "$dest"
        fi
    done

    log_success "Skeleton configuration complete."
}

main "$@"
