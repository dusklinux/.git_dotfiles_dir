#!/bin/bash

# --- GRUB Dependency Check and Install Script ---
# This script checks for required dependencies for a GRUB script
# and attempts to install them if missing on Fedora, Debian, Ubuntu, or Mint.
# Place this script at the very beginning of your main GRUB script.

# List of required commands/packages
REQUIRED_COMMANDS=(
    lsblk
    blkid
    mount
    umount
    chroot
    grub-install
    grub-mkconfig # Debian/Ubuntu/Mint might use update-grub, but grub-mkconfig is also often available or part of grub-install package
    os-prober
    parted
    findmnt
    grep
    awk
    dialog
)

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Checking for required GRUB script dependencies..."

# Detect distribution and set package manager
if command_exists dnf; then
    PKG_MANAGER="dnf"
    DISTRO="Fedora"
    # Fedora packages corresponding to the commands
    # Note: Many of these are part of core utilities and might already be installed.
    # We list common packages that contain these tools.
    REQUIRED_PACKAGES=(
        util-linux    # Provides lsblk, mount, umount, findmnt
        util-linux-ng # Provides blkid
        coreutils     # Provides chroot, grep, awk
        grub2-common  # Provides grub-install, grub-mkconfig
        os-prober     # Provides os-prober
        parted        # Provides parted
        dialog        # Provides dialog
    )
elif command_exists apt; then
    PKG_MANAGER="apt"
    DISTRO="Debian/Ubuntu/Mint"
    # Debian/Ubuntu/Mint packages corresponding to the commands
    REQUIRED_PACKAGES=(
        util-linux    # Provides lsblk, mount, umount, findmnt
        blkid         # Provides blkid (sometimes separate, sometimes in util-linux)
        coreutils     # Provides chroot, grep, awk
        grub-common   # Provides grub-install, grub-mkconfig (update-grub)
        os-prober     # Provides os-prober
        parted        # Provides parted
        dialog        # Provides dialog
    )
else
    echo "Error: Could not detect a supported package manager (dnf or apt)."
    echo "Please manually install the required dependencies:"
    echo "${REQUIRED_COMMANDS[@]}"
    exit 1
fi

echo "Detected distribution: $DISTRO (using $PKG_MANAGER)"

# Check for missing commands
MISSING_COMMANDS=()
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
        MISSING_COMMANDS+=("$cmd")
    fi
done

# Install missing packages if any
if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
    echo "Missing dependencies detected: ${MISSING_COMMANDS[*]}"

    # Map missing commands back to potential package names (simplified mapping)
    # This is not foolproof as one package can provide multiple commands,
    # but it gives us a list of packages to try installing.
    PACKAGES_TO_INSTALL=()
    for missing_cmd in "${MISSING_COMMANDS[@]}"; do
        case "$missing_cmd" in
            lsblk|mount|umount|findmnt)
                if [ "$PKG_MANAGER" == "dnf" ]; then PACKAGES_TO_INSTALL+=(util-linux); else PACKAGES_TO_INSTALL+=(util-linux); fi
                ;;
            blkid)
                 if [ "$PKG_MANAGER" == "dnf" ]; then PACKAGES_TO_INSTALL+=(util-linux-ng); else PACKAGES_TO_INSTALL+=(blkid); fi
                ;;
            chroot|grep|awk)
                PACKAGES_TO_INSTALL+=(coreutils)
                ;;
            grub-install|grub-mkconfig)
                if [ "$PKG_MANAGER" == "dnf" ]; then PACKAGES_TO_INSTALL+=(grub2-common); else PACKAGES_TO_INSTALL+=(grub-common); fi
                ;;
            os-prober)
                PACKAGES_TO_INSTALL+=(os-prober)
                ;;
            parted)
                PACKAGES_TO_INSTALL+=(parted)
                ;;
            dialog)
                PACKAGES_TO_INSTALL+=(dialog)
                ;;
            *)
                echo "Warning: Cannot determine package for missing command '$missing_cmd'."
                ;;
        esac
    done

    # Remove duplicates from the list of packages
    readarray -t PACKAGES_TO_INSTALL < <(printf "%s\n" "${PACKAGES_TO_INSTALL[@]}" | sort -u)

    if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
        echo "Attempting to install the following packages: ${PACKAGES_TO_INSTALL[*]}"

        # Check if running as root
        if [ "$EUID" -ne 0 ]; then
            echo "Error: Root privileges are required to install packages."
            echo "Please run this script with sudo or as root."
            exit 1
        fi

        # Install packages
        if [ "$PKG_MANAGER" == "dnf" ]; then
            dnf install -y "${PACKAGES_TO_INSTALL[@]}"
        elif [ "$PKG_MANAGER" == "apt" ]; then
            apt update
            apt install -y "${PACKAGES_TO_INSTALL[@]}"
        fi

        # Re-check commands after installation
        MISSING_AFTER_INSTALL=()
        for cmd in "${REQUIRED_COMMANDS[@]}"; do
            if ! command_exists "$cmd"; then
                MISSING_AFTER_INSTALL+=("$cmd")
            fi
        done

        if [ ${#MISSING_AFTER_INSTALL[@]} -gt 0 ]; then
            echo "Error: The following dependencies are still missing after attempted installation: ${MISSING_AFTER_INSTALL[*]}"
            echo "Please manually install them."
            exit 1
        else
            echo "All required dependencies are now installed."
        fi
    else
         echo "Could not determine packages for missing commands. Please install manually."
         exit 1
    fi
else
    echo "All required dependencies are already installed."
fi

# --- End of Dependency Check Script ---

# You can now continue with the rest of your GRUB script logic below this line.
# For example:
# lsblk
# ... rest of your script ...


