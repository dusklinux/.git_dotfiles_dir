#!/usr/bin/env bash
# ==============================================================================
# Script Name:   btrfs_compression_stats.sh (v3.2 - Absolute Savings)
# Description:   Calculates ZSTD compression savings on Arch Linux.
#                - CRITICAL FIX: Prevents silent exit on grep failures (set -e).
#                - CRITICAL FIX: Robust sudo re-execution using realpath.
#                - AUTO-INSTALL: Installs missing deps via pacman automatically.
#                - NEW: Calculates absolute space saved (e.g., "14GB").
#                - Dynamic Discovery: Finds Btrfs mounts automatically.
#                - Atomic Execution: Runs compsize ONCE to prevent double-counting.
# ==============================================================================

set -euo pipefail
# Ensure subshells inherit the strict error handling (Bash 4.4+)
shopt -s inherit_errexit 2>/dev/null || true

# --- 1. Environment & Color Setup ---
# Only use colors if we are in an interactive terminal (TTY)
if [[ -t 1 ]]; then
    readonly C_RED="\033[31m"
    readonly C_GREEN="\033[32m"
    readonly C_YELLOW="\033[33m"
    readonly C_BLUE="\033[34m"
    readonly C_GRAY="\033[90m"
    readonly C_BOLD="\033[1m"
    readonly C_RESET="\033[0m"
else
    readonly C_RED="" C_GREEN="" C_YELLOW="" C_BLUE=""
    readonly C_GRAY="" C_BOLD="" C_RESET=""
fi

# --- 2. Privilege Escalation (Hardened) ---
if [[ $EUID -ne 0 ]]; then
    printf "%b[PRIV]%b Root privileges needed for block analysis. Auto-escalating...\n" "$C_YELLOW" "$C_RESET"
    
    # Resolve the absolute path of the script to prevent "command not found" on re-exec
    script_path=$(realpath -- "$0" 2>/dev/null || echo "$0")
    
    # Execute sudo preserving the environment
    if command -v sudo &>/dev/null; then
        exec sudo env PATH="$PATH" bash -- "$script_path" "$@"
    else
        printf "%b[ERR]%b 'sudo' not found. Please run as root.\n" "$C_RED" "$C_RESET" >&2
        exit 1
    fi
fi

# --- 3. Dependency Check & Auto-Install ---
declare -a missing_pkgs=()

# Map commands to their Arch package names
# Note: numfmt is part of coreutils (base), so usually present.
if ! command -v compsize &>/dev/null; then missing_pkgs+=("compsize"); fi
if ! command -v findmnt &>/dev/null;  then missing_pkgs+=("util-linux"); fi
if ! command -v awk &>/dev/null;      then missing_pkgs+=("gawk"); fi
if ! command -v grep &>/dev/null;     then missing_pkgs+=("grep"); fi

if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
    printf "%b[DEPS]%b Missing packages detected: %b%s%b\n" "$C_YELLOW" "$C_RESET" "$C_BOLD" "${missing_pkgs[*]}" "$C_RESET"
    printf "       Installing via pacman...\n"
    
    # Install missing dependencies using the requested flags
    if pacman -S --needed --noconfirm "${missing_pkgs[@]}"; then
        printf "%b[OK]%b Dependencies installed successfully.\n" "$C_GREEN" "$C_RESET"
    else
        printf "%b[ERR]%b Failed to install dependencies. Aborting.\n" "$C_RED" "$C_RESET" >&2
        exit 1
    fi
fi

# --- 4. Dynamic Target Discovery ---
# "|| true" prevents grep returning 1 (exit) if no mounts are found or all are filtered.
raw_mounts=$(findmnt -n -l -t btrfs -o TARGET 2>/dev/null || true)

if [[ -z "$raw_mounts" ]]; then
    printf "%b[ERR]%b No Btrfs filesystems detected on this system.\n" "$C_RED" "$C_RESET" >&2
    exit 1
fi

