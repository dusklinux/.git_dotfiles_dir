#!/usr/bin/env bash
# ==============================================================================
#  ARCH CHROOT ORCHESTRATOR (MANUAL SEQUENCE)
#  Context: Run INSIDE 'arch-chroot /mnt'
#  Instructions: Edit 'INSTALL_SEQUENCE' to define your order.
# ==============================================================================

# --- 1. CONFIGURATION: EDIT THIS LIST ---
# The script will look for these files in the SAME directory as this master script.
INSTALL_SEQUENCE=(
    "002_etc_skel_gitdeploy.sh"
    "003_post_chroot.sh"
    "004_chroot_package_installer.sh"
    "005_mkinitcpio_generation.sh"
    "006_systemd_bootloader.sh"
    "006_grub.sh"
    "007_zram_config.sh"
    "008_services.sh"
    "009_exiting_unmounting.sh"
)

# --- 2. SETUP & SAFETY ---
set -o errexit   # Exit on error
set -o nounset   # Abort on unbound variable
set -o pipefail  # Catch pipe errors

# FORCE SCRIPT TO RUN IN ITS OWN DIRECTORY
# This ensures it finds the subscripts listed above.
cd "$(dirname "$(readlink -f "$0")")"

# --- 3. VISUALS ---
if [[ -t 1 ]]; then
    readonly R=$'\e[31m' G=$'\e[32m' B=$'\e[34m' Y=$'\e[33m' HL=$'\e[1m' RS=$'\e[0m'
else
    readonly R="" G="" B="" Y="" HL="" RS=""
fi

log() {
    local type="$1"
    local msg="$2"
    case "$type" in
        INFO) printf "${B}[INFO]${RS}  %s\n" "$msg" ;;
        OK)   printf "${G}[OK]${RS}    %s\n" "$msg" ;;
        WARN) printf "${Y}[WARN]${RS}  %s\n" "$msg" ;;
        ERR)  printf "${R}[ERR]${RS}   %s\n" "$msg" ;;
        *)    printf "%s\n" "$msg" ;;
    esac
}

# --- 4. ROOT CHECK ---
if (( EUID != 0 )); then
    log ERR "This script must be run as root (inside chroot)."
    exit 1
fi

# --- 5. EXECUTION ENGINE ---
execute_script() {
    local script_name="$1"

    if [[ ! -f "$script_name" ]]; then
        log ERR "File not found: $script_name"
        echo -e "${Y}Action Required:${RS}"
        read -r -p "Script missing. [S]kip or [A]bort? (s/a): " missing_choice
        if [[ "${missing_choice,,}" == "s" ]]; then return 0; else exit 1; fi
    fi

    # Retry Loop
    while true; do
        log INFO "Executing: ${HL}$script_name${RS}"
        
        chmod +x "$script_name"

        set +e
        bash "$script_name"
        local exit_code=$?
        set -e

        if (( exit_code == 0 )); then
            log OK "Finished: $script_name"
            return 0
        else
            log ERR "Failed: $script_name (Exit Code: $exit_code)"
            
            echo -e "${Y}>>> EXECUTION FAILED <<<${RS}"
            read -r -p "[R]etry, [S]kip, or [A]bort? (r/s/a): " action
            case "${action,,}" in
                r|retry) continue ;;
                s|skip)  log WARN "Skipping $script_name."; return 0 ;;
                *)       log ERR "Aborting."; exit "$exit_code" ;;
            esac
        fi
    done
}

main() {
    echo -e "\n${B}${HL}=== ARCH CHROOT ORCHESTRATOR ===${RS}\n"
    log INFO "Working Directory: $(pwd)"
    
    for script in "${INSTALL_SEQUENCE[@]}"; do
        execute_script "$script"
    done

    echo -e "\n${G}${HL}=== ORCHESTRATION COMPLETE ===${RS}"
}

main
