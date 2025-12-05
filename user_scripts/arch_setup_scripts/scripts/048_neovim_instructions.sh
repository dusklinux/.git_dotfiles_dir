#!/usr/bin/env bash
# ==============================================================================
#  NEOVIM INTERACTIVE CONFIGURATION GUIDE
# ==============================================================================
#  Purpose: Guides the user through the initial "hydration" of Neovim plugins
#           and the manual installation of Mason tools.
#  Context: Arch Linux / Hyprland / UWSM
# ==============================================================================

# 1. Safety & Environment
set -euo pipefail

# 2. Presentation & Constants
readonly SCRIPT_NAME="${0##*/}"
# We use a dummy filename to force Neovim to load filetype-specific plugins
readonly TRIGGER_FILE="nvim_plugin_trigger.sh"

# Colors
declare RED="" GREEN="" BLUE="" YELLOW="" BOLD="" RESET=""
if [[ -t 1 ]] && command -v tput &>/dev/null; then
    if (( $(tput colors 2>/dev/null || echo 0) >= 8 )); then
        RED=$(tput setaf 1); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4); BOLD=$(tput bold); RESET=$(tput sgr0)
    fi
fi

# 3. Utility Functions

cleanup() {
    # 1. Reset terminal colors
    printf "%s\n" "${RESET}"
    # 2. Remove the dummy trigger file if the user accidentally saved it
    if [[ -f "$TRIGGER_FILE" ]]; then
        rm -f "$TRIGGER_FILE"
    fi
}
trap cleanup EXIT INT TERM

msg() {
    local type="${1:-INFO}"
    local text="${2:-}"
    case "${type}" in
        INFO)    printf "%s[INFO]%s %s\n" "$BLUE" "$RESET" "$text" ;;
        SUCCESS) printf "%s[OK]%s   %s\n" "$GREEN" "$RESET" "$text" ;;
        WARN)    printf "%s[WARN]%s %s\n" "$YELLOW" "$RESET" "$text" >&2 ;;
        CMD)     printf "%s  > %s%s\n" "$GREEN" "$text" "$RESET" ;;
    esac
}

pause_for_user() {
    local prompt="${1:-Press [Enter] to open Neovim...}"
    printf "\n"
    read -r -p "${YELLOW}${prompt}${RESET}" || true
    printf "\n"
}

copy_to_clipboard() {
    local text="$1"
    if command -v wl-copy &>/dev/null; then
        printf "%s" "$text" | wl-copy || true
        msg "SUCCESS" "Copied to clipboard: ${BOLD}'${text}'${RESET}"
    else
        msg "WARN" "Could not copy to clipboard (wl-copy missing)."
    fi
}

safe_nvim() {
    # We open the TRIGGER_FILE instead of plain nvim.
    # This forces 'BufRead' and 'FileType' events, loading lazy plugins.
    nvim "$TRIGGER_FILE" || msg "WARN" "Neovim exited with a code (normal during bootstrap)."
}

# 4. Main Logic
main() {
    # Check for nvim
    if ! command -v nvim &>/dev/null; then
        msg "ERROR" "Neovim is not installed."
        exit 1
    fi

    clear
    printf "%s=== Neovim Configuration Wizard ===%s\n\n" "$BOLD" "$RESET"

    # --- Phase 1: Initial Hydration ---
    msg "INFO" "Neovim needs to initialize plugins on its first run."
    
    # ACTION: Copy the first command
    copy_to_clipboard ":TSInstall regex"
    
    # Ensure file is empty for start
    > "$TRIGGER_FILE"

    printf "\n%sINSTRUCTIONS:%s\n" "$BOLD" "$RESET"
    printf "  1. Neovim will open.\n"
    printf "  2. Wait for network activity (scrolling text) to stop.\n"
    printf "  3. Press %sShift + ;%s (colon) to enter command mode.\n" "$BOLD" "$RESET"
    printf "  4. Paste the command using %sCtrl + Shift + V%s and hit Enter.\n" "$BOLD" "$RESET"
    printf "  5. Wait for it to finish, then type %s:q%s to exit.\n" "$BOLD" "$RESET"
    
    pause_for_user
    safe_nvim

    # --- Phase 2: Mason Tools ---
    clear
    printf "%s=== Neovim Configuration: Phase 2 ===%s\n\n" "$BOLD" "$RESET"
    msg "INFO" "Now installing external tools (Formatters/LSPs)."
    
    local tools="clang-format isort prettier prettierd shfmt stylua black"
    
    # ACTION 1: Pre-fill the file so it appears 'pasted' automatically
    echo "$tools" > "$TRIGGER_FILE"
    msg "SUCCESS" "I have pre-pasted the tool list into the file for you."

    # ACTION 2: Copy :Mason command
    copy_to_clipboard ":Mason"
    
    printf "\n%sINSTRUCTIONS:%s\n" "$BOLD" "$RESET"
    printf "  1. Neovim will open. You will see the tool list at the top.\n"
    printf "  2. Press %sShift + ;%s (colon) to enter command mode.\n" "$BOLD" "$RESET"
    printf "  3. Paste %s:Mason%s using %sCtrl + Shift + V%s and hit Enter.\n" "$BOLD" "$RESET" "$BOLD" "$RESET"
    printf "  4. In the Mason window, press %s/%s (search) and type the tools from the list.\n" "$BOLD" "$RESET"
    printf "     (You can see the list in the background buffer)\n"
    printf "  5. When done, close Neovim (discard changes with %s:q!%s if asked).\n" "$BOLD" "$RESET"

    pause_for_user
    safe_nvim

    printf "\n"
    msg "SUCCESS" "Neovim configuration guide complete."
}

# Execute
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
