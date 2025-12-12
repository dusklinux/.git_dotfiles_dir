#!/usr/bin/env bash
# ==============================================================================
#  003_mirrorlist.sh
#  Context: Arch ISO (Root)
#  Description: Optimizes mirrorlist using Reflector with manual fallback options.
# ==============================================================================

# --- CONFIGURATION ---
TARGET_FILE="/etc/pacman.d/mirrorlist"

# Preselected Indian Mirrors (Fallback)
# Single quotes used to prevent premature variable expansion
FALLBACK_MIRRORS=(
    'Server = https://in.arch.niranjan.co/$repo/os/$arch'
    'Server = https://mirrors.saswata.cc/archlinux/$repo/os/$arch'
    'Server = https://in.mirrors.cicku.me/archlinux/$repo/os/$arch'
    'Server = https://archlinux.kushwanthreddy.com/$repo/os/$arch'
    'Server = https://mirror.del2.albony.in/archlinux/$repo/os/$arch'
    'Server = https://mirror.sahil.world/archlinux/$repo/os/$arch'
    'Server = https://mirror.maa.albony.in/archlinux/$repo/os/$arch'
    'Server = https://in-mirror.garudalinux.org/archlinux/$repo/os/$arch'
    'Server = https://mirrors.nxtgen.com/archlinux-mirror/$repo/os/$arch'
    'Server = https://mirrors.abhy.me/archlinux/$repo/os/$arch'
)

# --- UTILS ---
if [[ -t 1 ]]; then
    G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; B=$'\e[34m'; NC=$'\e[0m'
else
    G=""; R=""; Y=""; B=""; NC=""
fi

# --- MAIN LOGIC ---
update_mirrors() {
    # Default variable for first run
    local _input_country=""
    
    while true; do
        echo -e "\n${B}:: Mirrorlist Configuration${NC}"
        
        # Ask for country with default to India
        # We put this inside the loop so you can change it if the first attempt fails
        read -r -p ":: Enter country for Reflector (default 'India'): " _input_country
        local country="${_input_country:-India}"

        echo -e "${Y}:: Running Reflector for region: ${country}...${NC}"
        
        # 1. Try to run Reflector
        # Using the $country variable provided by user
        if reflector --country "$country" --latest 10 --protocol https --sort rate --save "$TARGET_FILE"; then
            echo -e "${G}:: Reflector success! Mirrors updated.${NC}"
            
            echo ":: Syncing package database..."
            pacman -Syy
            break
        else
            # 2. Reflector Failed - Error Handling Menu
            echo -e "\n${R}!! Reflector failed to update mirrors for '$country'.${NC}"
            echo "   1) Retry Reflector (Enter new country or try again)"
            echo "   2) Use Preselected Indian Mirrors (Fallback)"
            echo "   3) Do nothing (Leave as default)"
            
            read -r -p ":: Select an option [1-3]: " choice

            case "$choice" in
                1)
                    echo ":: Retrying..."
                    # Loop continues, prompting for country again
                    continue
                    ;;
                2)
                    echo -e "${Y}:: Applying fallback mirror list...${NC}"
                    printf "%s\n" "${FALLBACK_MIRRORS[@]}" > "$TARGET_FILE"
                    
                    echo -e "${G}:: Fallback mirrors applied.${NC}"
                    echo ":: Syncing package database..."
                    pacman -Syy
                    break
                    ;;
                3)
                    echo -e "${Y}:: Skipping mirror update. Leaving existing list intact.${NC}"
                    break
                    ;;
                *)
                    echo "!! Invalid selection."
                    ;;
            esac
        fi
    done
}

# Execute
update_mirrors
