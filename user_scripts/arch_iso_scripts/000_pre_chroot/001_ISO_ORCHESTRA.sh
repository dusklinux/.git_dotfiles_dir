#!/usr/bin/env bash
# ==============================================================================
#  ARCH ISO ORCHESTRATOR (PART 1: DISK TO PACSTRAP)
#  Context: Run in ARCH ISO (Root)
# ==============================================================================

# --- 1. CONFIGURATION ---
INSTALL_SEQUENCE=(
  "002_environment_prep.sh"
  "003_formatting.sh"
  "004_disk_mount.sh"
  "005_mirrorlist.sh"
  "006_console_fix.sh"
  "007_pacstrap.sh"
# "007_pacstrap_old_works.sh"
  "008_script_directories_population_in_chroot.sh"
  "009_fstab.sh"
)

# --- 2. SETUP & SAFETY ---
set -o errexit   # Exit on error
set -o nounset   # Abort on unbound variable
set -o pipefail  # Catch pipe errors

# FORCE SCRIPT TO RUN IN ITS OWN DIRECTORY
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

# --- 4. EXECUTION ENGINE ---
execute_script() {
    local script_name="$1"

    # Retry Loop
    while true; do
        log INFO "Executing: ${HL}$script_name${RS}"
        
        chmod +x "$script_name"

        set +e
        # execute in current shell or subshell depending on preference, 
        # using ./ ensures it runs as executable
        ./"$script_name"
        local exit_code=$?
        set -e

        if (( exit_code == 0 )); then
            log OK "Finished: $script_name"
            # PAUSE FOR 1 SECOND as requested
            sleep 1
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
    echo -e "\n${B}${HL}=== ARCH ISO INSTALLER ===${RS}\n"
    log INFO "Working Directory: $(pwd)"

    # --- EXECUTION MODE SELECTION ---
    local interactive_mode=1
    echo -e "\n${Y}>>> EXECUTION MODE <<<${RS}"
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
            echo -e "${Y}Action Required:${RS}"
            read -r -p "Script missing. [S]kip to next or [A]bort? (s/a): " missing_choice
            if [[ "${missing_choice,,}" == "s" ]]; then continue; else exit 1; fi
        fi

        # --- SHOW NEXT SCRIPT PREVIEW ---
        if [[ $interactive_mode -eq 1 ]]; then
            echo -e "\n${Y}>>> NEXT SCRIPT:${RS} $script"
            read -r -p "Do you want to [P]roceed, [S]kip, or [Q]uit? (p/s/q): " _user_confirm
            case "${_user_confirm,,}" in
                s|skip)
                    log WARN "Skipping $script (User Selection)"
                    continue
                    ;;
                q|quit)
                    log INFO "User requested exit."
                    exit 0
                    ;;
                *)
                    # Fall through to execution (Proceed)
                    ;;
            esac
        fi

        execute_script "$script"
    done

    echo -e "\n${G}${HL}=== BASE SYSTEM INSTALLED ===${RS}"
    echo "Next step: arch-chroot /mnt"
}

main
