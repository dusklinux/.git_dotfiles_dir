#!/usr/bin/env bash
#
# Arch Linux Configuration Script (Chroot Phase)
# Optimized for Bash 5+ | Arch Linux | Hyprland/UWSM Context
#

# --- 1. Safety & Environment ---
set -euo pipefail
IFS=$'\n\t'

# --- 2. Visuals & Helpers ---
BOLD=$'\e[1m'
RESET=$'\e[0m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
RED=$'\e[31m'
YELLOW=$'\e[33m'

log_info() { printf "${BLUE}[INFO]${RESET} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${RESET} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${RESET} %s\n" "$1"; }
log_step() { printf "\n${BOLD}${YELLOW}>>> STEP: %s${RESET}\n" "$1"; }

# Function to preview next step and ask for permission (Orchestrator Logic)
ask_next_step() {
    local step_description="$1"
    
    # Visual Separator for clarity
    printf "\n${BLUE}----------------------------------------------------------------${RESET}\n"
    printf "${BOLD}UPCOMING STEP:${RESET} %s\n" "$step_description"

    # === NEW: Check for Automated Mode ===
    if [[ "${INTERACTIVE_MODE:-false}" == "false" ]]; then
        printf "${GREEN}>> Auto-proceeding...${RESET}\n"
        return 0
    fi

    while true; do
        read -r -p "Action: [P]roceed, [S]kip, or [Q]uit? (p/s/q) [Default: p]: " choice
        choice=${choice:-p} # Default to proceed

        case "${choice,,}" in
            p|proceed|y|yes)
                return 0 # Return true to run the block
                ;;
            s|skip)
                log_info "Skipping step: $step_description"
                return 1 # Return false to skip the block
                ;;
            q|quit)
                log_info "User requested exit."
                exit 0
                ;;
            *)
                printf "Invalid choice. Please enter [p]roceed, [s]kip, or [q]uit.\n"
                ;;
        esac
    done
}

# Cleanup on exit
trap 'printf "${RESET}\n"' EXIT

# --- 3. Pre-flight Check (Chroot) ---
log_step "Environment Check"
read -r -p "$(printf "${BOLD}Are you currently inside the 'arch-chroot /mnt' environment? [Y/n]: ${RESET}")" chroot_check
chroot_check=${chroot_check:-y}

if [[ ! "$chroot_check" =~ ^[Yy] ]]; then
    log_error "This script must be run inside the chroot."
    printf "Please run: ${BOLD}arch-chroot /mnt${RESET} first.\n"
    exit 1
fi
log_success "Environment confirmed."

# --- 4. Main Logic ---

# === NEW: Execution Mode Selection ===
log_step "Execution Mode"
printf "Select execution mode:\n"
printf "  ${BOLD}[A]${RESET}utomated  - Proceed through all steps without pausing (Default)\n"
printf "  ${BOLD}[I]${RESET}nteractive - Ask for confirmation before every step\n"
read -r -p "Enter choice [A/i]: " mode_choice
mode_choice=${mode_choice:-a}

if [[ "$mode_choice" =~ ^[Ii] ]]; then
    INTERACTIVE_MODE="true"
    log_info "Running in INTERACTIVE mode."
else
    INTERACTIVE_MODE="false"
    log_info "Running in AUTOMATED mode."
fi


# === Step 19: Setting System Time ===
if ask_next_step "Configure Timezone & Hardware Clock"; then
    log_step "Setting System Time"

    DEFAULT_TZ="Asia/Kolkata"
    TARGET_TZ=""

    # Ask user if they want the default or manual selection
    read -r -p "$(printf "Use default timezone ${BOLD}%s${RESET}? [Y/n]: " "$DEFAULT_TZ")" use_default
    use_default=${use_default:-y}

    if [[ "$use_default" =~ ^[Yy] ]]; then
        TARGET_TZ="$DEFAULT_TZ"
    else
        # Interactive Selection
        if [[ -d "/usr/share/zoneinfo" ]]; then
            log_info "Select Continent/Region:"
            
            # Generate list of regions
            mapfile -t regions < <(find /usr/share/zoneinfo -maxdepth 1 -type d ! -name "." | sed 's|.*/||' | sort)
            
            PS3="Select Region (Number): "
            select region in "${regions[@]}"; do
                if [[ -n "$region" ]]; then
                    break
                else
                    printf "Invalid selection. Try again.\n"
                fi
            done

            log_info "Select City/Zone in $region:"
            mapfile -t cities < <(find "/usr/share/zoneinfo/$region" -maxdepth 1 -type f | sed "s|.*/$region/||" | sort)
            
            PS3="Select City (Number): "
            select city in "${cities[@]}"; do
                if [[ -n "$city" ]]; then
                    TARGET_TZ="$region/$city"
                    break
                else
                    printf "Invalid selection. Try again.\n"
                fi
            done
        else
            log_error "/usr/share/zoneinfo not found. Forcing default."
            TARGET_TZ="$DEFAULT_TZ"
        fi
    fi

    log_info "Setting timezone to $TARGET_TZ..."
    ln -sf "/usr/share/zoneinfo/$TARGET_TZ" /etc/localtime

    # Set Hardware Clock
    hwclock --systohc
    log_success "Timezone set to $TARGET_TZ and hardware clock synced."
