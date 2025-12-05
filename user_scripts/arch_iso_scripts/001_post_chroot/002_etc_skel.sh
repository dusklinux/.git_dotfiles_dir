#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: configure_skel.sh
# Description: Stages multiple dotfiles/directories into /etc/skel.
# Context: Arch Linux ISO (Chroot Environment)
# -----------------------------------------------------------------------------

# Strict Mode
set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

# -----------------------------------------------------------------------------
# Visuals
# -----------------------------------------------------------------------------
declare -r BLUE=$'\033[0;34m'
declare -r GREEN=$'\033[0;32m'
declare -r RED=$'\033[0;31m'
declare -r YELLOW=$'\033[0;33m'
declare -r NC=$'\033[0m'

# -----------------------------------------------------------------------------
# Critical Pre-Flight Check (Unchanged)
# -----------------------------------------------------------------------------
printf "\n${RED}[CRITICAL CHECK]${NC} Verify Environment:\n"
printf "Have you switched to the chroot environment by running: ${BLUE}arch-chroot /mnt${NC} ?\n"
read -r -p "Type 'yes' to proceed, or anything else to exit: " user_conf

if [[ "${user_conf,,}" != "yes" ]]; then
    printf "\n${RED}[ABORTING]${NC} You must be inside the chroot environment to run this script.\n"
    printf "Please run the following command first:\n"
    printf "\n    ${BLUE}arch-chroot /mnt${NC}\n\n"
    exit 1
fi

# -----------------------------------------------------------------------------
# Configuration Section
# -----------------------------------------------------------------------------
# INSTRUCTIONS:
# 1. Add entries to the array below.
# 2. Format: "SOURCE_PATH :: DESTINATION_PATH"
# 3. Use absolute paths. (Inside chroot, ~ usually creates path relative to /root)
# 4. If copying a directory contents, ensure source ends with /
# -----------------------------------------------------------------------------

declare -a COPY_TASKS=(
    # Example 1: Copy a single file
    #"/root/deploy_dotfiles.sh :: /etc/skel/deploy_dotfiles.sh"
    
    # Example 2: Copy .zshrc to the root of skel
    # (Assuming source is at /root/dusk/.zshrc inside chroot)
    #"/root/dusk/.zshrc :: /etc/skel/.zshrc"
    
    # Example 3: Copy a directory and its contents
    # This copies 'user_scripts' folder INTO 'Documents'
    #"/root/dusk/user_scripts/ :: /etc/skel/Documents/user_scripts"
    
    # -----------------------------------------------------------
    # Add as many files/direcotires as you want, right below here.
    #
    # With the -T flag, you must be explicit in your configuration array.
    # You cannot point to a folder and expect the script to
    # "drop the file inside." You must define the full destination filename/foldername.
    # 
    # also since this is from the chroot environment, the default starting directory is "/root"
    # -----------------------------------------------------------
    
    #deploy_dotfiles.sh
    "/root/deploy_dotfiles.sh :: /etc/skel/deploy_dotfiles.sh"

    #populate .zshrc
    "/root/dusk/.zshrc :: /etc/skel/.zshrc"

)

# -----------------------------------------------------------------------------
# Logging Helpers
# -----------------------------------------------------------------------------
log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
deploy_item() {
    local source_path="$1"
    local dest_path="$2"

    # 1. Validate Source
    if [[ ! -e "$source_path" ]]; then
        log_warn "Source not found, skipping: $source_path"
        return
    fi

    # 2. Prepare Destination Parent Directory
    # We strip the filename/dirname from the dest path to find the parent
    local dest_parent
    dest_parent=$(dirname "$dest_path")

    if [[ ! -d "$dest_parent" ]]; then
        log_info "Creating parent directory: $dest_parent"
        mkdir -p -- "$dest_parent"
    fi

    # 3. Execution
    log_info "Copying: $source_path -> $dest_path"
    
    # cp -r: recursive (for dirs), -f: force
    cp -rfT -- "$source_path" "$dest_path"

    # 4. Permissions & Ownership
    # Ensure root owns the files in /etc/skel
    chown -R root:root -- "$dest_path"
    
    # Set standard permissions (Directories 755, Files read/exec as needed)
    # If it's a script/executable, we usually want 755. 
    # If it's a config file, 644 is safer, but 755 covers both for skeleton purposes.
    chmod -R 755 -- "$dest_path"
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------
log_info "Starting Skeleton Configuration..."

for task in "${COPY_TASKS[@]}"; do
    # Split the string by the delimiter ' :: '
    # We use parameter expansion to separate source and dest
    local src="${task%% :: *}"
    local dest="${task##* :: }"

    # Trim leading/trailing whitespace just in case
    src="${src#"${src%%[![:space:]]*}"}"
    src="${src%"${src##*[![:space:]]}"}"
    dest="${dest#"${dest%%[![:space:]]*}"}"
    dest="${dest%"${dest##*[![:space:]]}"}"

    deploy_item "$src" "$dest"
done

# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------
log_success "Skeleton configuration complete."
