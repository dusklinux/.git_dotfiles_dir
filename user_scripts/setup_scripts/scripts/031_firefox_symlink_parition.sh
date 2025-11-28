#!/bin/bash

# ==============================================================================
# Firefox Data Migration Utility
# ==============================================================================
# DESCRIPTION:
# This script migrates Firefox user data from the home directory to a dedicated 
# mounted partition. 
#
# BEHAVIOR:
# 1. MUST be run with sudo.
# 2. Detects the actual user (SUDO_USER) to target the correct home directory.
# 3. Prompts for confirmation of dedicated partition mount.
# 4. WIPES local ~/.mozilla and ~/.cache/mozilla without backup.
# 5. Creates target structure on /mnt/browser and fixes ownership to the user.
# 6. Symlinks target to home and fixes ownership of the link.
# ==============================================================================

# ------------------------------------------------------------------------------
# PRE-FLIGHT CHECKS & USER DETECTION
# ------------------------------------------------------------------------------

# Ensure script IS run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo."
  echo "Usage: sudo ./migrate_firefox.sh"
  exit 1
fi

# Detect the real user who ran sudo
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
NC='\033[0m' # No Color

echo -e "${YELLOW}:: Firefox Data Migration Tool initialized.${NC}"
echo -e "Target User: ${GREEN}$REAL_USER${NC}"
echo -e "Target Home: ${GREEN}$REAL_HOME${NC}"
echo "This script will permanently delete Firefox data in the home directory."
echo ""

# ------------------------------------------------------------------------------
# STEP 1: Interactive Prompts
# ------------------------------------------------------------------------------

# Prompt 1: Check for dedicated partition
read -p "Do you have a dedicated partition for browser files mounted at /mnt/browser? (y/n): " partition_confirm
if [[ ! "$partition_confirm" =~ ^[Yy]$ ]]; then
    echo "Aborting. Please mount your dedicated drive to /mnt/browser before proceeding."
    exit 1
fi

if [ ! -d "/mnt/browser" ]; then
    echo -e "${RED}Error: /mnt/browser directory not found.${NC}"
    exit 1
fi

# Prompt 2: Check for existing data
read -p "Does this drive already contain existing Firefox/browser data? (y/n): " data_exists
if [[ "$data_exists" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}:: OK. Linking to existing data.${NC}"
else
    echo -e "${GREEN}:: OK. Creating new directory structure.${NC}"
fi

echo -e "${RED}WARNING: Starting destructive operations on $REAL_HOME/.mozilla and $REAL_HOME/.cache/mozilla...${NC}"
read -p "Press [Enter] to execute or Ctrl+C to cancel."

# ------------------------------------------------------------------------------
# STEP 2: Execution
# ------------------------------------------------------------------------------

# 1. Wipe local data
echo -e "${YELLOW}:: Wiping local Firefox data...${NC}"
rm -rf "$REAL_HOME/.mozilla" "$REAL_HOME/.cache/mozilla"

# 2. Create/Ensure target directory on mount
# mkdir -p is safe if directory already exists
echo -e "${YELLOW}:: Ensuring target directory exists on mount...${NC}"
mkdir -p /mnt/browser/.mozilla

# CRITICAL: Since we are root, mkdir creates root-owned folders.
# We must give them back to the user, otherwise Firefox will crash on launch.
# We do this recursively in case we just created it, but it's safe on existing data too.
# (If data exists, we ensure the user owns it, which is a good fix anyway).
echo -e "${YELLOW}:: Setting ownership permissions on /mnt/browser/.mozilla...${NC}"
chown -R "$REAL_USER":"$REAL_GROUP" /mnt/browser/.mozilla

# 3. Create the symbolic link
echo -e "${YELLOW}:: Linking /mnt/browser/.mozilla to $REAL_HOME/.mozilla...${NC}"
# No 'sudo' prefix needed here because we ARE root.
ln -nfs /mnt/browser/.mozilla "$REAL_HOME/.mozilla"

# CRITICAL: Ensure the symlink itself is owned by the user, not root.
chown -h "$REAL_USER":"$REAL_GROUP" "$REAL_HOME/.mozilla"

# ------------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------------
echo -e "${GREEN}:: Operation complete.${NC}"
echo "Firefox is now configured to use /mnt/browser/.mozilla."
