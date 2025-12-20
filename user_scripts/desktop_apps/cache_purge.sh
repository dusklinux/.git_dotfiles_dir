#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX CACHE PURGE & OPTIMIZER
# ==============================================================================
#  Description: Aggressively cleans Pacman, Paru, and Yay caches to reclaim space.
#               Includes fixes for stuck 'download-*' directories.
#               Calculates and displays total space saved in MB.
#  Mode:        USER (U) - Handles sudo internally for Pacman.
# ==============================================================================

# --- 1. Safety & Environment ---
set -o errexit   # Exit on error
set -o nounset   # Exit on unset variables
set -o pipefail  # Exit if pipe fails

# --- 2. Visuals (ANSI with $'') ---
readonly R=$'\e[31m'
readonly G=$'\e[32m'
readonly Y=$'\e[33m'
readonly B=$'\e[34m'
readonly RESET=$'\e[0m'
readonly BOLD=$'\e[1m'

# --- 3. Targets ---
# We track these directories to calculate space saved
readonly PACMAN_CACHE="/var/cache/pacman/pkg"
readonly PARU_CACHE="${HOME}/.cache/paru"
readonly YAY_CACHE="${HOME}/.cache/yay"

# --- 4. Helper Functions ---

log() {
    printf "%s%s%s %s\n" "${B}" "::" "${RESET}" "$1"
    sleep 0.5
}

get_dir_size_mb() {
    local target="$1"
    # If directory doesn't exist, size is 0
    if [[ ! -d "$target" ]]; then
        echo "0"
        return
    fi
    
    # usage: du -sm (summarize, megabytes)
    # handling sudo if not owned by user
    if [[ -w "$target" ]]; then
        du -sm "$target" 2>/dev/null | cut -f1
    else
        sudo du -sm "$target" 2>/dev/null | cut -f1
    fi
}

# --- 5. Main Execution ---

main() {
    echo -e "${BOLD}Starting Aggressive Cache Cleanup...${RESET}"
    sleep 0.5

    # --- Step 1: Pre-Flight Check ---
    local has_paru=false
    local has_yay=false

    if command -v paru &>/dev/null; then has_paru=true; fi
    if command -v yay &>/dev/null; then has_yay=true; fi

    if [[ "$has_paru" == "false" && "$has_yay" == "false" ]]; then
        echo -e "${Y}Warning: No AUR helpers (yay/paru) detected. Cleaning Pacman only.${RESET}"
    fi

    # --- Step 2: Measure Initial Size ---
    log "Measuring current cache usage..."
    
    local pacman_start
    local paru_start=0
    local yay_start=0
    
    pacman_start=$(get_dir_size_mb "$PACMAN_CACHE")
    echo -e "   ${BOLD}Pacman Cache:${RESET} ${pacman_start} MB"

    if [[ "$has_paru" == "true" ]]; then
        paru_start=$(get_dir_size_mb "$PARU_CACHE")
        echo -e "   ${BOLD}Paru Cache:${RESET}   ${paru_start} MB"
    fi

    if [[ "$has_yay" == "true" ]]; then
        yay_start=$(get_dir_size_mb "$YAY_CACHE")
        echo -e "   ${BOLD}Yay Cache:${RESET}    ${yay_start} MB"
    fi
    
    local total_start=$((pacman_start + paru_start + yay_start))
    sleep 0.5

    # --- Step 3: Clean Pacman (System Level) ---
    log "Purging Pacman cache (System)..."
    
    if sudo -v; then
        # === FIX: Remove stuck download directories before pacman sees them ===
        # Finds directories named 'download-*' inside pkg cache and nukes them.
        # This prevents "Is a directory" errors during -Scc.
        if [[ -d "$PACMAN_CACHE" ]]; then
            # 'find' is safer than shell expansion here
            if sudo find "$PACMAN_CACHE" -maxdepth 1 -type d -name "download-*" -print -quit | grep -q .; then
                 echo -e "   ${Y}Found stuck download directories. Removing...${RESET}"
                 sudo find "$PACMAN_CACHE" -maxdepth 1 -type d -name "download-*" -exec rm -rf {} +
            fi
        fi

        # Standard Pacman Clean
        # We pipe 'yes' to answer "y" to:
        # 1. Remove ALL files from cache?
        # 2. Remove unused repositories?
        yes | sudo pacman -Scc > /dev/null 2>&1 || true
        echo -e "   ${G}✔ Pacman cache cleared.${RESET}"
    else
        echo -e "   ${R}✘ Sudo authentication failed. Skipping Pacman.${RESET}"
    fi
    sleep 0.5

    # --- Step 4: Clean AUR Helpers (User Level) ---
    
    # Clean Paru
    if [[ "$has_paru" == "true" ]]; then
        log "Purging Paru cache (AUR)..."
        # Paru cleanup
        yes | paru -Scc > /dev/null 2>&1 || true
        echo -e "   ${G}✔ Paru cache cleared.${RESET}"
    fi

    # Clean Yay
    if [[ "$has_yay" == "true" ]]; then
        log "Purging Yay cache (AUR)..."
        # Yay cleanup. 
        # Note: yay -Scc might ask to clean system cache too, but since we
        # ran pacman -Scc already, it's fine. We suppress output anyway.
        yes | yay -Scc > /dev/null 2>&1 || true
        echo -e "   ${G}✔ Yay cache cleared.${RESET}"
    fi

    sleep 0.5

    # --- Step 5: Measure Final Size ---
    log "Calculating reclaimed space..."
    
    local pacman_end
    local paru_end=0
    local yay_end=0
    
    pacman_end=$(get_dir_size_mb "$PACMAN_CACHE")
    if [[ "$has_paru" == "true" ]]; then paru_end=$(get_dir_size_mb "$PARU_CACHE"); fi
    if [[ "$has_yay" == "true" ]]; then yay_end=$(get_dir_size_mb "$YAY_CACHE"); fi
    
    local total_end=$((pacman_end + paru_end + yay_end))
    local saved=$((total_start - total_end))

    # --- Step 6: Final Report ---
    echo ""
    echo -e "${BOLD}========================================${RESET}"
    echo -e "${BOLD}       DISK SPACE RECLAIMED REPORT      ${RESET}"
    echo -e "${BOLD}========================================${RESET}"
    printf "${BOLD}Initial Usage:${RESET} %s MB\n" "$total_start"
    printf "${BOLD}Final Usage:${RESET}   %s MB\n" "$total_end"
    echo -e "${BOLD}----------------------------------------${RESET}"
    
    if [[ $saved -gt 0 ]]; then
        printf "${G}${BOLD}TOTAL CLEARED:${RESET} ${G}%s MB${RESET}\n" "$saved"
    else
        printf "${Y}${BOLD}TOTAL CLEARED:${RESET} ${Y}0 MB (Already Clean)${RESET}\n"
    fi
    echo -e "${BOLD}========================================${RESET}"
}

# Run
main
