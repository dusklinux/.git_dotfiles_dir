#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: REFLECTOR MIRRORS
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_BLUE=$'\033[34m' C_RESET=$'\033[0m'

echo -e "${C_BLUE}=== UPDATING MIRRORS ===${C_RESET}"

while true; do
    read -rp "Enter country (default: India, 'list' to view): " COUNTRY_INPUT
    if [[ "${COUNTRY_INPUT,,}" == "list" ]]; then
        reflector --list-countries | less
        continue
    fi
    TARGET_COUNTRY="${COUNTRY_INPUT:-India}"
    
    echo "Fetching mirrors for $TARGET_COUNTRY..."
    
    if reflector --protocol https --country "$TARGET_COUNTRY" --latest 10 --sort rate --download-timeout 20 --save /tmp/mirrorlist_check; then
        if [[ $(wc -l < /tmp/mirrorlist_check) -gt 5 ]]; then
            mv /tmp/mirrorlist_check /etc/pacman.d/mirrorlist
            echo "Mirrors updated."
            break
        else
            echo "Reflector returned too few results."
        fi
    else
        echo "Reflector connection failed."
    fi
    
    read -rp "Try again? [Y/n] " retry
    [[ "${retry,,}" == "n" ]] && break
done
