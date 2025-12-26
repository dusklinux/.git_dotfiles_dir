#!/usr/bin/env bash
# ==============================================================================
#  ARCH ISO ORCHESTRATOR (UPDATED)
#  Context: Run in ARCH ISO (Root)
#  Description: Orchestrates the disk partitioning, formatting, and pacstrap.
#  Usage: ./script.sh [--auto|-a] [--dry-run|-d] [--help|-h]
# ==============================================================================

# --- 1. CONFIGURATION: EDIT THIS LIST ---
declare -ra INSTALL_SEQUENCE=(
  "002_environment_prep.sh"
  "003_partitioning.sh"
  "004_disk_mount.sh"
  "005_mirrorlist.sh"
  "006_console_fix.sh"
  "007_pacstrap.sh"
# "007_pacstrap_old_works.sh"
  "008_script_directories_population_in_chroot.sh"
  "009_fstab.sh"
)

# --- 2. SETUP & SAFETY ---
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

# FORCE SCRIPT TO RUN IN ITS OWN DIRECTORY
cd "$(dirname "$(readlink -f "$0")")"

# --- 3. LOG FILE SETUP ---
# In the ISO environment, /var/log is in RAM (OverlayFS), which is fast and fine.
LOG_FILE="/var/log/arch-iso-orchestrator-$(date +%Y%m%d-%H%M%S).log"
if ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_FILE="/tmp/arch-iso-orchestrator-$(date +%Y%m%d-%H%M%S).log"
fi
exec > >(tee -a "$LOG_FILE") 2>&1

# --- 4. STATE TRACKING ---
declare -a EXECUTED_SCRIPTS=()
declare -a SKIPPED_SCRIPTS=()
declare -a FAILED_SCRIPTS=()
declare -i TOTAL_START_TIME=0
declare -i DRY_RUN=0
declare -i AUTO_MODE=0

# --- 5. VISUALS ---
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

# --- 6. SUMMARY FUNCTION ---
print_summary() {
    printf "\n%s%s=== ISO INSTALLATION SUMMARY ===%s\n" "$B" "$HL" "$RS"
    
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
    
    # Total execution time
    if (( TOTAL_START_TIME > 0 )); then
        local end_time duration_total
        end_time=$(date +%s)
        duration_total=$((end_time - TOTAL_START_TIME))
        printf "\n%sTotal time:%s %dm %ds\n" "$B" "$RS" $((duration_total/60)) $((duration_total%60))
    fi
    
    printf "%sLog file:%s  %s\n" "$B" "$RS" "$LOG_FILE"
}

# --- 7. CTRL+C TRAP (GRACEFUL EXIT) ---
cleanup() {
    printf "\n"
    log WARN "Installation interrupted by user!"
    print_summary
    exit 130
}
trap cleanup SIGINT SIGTERM

# --- 8. CLI ARGUMENT PARSING ---
parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            -a|--auto)
                AUTO_MODE=1
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -h|--help)
                printf "Usage: %s [OPTIONS]\n\n" "${0##*/}"
                printf "Options:\n"
                printf "  -a, --auto      Run fully autonomous (no initial prompt)\n"
                printf "  -d, --dry-run   Preview execution without running scripts\n"
                printf "  -h, --help      Show this help message\n\n"
                printf "Scripts in sequence:\n"
                for s in "${INSTALL_SEQUENCE[@]}"; do
                    printf "  • %s\n" "$s"
                done
                exit 0
                ;;
            *)
                log WARN "Unknown option: $1"
                shift
                ;;
        esac
    done
}

# --- 9. PRE-FLIGHT VALIDATION ---
preflight_check() {
    local missing=0
    log INFO "Validating script files..."
    
    for script in "${INSTALL_SEQUENCE[@]}"; do
        if [[ ! -f "$script" ]]; then
            log ERR "Missing: $script"
            ((++missing))
        fi
    done
    
    if ((missing > 0)); then
        log ERR "$missing script(s) missing."
        printf "%sAction Required:%s\n" "$Y" "$RS"
        read -r -p "Continue anyway? [y/N]: " _preflight_choice
        if [[ "${_preflight_choice,,}" != "y" && "${_preflight_choice,,}" != "yes" ]]; then
            log ERR "Aborting due to missing scripts."
            exit 1
        fi
        log WARN "Continuing despite missing scripts..."
    else
        log OK "All ${#INSTALL_SEQUENCE[@]} scripts found."
    fi
}