fi

# === Step 20 & 21: Setting System Language ===
if ask_next_step "Generate Locale (en_US.UTF-8) & set LANG variable"; then
    log_step "Setting System Language"

    # Uncomment en_US.UTF-8
    log_info "Uncommenting en_US.UTF-8 in /etc/locale.gen..."
    sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen

    # Generate Locale
    log_info "Generating locales..."
    locale-gen

    # Set locale.conf
    log_info "Setting LANG in /etc/locale.conf..."
    printf "LANG=en_US.UTF-8\n" > /etc/locale.conf

    log_success "System language configured."
fi

# === Step 22: Setting Hostname ===
if ask_next_step "Set System Hostname"; then
    log_step "Setting Hostname"

    DEFAULT_HOST="workstation"
    read -r -p "$(printf "Enter hostname [Default: ${BOLD}%s${RESET}]: " "$DEFAULT_HOST")" USER_HOST
    FINAL_HOST="${USER_HOST:-$DEFAULT_HOST}"

    printf "%s\n" "$FINAL_HOST" > /etc/hostname
    log_success "Hostname set to: $FINAL_HOST"
fi

# === Step 23: Setting Root Password ===
if ask_next_step "Set Password for Root (Administrator)"; then
    log_step "Setting Root Password"

    log_info "Please enter the password for the ROOT account:"
    passwd
    if [[ $? -eq 0 ]]; then
        log_success "Root password set successfully."
    else
        log_error "Failed to set root password."
        exit 1
    fi
fi

# === Step 24: Creating User Account ===
if ask_next_step "Create User Account & Install ZSH"; then
    log_step "Creating User Account"

    # === MODIFICATION START: Pre-install ZSH ===
    log_info "Ensuring ZSH binary exists before assignment..."
    # Using --noconfirm to prevent script hang, --needed to skip if already present
    pacman -S --needed --noconfirm zsh
    # === MODIFICATION END ===

    DEFAULT_USER="dusk"
    read -r -p "$(printf "Enter username [Default: ${BOLD}%s${RESET}]: " "$DEFAULT_USER")" INPUT_USER
    FINAL_USER="${INPUT_USER:-$DEFAULT_USER}"

    # Check if user exists before attempting creation
    if id "$FINAL_USER" &>/dev/null; then
        log_info "User '$FINAL_USER' already exists. Skipping creation."
    else
        log_info "Creating user '$FINAL_USER' with ZSH as default shell..."
        # Explicitly set shell to zsh during creation (Greenfield approach)
        useradd -m -G wheel,input,audio,video,storage,optical,network,lp,power,games,rfkill -s /usr/bin/zsh "$FINAL_USER"
        log_success "User '$FINAL_USER' created with ZSH shell."
    fi

    log_info "Please set the password for user '$FINAL_USER':"
    passwd "$FINAL_USER"

    log_success "User account setup complete."
fi

# === Step 25: Wheel Group Rights ===
if ask_next_step "Configure Sudoers (Grant Wheel group access)"; then
    log_step "Configuring Sudoers (Wheel Group)"

    log_info "Creating /etc/sudoers.d/10_wheel drop-in file..."
    # Using the specific piped EDITOR approach from notes to ensure syntax safety via visudo
    printf '%%wheel ALL=(ALL:ALL) ALL\n' | EDITOR='tee' visudo -f /etc/sudoers.d/10_wheel >/dev/null

    log_success "Wheel group privileges granted."
fi

# === Step 26: Configuring Initramfs (mkinitcpio) ===
if ask_next_step "Configure mkinitcpio (BTRFS modules & Systemd hooks)"; then
    log_step "Configuring mkinitcpio.conf"

    CONF_FILE="/etc/mkinitcpio.conf"

    if [[ -f "$CONF_FILE" ]]; then
        log_info "Applying BTRFS modules, binaries, and systemd hooks to $CONF_FILE..."
        
        # Executing the exact sed command from notes
        sed -i -e 's/^MODULES=.*/MODULES=(btrfs)/' \
            -e 's|^BINARIES=.*|BINARIES=(/usr/bin/btrfs)|' \
            -e 's/^HOOKS=.*/HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/' \
            "$CONF_FILE"
            
        log_success "mkinitcpio.conf updated."
    else
        log_error "$CONF_FILE not found! Cannot apply configuration."
        exit 1
    fi
fi

# Final Exit Message
printf "\n${GREEN}${BOLD}Please run the package installer script now to install all the packages. . .${RESET}\n"
