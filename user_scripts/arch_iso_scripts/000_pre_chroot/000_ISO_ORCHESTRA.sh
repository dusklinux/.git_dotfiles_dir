#!/usr/bin/env bash
# ==============================================================================
#  ARCH ISO ORCHESTRATOR (PART 1: DISK TO PACSTRAP)
#  Context: Run in ARCH ISO (Root)
# ==============================================================================

# --- CONFIGURATION ---
INSTALL_SEQUENCE=(
  "001_environment_prep.sh"
  "002_disk_mount.sh"
  "003_mirrorlist.sh"
  "004_console_fix.sh"
  "005_pacstrap.sh"
  "006_script_directories_population_in_chroot.sh"
  "007_fstab.sh"
)

# --- SETUP ---
set -o errexit
set -o nounset
set -o pipefail
cd "$(dirname "$(readlink -f "$0")")"

# --- VISUALS ---
readonly R=$'\e[31m' G=$'\e[32m' B=$'\e[34m' Y=$'\e[33m' HL=$'\e[1m' RS=$'\e[0m'

log() {
    local type="$1"
    local msg="$2"
    case "$type" in
        INFO) printf "${B}[INFO]${RS}  %s\n" "$msg" ;;
        OK)   printf "${G}[OK]${RS}    %s\n" "$msg" ;;
        WARN) printf "${Y}[WARN]${RS}  %s\n" "$msg" ;;
        ERR)  printf "${R}[ERR]${RS}   %s\n" "$msg" ;;
    esac
}

execute_script() {
    local script_name="$1"
    if [[ ! -f "$script_name" ]]; then
        log ERR "Missing script: $script_name"
        exit 1
    fi

    log INFO "Starting module: ${HL}$script_name${RS}"
    chmod +x "$script_name"
    
    # We allow scripts to take over stdin/stdout for user interaction
    if ./$script_name; then
        log OK "Module complete: $script_name"
        sleep 1 # Pause for 1s to allow user verification of success
    else
        log ERR "Module failed: $script_name"
        read -r -p "Abort? [Y/n] " choice
        [[ "${choice,,}" == "n" ]] || exit 1
    fi
}

# --- MAIN ---
echo -e "\n${B}${HL}=== ARCH ISO INSTALLER ===${RS}\n"

for script in "${INSTALL_SEQUENCE[@]}"; do
    execute_script "$script"
done

echo -e "\n${G}${HL}=== BASE SYSTEM INSTALLED ===${RS}"
echo "Next step: arch-chroot /mnt"