# --- 10. SCRIPT DESCRIPTION HELPER ---
get_script_description() {
    local script="$1"
    local desc
    # Try to get first comment line after shebang (line 2)
    desc=$(sed -n '2s/^#[[:space:]]*//p' "$script" 2>/dev/null)
    if [[ -z "$desc" ]]; then
        # Try line 3 if line 2 was empty or not a comment
        desc=$(sed -n '3s/^#[[:space:]]*//p' "$script" 2>/dev/null)
    fi
    printf "%s" "${desc:-No description available}"
}

# --- 11. ROOT CHECK ---
if (( EUID != 0 )); then
    log ERR "This script must be run as root (Arch ISO default)."
    exit 1
fi

# --- 12. EXECUTION ENGINE ---
execute_script() {
    local script_name="$1"
    local current="$2"
    local total="$3"
    local start_time end_time duration

    # Retry Loop
    while true; do
        log INFO "[$current/$total] Executing: ${HL}$script_name${RS}"
        
        # Dry-run mode: skip actual execution
        if ((DRY_RUN)); then
            log INFO "[DRY-RUN] Would execute: $script_name"
            EXECUTED_SCRIPTS+=("$script_name")
            sleep 0.5
            return 0
        fi
        
        chmod +x "$script_name"

        start_time=$(date +%s)
        set +e
        # Using ./ ensures we run the local file
        bash "$script_name"
        local exit_code=$?
        set -e
        end_time=$(date +%s)
        duration=$((end_time - start_time))

        if (( exit_code == 0 )); then
            log OK "Finished: $script_name (${duration}s)"
            EXECUTED_SCRIPTS+=("$script_name")
            sleep 1
            return 0
        else
            log ERR "Failed: $script_name (Exit Code: $exit_code, after ${duration}s)"
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

# --- 13. MAIN FUNCTION ---
main() {
    # Parse command line arguments first
    parse_args "$@"
    
    # Start total timer
    TOTAL_START_TIME=$(date +%s)
    
    printf "\n%s%s=== ARCH ISO ORCHESTRATOR ===%s\n\n" "$B" "$HL" "$RS"
    log INFO "Working Directory: $(pwd)"
    log INFO "Log file: $LOG_FILE"
    log INFO "Scripts to execute: ${#INSTALL_SEQUENCE[@]}"
    
    if ((DRY_RUN)); then
        log WARN "DRY-RUN MODE: No scripts will actually be executed."
    fi

    # Pre-flight validation
    preflight_check

    # --- EXECUTION MODE SELECTION ---
    local interactive_mode=1
    
    if ((AUTO_MODE)); then
        interactive_mode=0
        log INFO "Autonomous mode (--auto flag). Running all scripts without confirmation."
    else
        printf "\n%s>>> EXECUTION MODE <<<%s\n" "$Y" "$RS"
        read -r -p "Do you want to run autonomously (no prompts)? [y/N]: " _mode_choice
        if [[ "${_mode_choice,,}" == "y" || "${_mode_choice,,}" == "yes" ]]; then
            interactive_mode=0
            log INFO "Autonomous mode selected. Running all scripts without confirmation."
        else
            log INFO "Interactive mode selected. You will be asked before each script."
        fi
    fi

    # --- MAIN LOOP ---
    local total=${#INSTALL_SEQUENCE[@]}
    local current=0
    
    for script in "${INSTALL_SEQUENCE[@]}"; do
        ((++current))
        
        # Check if file exists (backup check after preflight)
        if [[ ! -f "$script" ]]; then
            log ERR "[$current/$total] File not found: $script"
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

        # --- SHOW NEXT SCRIPT PREVIEW (Interactive Mode) ---
        if [[ $interactive_mode -eq 1 ]]; then
            local description
            description=$(get_script_description "$script")
            
            printf "\n%s>>> NEXT SCRIPT [%d/%d]:%s %s\n" "$Y" "$current" "$total" "$RS" "$script"
            printf "    %sDescription:%s %s\n" "$B" "$RS" "$description"
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

        execute_script "$script" "$current" "$total"
    done

    printf "\n%s%s=== BASE SYSTEM INSTALLED ===%s\n" "$G" "$HL" "$RS"
    log INFO "Next step: arch-chroot /mnt"
    print_summary
    
    # Exit with appropriate code based on execution state
    (( ${#FAILED_SCRIPTS[@]} == 0 ))
}

main "$@"
