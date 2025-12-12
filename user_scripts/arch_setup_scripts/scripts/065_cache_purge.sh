#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX CACHE PURGE & OPTIMIZER
# ==============================================================================
#  Description: Aggressively cleans Pacman and Paru caches to reclaim disk space.
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
    if ! command -v paru &>/dev/null; then
        echo -e "${Y}Warning: Paru not found. Skipping AUR cleanup.${RESET}"
    fi

    # --- Step 2: Measure Initial Size ---
    log "Measuring current cache usage..."
    
    local pacman_start
    local paru_start
    
    pacman_start=$(get_dir_size_mb "$PACMAN_CACHE")
    paru_start=$(get_dir_size_mb "$PARU_CACHE")
    
    local total_start=$((pacman_start + paru_start))
    
    echo -e "   ${BOLD}Pacman Cache:${RESET} ${pacman_start} MB"
    echo -e "   ${BOLD}Paru Cache:${RESET}   ${paru_start} MB"
    sleep 0.5

    # --- Step 3: Clean Pacman (Requires Root) ---
    log "Purging Pacman cache (System)..."
    
    # We pipe 'yes' to answer "y" to:
    # 1. Remove ALL files from cache?
    # 2. Remove unused repositories?
    if sudo -v; then
        # 'yes' outputs 'y' repeatedly until pipe closes
        yes | sudo pacman -Scc > /dev/null 2>&1 || true
        echo -e "   ${G}✔ Pacman cache cleared.${RESET}"
    else
        echo -e "   ${R}✘ Sudo authentication failed. Skipping Pacman.${RESET}"
    fi
    sleep 0.5

    # --- Step 4: Clean Paru (User Level) ---
    if command -v paru &>/dev/null; then
        log "Purging Paru cache (AUR)..."
        
        # Paru asks 4 questions usually (pkg, repos, clones, diffs)
        # We pipe 'yes' to ensure deep clean
        yes | paru -Scc > /dev/null 2>&1 || true
        echo -e "   ${G}✔ Paru cache cleared.${RESET}"
        sleep 0.5
    fi

    # --- Step 5: Measure Final Size ---
    log "Calculating reclaimed space..."
    
    local pacman_end
    local paru_end
    
    pacman_end=$(get_dir_size_mb "$PACMAN_CACHE")
    paru_end=$(get_dir_size_mb "$PARU_CACHE")
    
    local total_end=$((pacman_end + paru_end))
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
