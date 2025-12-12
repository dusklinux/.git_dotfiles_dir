#!/bin/bash
# refresh_fonts.sh
# Refreshes font cache and verifies font aliasing for Arch/Hyprland environment.

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
TARGET_FONT="Atkinson Hyperlegible Next"
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m' # No Color

echo -e "${YELLOW}:: Refreshing System Font Cache...${NC}"

# 1. Regenerate the cache (Verbose and Forced as requested)
#    We let stdout flow so you can see the directories being scanned.
fc-cache -fv

echo -e "\n${YELLOW}:: Verifying Font Aliases...${NC}"

# 2. Check the alias
#    We capture the output to perform a logic check
MATCH_OUTPUT=$(fc-match "Arial")
FAMILY_NAME=$(echo "$MATCH_OUTPUT" | cut -d'"' -f 2)

echo -e "   Input Request:  ${NC}Arial"
echo -e "   System Return:  ${NC}$MATCH_OUTPUT"

# 3. Validation Logic
if [[ "$MATCH_OUTPUT" == *"$TARGET_FONT"* ]]; then
  echo -e "\n${GREEN}[SUCCESS] System is correctly aliased to $TARGET_FONT.${NC}"
else
  echo -e "\n${RED}[FAIL] System is NOT using $TARGET_FONT.${NC}"
  echo -e "       Current default for Arial is: $FAMILY_NAME"
  echo -e "       Check ~/.config/fontconfig/fonts.conf or missing font files."
fi
