#!/bin/bash

# ==============================================================================
# Waydroid Manager Script
# Author: Gemini
# Version: 1.4 (Fixed uninstall permissions for user directories)
# Description: Installs, manages, and uninstalls Waydroid on major Linux distros,
#              allowing manual placement of system/vendor images. Also provides
#              an option to cleanly stop Waydroid services.
# ==============================================================================

# --- Initial Check: Prevent running the whole script as root ---
if [[ "$EUID" -eq 0 ]]; then
   echo "[ERROR] Do not run this entire script using 'sudo'." >&2
   echo "        Run it as your normal user (e.g., './waydroid.sh')." >&2
   echo "        The script will use 'sudo' internally for commands that require root privileges." >&2
   exit 1
fi

# --- Configuration ---
MANUAL_IMAGE_DIR="/etc/waydroid-extra/images"
REQUIRED_IMAGES=("system.img" "vendor.img")

# --- Helper Functions ---
msg() {
    echo -e "[INFO] $1"
}
warn() {
    echo -e "\n[WARN] $1\n"
}
error_exit() {
    echo -e "\n[ERROR] $1\n" >&2
    exit 1
}
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error_exit "Required command '$1' not found. Please install it first."
    fi
}
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        OS_NAME=$ID
        if [[ "$ID" == "debian" || "$ID_LIKE" == "debian" ]]; then
            PKG_MANAGER="apt-get"
            INSTALL_CMD="sudo $PKG_MANAGER update && sudo $PKG_MANAGER install -y"
            REMOVE_CMD="sudo $PKG_MANAGER remove -y --purge"
            NEEDED_DEPS="curl ca-certificates python3-gbinder lxc"
        elif [[ "$ID" == "fedora" ]]; then
            PKG_MANAGER="dnf"
            INSTALL_CMD="sudo $PKG_MANAGER install -y"
            REMOVE_CMD="sudo $PKG_MANAGER remove -y"
            NEEDED_DEPS="curl python3-gbinder lxc"
        elif [[ "$ID" == "arch" || "$ID_LIKE" == "arch" ]]; then
            PKG_MANAGER="pacman"
            INSTALL_CMD="sudo $PKG_MANAGER -Syu --noconfirm"
            REMOVE_CMD="sudo $PKG_MANAGER -Rns --noconfirm"
            NEEDED_DEPS="curl python3-gbinder lxc"
        else
            error_exit "Unsupported distribution: $PRETTY_NAME."
        fi
        msg "Detected Distribution: $PRETTY_NAME"
        msg "Using Package Manager: $PKG_MANAGER"
    else
        error_exit "Cannot detect Linux distribution. /etc/os-release not found."
    fi
}
check_wayland() {
    # Use loginctl to get session type reliably, even if XDG_SESSION_TYPE isn't set in script env
    local session_type
    session_type=$(loginctl show-session "$XDG_SESSION_ID" -p Type --value)

    if [[ "$session_type" != "wayland" ]]; then
        warn "You do not appear to be running a Wayland session (Detected: $session_type, XDG: $XDG_SESSION_TYPE)."
        warn "Waydroid officially requires Wayland. It might not work correctly on X11/tty."
        read -p "Do you want to continue the installation anyway? (y/N): " confirm_wayland
        if [[ ! "$confirm_wayland" =~ ^[Yy]$ ]]; then
            error_exit "Aborting installation due to non-Wayland session."
        fi
        msg "Continuing installation despite non-Wayland session..."
    else
        msg "Wayland session detected ($session_type)."
    fi
}
install_waydroid() {
    msg "Starting Waydroid installation..."
    detect_distro
    msg "Installing dependencies ($NEEDED_DEPS)..."
    $INSTALL_CMD $NEEDED_DEPS || error_exit "Failed to install dependencies."
    msg "Installing Waydroid..."
    if [[ "$PKG_MANAGER" == "apt-get" ]]; then
        msg "Adding Waydroid repository..."
        sudo curl -sS https://repo.waydro.id/waydroid.gpg --output /usr/share/keyrings/waydroid.gpg || error_exit "Failed to download Waydroid GPG key."
        echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ $VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/waydroid.list > /dev/null || error_exit "Failed to add Waydroid apt source."
        sudo apt-get update
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
         msg "Adding Waydroid COPR repository..."
         sudo dnf copr enable -y aleasto/waydroid || error_exit "Failed to enable Waydroid COPR repository."
    fi
    $INSTALL_CMD waydroid || error_exit "Failed to install Waydroid package."
    msg "Waydroid package installed successfully."
}
handle_manual_images() {
    msg "Handling manual Waydroid images..."
    if [[ ! -d "$MANUAL_IMAGE_DIR" ]]; then
        msg "Creating target directory: $MANUAL_IMAGE_DIR"
        sudo mkdir -p "$MANUAL_IMAGE_DIR" || error_exit "Failed to create directory $MANUAL_IMAGE_DIR (requires sudo)."
    else
        msg "Target directory $MANUAL_IMAGE_DIR already exists."
    fi
    images_exist=true
    for img in "${REQUIRED_IMAGES[@]}"; do
        if [[ ! -f "$MANUAL_IMAGE_DIR/$img" ]]; then
            images_exist=false
            break
        fi
    done
    if $images_exist; then
        msg "Required images (system.img, vendor.img) already exist in $MANUAL_IMAGE_DIR."
        msg "Skipping copy operation."
        return 0
    fi
    msg "Required images not found in $MANUAL_IMAGE_DIR."
    read -rp "Please enter the full path to the directory containing system.img and vendor.img: " source_dir
    if [[ ! -d "$source_dir" ]]; then
        error_exit "Source directory '$source_dir' not found or is not a directory."
    fi
    for img in "${REQUIRED_IMAGES[@]}"; do
        source_file="$source_dir/$img"
        target_file="$MANUAL_IMAGE_DIR/$img"
        if [[ ! -f "$source_file" ]]; then
            error_exit "Required image '$img' not found in '$source_dir'."
        fi
        msg "Copying $img from $source_dir to $MANUAL_IMAGE_DIR..."
        sudo cp "$source_file" "$target_file" || error_exit "Failed to copy $img (requires sudo)."
        sudo chmod 644 "$target_file" || error_exit "Failed to set permissions for $img (requires sudo)."
        msg "$img copied successfully."
    done
    msg "Both system.img and vendor.img have been copied to $MANUAL_IMAGE_DIR."
    return 0
}
initialize_waydroid() {
    msg "Initializing Waydroid with manually placed images..."
    sudo waydroid init -f || error_exit "Waydroid initialization failed. Check logs with 'sudo waydroid log' (requires sudo)."
    msg "Waydroid initialized successfully."
    msg "Checking Waydroid status..."
    sleep 5
    sudo waydroid status || warn "Waydroid status check reported issues. Initialization might still be in progress or failed."
}
start_session() {
    msg "Starting Waydroid session in the background..."
    msg "Starting waydroid-container service..."
    sudo systemctl start waydroid-container.service || error_exit "Failed to start waydroid-container service (requires sudo)."
    msg "Waydroid container service started. It might take a moment for the UI to be available."
    msg "You can check status with 'sudo waydroid status' and logs with 'sudo waydroid log'."
    msg "Launch the Waydroid application from your desktop menu if available."
}
stop_waydroid() {
    msg "Attempting to stop Waydroid completely..."
    msg "Stopping Waydroid user session..."
    sudo waydroid session stop &> /dev/null
    sleep 1
    msg "Stopping waydroid-container service..."
    if sudo systemctl is-active --quiet waydroid-container.service; then
        sudo systemctl stop waydroid-container.service || warn "Failed to stop waydroid-container service cleanly (requires sudo)."
    else
        msg "waydroid-container service is already stopped."
    fi
    sleep 1
    msg "Verifying Waydroid status..."
    if sudo systemctl is-active --quiet waydroid-container.service; then
        warn "waydroid-container service is still active after stop command."
        warn "You might need to check 'sudo systemctl status waydroid-container.service' or 'sudo waydroid log'."
    else
        msg "Waydroid session and container service should now be stopped."
    fi
}
uninstall_waydroid() {
    warn "This will completely remove Waydroid, its configuration, and downloaded data."
    read -p "Are you absolutely sure you want to uninstall Waydroid? (y/N): " confirm_uninstall
    if [[ ! "$confirm_uninstall" =~ ^[Yy]$ ]]; then
        msg "Uninstallation cancelled."
        exit 0
    fi

    msg "Starting Waydroid uninstallation..."
    detect_distro

    msg "Stopping Waydroid services and session (if running)..."
    stop_waydroid # Uses sudo internally

    msg "Destroying Waydroid container data..."
    sudo waydroid container destroy &> /dev/null || warn "Could not destroy container (might be already stopped/removed)."

    msg "Removing Waydroid package..."
    $REMOVE_CMD waydroid || warn "Failed to remove Waydroid package (might be already removed)."

    msg "Removing Waydroid configuration, data, and images..."
    # Use sudo for removing system files/dirs
    sudo rm -rf /etc/waydroid \
                 "$MANUAL_IMAGE_DIR" \
                 /usr/share/waydroid \
                 /var/lib/waydroid

    # *** FIX: Use sudo to remove user-specific dirs/files as they might be root-owned ***
    # Construct the full path to the user's .local/share directory
    local user_share_dir
    # Get the actual home directory path, even if script is run weirdly (though initial check prevents sudo)
    user_share_dir=$(eval echo "~${SUDO_USER:-$USER}/.local/share")

    msg "Removing user-specific Waydroid files (using sudo)..."
    sudo rm -rf "${user_share_dir}/waydroid" \
                 "${user_share_dir}/applications/"*aydroid* \
                 "${user_share_dir}/icons/"*aydroid*

    # Use sudo for this potentially system-owned directory
    sudo rmdir /etc/waydroid-extra &> /dev/null

    # Clean up repositories (if added by this script)
    if [[ "$PKG_MANAGER" == "apt-get" ]]; then
        msg "Removing Waydroid apt repository files..."
        sudo rm -f /etc/apt/sources.list.d/waydroid.list /usr/share/keyrings/waydroid.gpg
        sudo apt-get update
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        msg "Disabling Waydroid COPR repository..."
        sudo dnf copr disable -y aleasto/waydroid &> /dev/null
    fi

    msg "Waydroid uninstallation complete."
    msg "Some user-specific files in ~/.local/share might remain if paths changed or sudo failed."
}

# --- Main Script Logic ---
echo "============================="
echo " Waydroid Manager Script"
echo "============================="
echo "Select an option:"
echo "  1. Install Waydroid (with manual image handling)"
echo "  2. Start Waydroid Session (if already installed/initialized)"
echo "  3. Stop Waydroid (Session & Container)"
echo "  4. Uninstall Waydroid (Complete Removal)"
echo "  5. Exit"
echo "-----------------------------"
read -p "Enter your choice [1-5]: " choice

case $choice in
    1)
        check_wayland
        install_waydroid
        handle_manual_images
        initialize_waydroid
        start_session
        msg "Installation process finished."
        ;;
    2)
        check_command waydroid || error_exit "Waydroid command not found. Is Waydroid installed?"
        start_session # Uses sudo internally
        ;;
    3)
        stop_waydroid # Uses sudo internally
        ;;
    4)
        uninstall_waydroid # Uses sudo internally
        ;;
    5)
        msg "Exiting."
        exit 0
        ;;
    *)
        error_exit "Invalid choice. Please enter a number between 1 and 5."
        ;;
esac

exit 0

