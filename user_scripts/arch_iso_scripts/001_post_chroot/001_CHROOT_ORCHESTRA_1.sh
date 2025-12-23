#!/usr/bin/env bash
# ==============================================================================
#  ARCH CHROOT ORCHESTRATOR (UPDATED)
#  Context: Run INSIDE 'arch-chroot /mnt'
#  Instructions: Edit 'INSTALL_SEQUENCE' to define your order.
# ==============================================================================

# --- 1. CONFIGURATION: EDIT THIS LIST ---
# The script will look for these files in the SAME directory as this master script.
declare -ra INSTALL_SEQUENCE=(
    "002_etc_skel.sh"
    "003_post_chroot.sh"
    "004_mkintcpip_optimizer.sh"
    "005_chroot_package_installer.sh"
    "006_mkinitcpio_generation.sh"
    "007_systemd_bootloader.sh"
    "008_grub.sh"
    "009_zram_config.sh"
    "010_services.sh"
    "011_exiting_unmounting.sh"
)

# --- 2. SETUP & SAFETY ---
set -o errexit   # Exit on error
set -o nounset   # Abort on unbound variable
set -o pipefail  # Catch pipe errors
set -o errtrace  # Inherited ERR traps

# FORCE SCRIPT TO RUN IN ITS OWN DIRECTORY
cd "$(dirname "$(readlink -f "$0")")"

# --- 3. STATE TRACKING ---
declare -a EXECUTED_SCRIPTS=()
declare -a SKIPPED_SCRIPTS=()
declare -a FAILED_SCRIPTS=()

# --- 4. VISUALS ---
if [[ -t 1 ]]; then
    readonly R=$'\e[31m' G=$'\e[32m' B=$'\e[34m' Y=$'\e[33m' HL=$'\e[1m' RS=$'\e[0m'
else
    readonly R="" G="" B="" Y="" HL="" RS=""
fi

log() {
    local type="$1"
    local msg="$2"
    case "$type" in
        INFO) printf "%s[INFO]%s  %s\n" "$B" "$RS" "$msg" ;;
        OK)   printf "%s[OK]%s    %s\n" "$G" "$RS" "$msg" ;;
        WARN) printf "%s[WARN]%s  %s\n" "$Y" "$RS" "$msg" >&2 ;;
        ERR)  printf "%s[ERR]%s   %s\n" "$R" "$RS" "$msg" >&2 ;;
        *)    printf "%s\n" "$msg" ;;
    esac
}

# --- 5. SUMMARY FUNCTION ---
print_summary() {
    printf "\n%s%s=== EXECUTION SUMMARY ===%s\n" "$B" "$HL" "$RS"
    
    if (( ${#EXECUTED_SCRIPTS[@]} > 0 )); then
        printf "%s[Executed]%s %d script(s)\n" "$G" "$RS" "${#EXECUTED_SCRIPTS[@]}"
    fi
    
    if (( ${#SKIPPED_SCRIPTS[@]} > 0 )); then
        printf "%s[Skipped]%s  %d script(s):" "$Y" "$RS" "${#SKIPPED_SCRIPTS[@]}"
        for s in "${SKIPPED_SCRIPTS[@]}"; do printf " %s" "$s"; done
        printf "\n"
    fi
    
    if (( ${#FAILED_SCRIPTS[@]} > 0 )); then
        printf "%s[Failed]%s   %d script(s):" "$R" "$RS" "${#FAILED_SCRIPTS[@]}"
        for s in "${FAILED_SCRIPTS[@]}"; do printf " %s" "$s"; done
        printf "\n"
    fi
}

# --- 6. ROOT CHECK ---
if (( EUID != 0 )); then
    log ERR "This script must be run as root (inside chroot)."
    exit 1
fi

# --- 7. EXECUTION ENGINE ---
execute_script() {
    local script_name="$1"

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
            EXECUTED_SCRIPTS+=("$script_name")
            # PAUSE FOR 1 SECOND as requested
            sleep 1
            return 0
        else
            log ERR "Failed: $script_name (Exit Code: $exit_code)"
            FAILED_SCRIPTS+=("$script_name")
            
            printf "%s>>> EXECUTION FAILED <<<%s\n" "$Y" "$RS"
            read -r -p "[R]etry, [S]kip, or [A]bort? (r/s/a): " action
            case "${action,,}" in
                r|retry)
                    unset 'FAILED_SCRIPTS[-1]'
                    continue
                    ;;
                s|skip)
                    log WARN "Skipping $script_name."
                    unset 'FAILED_SCRIPTS[-1]'
                    SKIPPED_SCRIPTS+=("$script_name")
                    return 0
                    ;;
                *)
                    log ERR "Aborting."
                    print_summary
                    exit "$exit_code"
                    ;;
            esac
        fi
    done
}

main() {
    printf "\n%s%s=== ARCH CHROOT ORCHESTRATOR ===%s\n\n" "$B" "$HL" "$RS"
    log INFO "Working Directory: $(pwd)"

    # --- EXECUTION MODE SELECTION (From ORCHESTRA.sh) ---
    local interactive_mode=1
    printf "\n%s>>> EXECUTION MODE <<<%s\n" "$Y" "$RS"
    read -r -p "Do you want to run autonomously (no prompts)? [y/N]: " _mode_choice
    if [[ "${_mode_choice,,}" == "y" || "${_mode_choice,,}" == "yes" ]]; then
        interactive_mode=0
        log INFO "Autonomous mode selected. Running all scripts without confirmation."
    else
        log INFO "Interactive mode selected. You will be asked before each script."
    fi

    # --- MAIN LOOP ---
    for script in "${INSTALL_SEQUENCE[@]}"; do
        
        # Check if file exists before anything else
        if [[ ! -f "$script" ]]; then
            log ERR "File not found: $script"
            printf "%sAction Required:%s\n" "$Y" "$RS"
            read -r -p "Script missing. [S]kip to next or [A]bort? (s/a): " missing_choice
            if [[ "${missing_choice,,}" == "s" ]]; then
                SKIPPED_SCRIPTS+=("$script")
                continue
            else
                print_summary
                exit 1
            fi
        fi

        # --- SHOW NEXT SCRIPT PREVIEW (From ORCHESTRA.sh) ---
        if [[ $interactive_mode -eq 1 ]]; then
            printf "\n%s>>> NEXT SCRIPT:%s %s\n" "$Y" "$RS" "$script"
            read -r -p "Do you want to [P]roceed, [S]kip, or [Q]uit? (p/s/q): " _user_confirm
            case "${_user_confirm,,}" in
                s|skip)
                    log WARN "Skipping $script (User Selection)"
                    SKIPPED_SCRIPTS+=("$script")
                    continue
                    ;;
                q|quit)
                    log INFO "User requested exit."
                    print_summary
                    exit 0
                    ;;
                *)
                    # Fall through to execution (Proceed)
                    ;;
            esac
        fi

        execute_script "$script"
    done

    printf "\n%s%s=== ORCHESTRATION COMPLETE ===%s\n" "$G" "$HL" "$RS"
    print_summary
    
    # Exit with appropriate code based on execution state
    (( ${#FAILED_SCRIPTS[@]} == 0 ))
}

main
