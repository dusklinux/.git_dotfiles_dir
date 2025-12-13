#!/bin/bash

# ==============================================================================
# SCRIPT CONFIGURATION
# ==============================================================================

# Add domains here to expand the block list.
BLOCKED_DOMAINS=(
    "instagram.com"
    "www.instagram.com"
    "facebook.com"
    "www.facebook.com"
    "m.facebook.com"
    "x.com"
    "www.x.com"
    "twitter.com"
    "www.twitter.com"
    "twitch.tv"
    "www.twitch.tv"
    "kick.com"
    "www.kick.com"
    "www.reddit.com"
)

HOSTS_FILE="/etc/hosts"
REDIRECT_IP="0.0.0.0"

# ANSI Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
NC=$'\033[0m' # No Color

# ==============================================================================
# LOGIC
# ==============================================================================

# 1. Root Privilege Check
# We exit with 1 here so the Orchestrator knows it FAILED and prompts you to Retry with sudo.
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (sudo).${NC}" 
   exit 1
fi

# 2. Intro Message
echo -e "${CYAN}--- Focus Mode Activated ---${NC}"
echo -e "This tool helps you reclaim your time and attention span."
echo -e "It modifies your system hosts file to block access to distracting websites,"
echo -e "preventing you from wasting hours doom-scrolling.\n"

# 3. Base Template
read -r -d '' FILE_CONTENT << EOM
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1       localhost
::1             localhost
EOM

# 4. User Interaction
echo -e "1) Block ${RED}ALL${NC} distracting websites listed"
echo -e "2) Select manually which sites to block"
echo -e "3) Exit / Leave as is (Default)"
read -p "Select an option [1-3]: " option

NEW_ENTRIES=""

case $option in
    1)
        echo -e "${YELLOW}Blocking all configured sites...${NC}"
        for site in "${BLOCKED_DOMAINS[@]}"; do
            NEW_ENTRIES+="${REDIRECT_IP} ${site}"$'\n'
        done
        ;;
    2)
        echo -e "${YELLOW}Entering manual selection mode...${NC}"
        for site in "${BLOCKED_DOMAINS[@]}"; do
            read -p "Block ${site}? [y/N]: " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                NEW_ENTRIES+="${REDIRECT_IP} ${site}"$'\n'
                echo -e "${RED}-> Blocked${NC}"
            else
                echo -e "${GREEN}-> Skipped${NC}"
            fi
        done
        ;;
    ""|[yY]*|3) # Handles Enter (empty), Y/y, or 3
        # ORCHESTRA COMPATIBILITY: 
        # We exit with 0 (Success) so the Orchestrator marks this step as "Done" 
        # and moves to the next script without asking to Retry.
        echo -e "${GREEN}No changes made to hosts file. Exiting.${NC}"
        exit 0
        ;;
    *)
        # We exit with 1 (Error) here so the Orchestrator catches the typo
        # and asks you if you want to Retry.
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

# 5. Execution
if [[ -z "$NEW_ENTRIES" ]]; then
    echo -e "${YELLOW}No sites selected. Exiting.${NC}"
    # Exit 0 -> Orchestrator continues
    exit 0
fi

# Construct final file content
FINAL_OUTPUT="${FILE_CONTENT}
${NEW_ENTRIES}"

# Write to /etc/hosts
echo "$FINAL_OUTPUT" > "$HOSTS_FILE"

echo -e "${GREEN}Done. /etc/hosts updated.${NC}"
# Exit 0 -> Orchestrator continues
exit 0
