#!/bin/bash

# ==============================================================================
# Firefox Data Migration Utility
# ==============================================================================

# ------------------------------------------------------------------------------
# PRE-FLIGHT CHECKS & USER DETECTION
# ------------------------------------------------------------------------------

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo."
  exit 1
fi

if [ -z "$SUDO_USER" ]; then
    echo "Error: Could not detect the actual user. Do not run as root directly."
    exit 1
fi

REAL_USER="$SUDO_USER"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_GROUP=$(id -gn "$REAL_USER")

# Visual formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}:: Firefox Data Migration Tool initialized.${NC}"
echo -e "Target User: ${GREEN}$REAL_USER${NC}"
echo -e "Target Home: ${GREEN}$REAL_HOME${NC}"

# ------------------------------------------------------------------------------
# STEP 1: Interactive Prompts (Fixed for Orchestra Integration)
# ------------------------------------------------------------------------------

# FORCE read from /dev/tty to bypass Orchestra logging pipes
# CHANGE exit 1 to exit 0 to prevent killing the Orchestra if skipped

read -p "Do you have a dedicated partition for browser files mounted at /mnt/browser? (y/n): " partition_confirm < /dev/tty
if [[ ! "$partition_confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}:: User declined or drive not ready. SKIPPING Firefox migration.${NC}"
    # Exit 0 ensures ORCHESTRA continues to script #032
    exit 0
fi

if [ ! -d "/mnt/browser" ]; then
    echo -e "${RED}Error: /mnt/browser directory not found.${NC}"
    echo -e "${YELLOW}:: SKIPPING Firefox migration to prevent errors.${NC}"
    exit 0
fi

read -p "Does this drive already contain existing Firefox/browser data? (y/n): " data_exists < /dev/tty
if [[ "$data_exists" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}:: OK. Linking to existing data.${NC}"
else
    echo -e "${GREEN}:: OK. Creating new directory structure.${NC}"
fi

echo -e "${RED}WARNING: Starting destructive operations on $REAL_HOME/.mozilla...${NC}"
read -p "Press [Enter] to execute or Ctrl+C to cancel." < /dev/tty

# ------------------------------------------------------------------------------
# STEP 2: Execution
# ------------------------------------------------------------------------------

# 1. Wipe local data
echo -e "${YELLOW}:: Wiping local Firefox data...${NC}"
rm -rf "$REAL_HOME/.mozilla" "$REAL_HOME/.cache/mozilla"

# 2. Create/Ensure target directory on mount
echo -e "${YELLOW}:: Ensuring target directory exists on mount...${NC}"
mkdir -p /mnt/browser/.mozilla

# 3. Fix Ownership (Recursive)
echo -e "${YELLOW}:: Setting ownership permissions on /mnt/browser/.mozilla...${NC}"
chown -R "$REAL_USER":"$REAL_GROUP" /mnt/browser/.mozilla

# 4. Create the symbolic link
echo -e "${YELLOW}:: Linking /mnt/browser/.mozilla to $REAL_HOME/.mozilla...${NC}"
ln -nfs /mnt/browser/.mozilla "$REAL_HOME/.mozilla"

# 5. Fix Symlink Ownership
chown -h "$REAL_USER":"$REAL_GROUP" "$REAL_HOME/.mozilla"

# ------------------------------------------------------------------------------
# 6. Install PSD Systemd Override (Added)
# ------------------------------------------------------------------------------
OVERRIDE_SOURCE="$REAL_HOME/user_scripts/services/psd/override.conf"
OVERRIDE_DEST_DIR="$REAL_HOME/.config/systemd/user/psd.service.d"

if [ -f "$OVERRIDE_SOURCE" ]; then
    echo -e "${YELLOW}:: Detecting PSD override file. Installing...${NC}"

    # Create the directory structure if it doesn't exist
    mkdir -p "$OVERRIDE_DEST_DIR"

    # Link the override file
    ln -nfs "$OVERRIDE_SOURCE" "$OVERRIDE_DEST_DIR/override.conf"

    # Fix ownership of the systemd config directory (since we are root)
    chown -R "$REAL_USER":"$REAL_GROUP" "$REAL_HOME/.config/systemd"

    # Reload systemd user daemon (Must run as the real user)
    echo -e "${YELLOW}:: Reloading systemd user daemon...${NC}"
    sudo -u "$REAL_USER" systemctl --user daemon-reload
else
    echo -e "${RED}Warning: PSD override source not found at $OVERRIDE_SOURCE${NC}"
    echo -e "${RED}Skipping systemd override installation.${NC}"
fi

# ------------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------------
echo -e "${GREEN}:: Firefox migration complete.${NC}"