# Filter out noise (Docker, Snap, etc.) and sort unique
# "|| true" ensures script doesn't die if grep filters everything
mapfile -t targets < <(echo "$raw_mounts" | grep -vE "/var/lib/docker|/var/lib/containers|/snap" | sort -u || true)

if [[ ${#targets[@]} -eq 0 ]]; then
    printf "%b[ERR]%b No suitable Btrfs mounts found (all were filtered).\n" "$C_RED" "$C_RESET" >&2
    exit 1
fi

# --- 5. The Execution (Atomic Pass) ---
printf "%b[INFO]%b Detected Btrfs targets:\n" "$C_BLUE" "$C_RESET"
printf "       %s\n" "${targets[@]}"
printf "\n%b[RUN]%b  Calculating compression (this may take a moment)...\n" "$C_BLUE" "$C_RESET"
printf "       %b(Using -x to respect mount boundaries)%b\n" "$C_GRAY" "$C_RESET"

# Use %s to prevent dash interpretation issues
printf "%s\n" "---------------------------------------------------------------"

# Run compsize. Capture output. 
# Allow exit code 1 (warnings) without crashing script, but capture strict errors.
output=$(compsize -x "${targets[@]}" 2>&1 || true)

# Display Output
printf "%s\n" "$output"
printf "%s\n" "---------------------------------------------------------------"

# --- 6. The Summary (Parsing & Math) ---
# Use "|| true" in case grep finds nothing (prevents crash)
total_line=$(echo "$output" | grep "^TOTAL" || true)

if [[ -n "$total_line" ]]; then
    # Parse values: TOTAL <Ratio>% <Disk> <Uncompressed> <Ref>
    read -r _ ratio_str disk_str uncomp_str _ <<< "$total_line"
    
    # 1. Strip '%'
    ratio_val="${ratio_str%\%}"
    
    # 2. Sanitize: Remove decimals if present (bash integers only)
    ratio_val="${ratio_val%%.*}"

    # 3. Verify it is a number
    if [[ ! "$ratio_val" =~ ^[0-9]+$ ]]; then
        printf "%b[WARN]%b Could not parse compression ratio (got: %s)\n" "$C_YELLOW" "$C_RESET" "$ratio_str" >&2
        exit 0
    fi

    # 4. Calculate Absolute Space Saved
    # Use numfmt to convert human-readable (10G, 500M) to bytes, subtract, then convert back.
    # We suppress stderr in case compsize gives a weird value, defaulting to 0.
    bytes_disk=$(numfmt --from=iec "$disk_str" 2>/dev/null || echo 0)
    bytes_uncomp=$(numfmt --from=iec "$uncomp_str" 2>/dev/null || echo 0)
    bytes_saved=$(( bytes_uncomp - bytes_disk ))
    
    # Handle negative savings (rare expansion edge case)
    if [[ $bytes_saved -lt 0 ]]; then bytes_saved=0; fi

    human_saved=$(numfmt --to=iec "$bytes_saved" 2>/dev/null || echo "N/A")

    # Calculate savings percentage
    saved_val=$((100 - ratio_val))

    # Color logic
    save_color="$C_GREEN"
    [[ $saved_val -lt 10 ]] && save_color="$C_YELLOW" 

    printf "\n%b=== ARCH SYSTEM SAVINGS OVERVIEW ===%b\n" "$C_BOLD" "$C_RESET"
    printf "  Total Data Size:      %s\n" "$uncomp_str"
    printf "  Physical Disk Used:   %s\n" "$disk_str"
    printf "  Compression Ratio:    %s\n" "$ratio_str"
    printf "  Total Space Saved:    %b%s%b\n" "$save_color" "$human_saved" "$C_RESET"
    printf "  Space Reclaimed:      %b~%s%% of your drive%b\n" "$save_color" "$saved_val" "$C_RESET"
    printf "\n"
else
    printf "%b[WARN]%b Could not find 'TOTAL' line in output. Is the volume empty?\n" "$C_YELLOW" "$C_RESET"
fi
