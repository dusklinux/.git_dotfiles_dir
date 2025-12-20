#!/usr/bin/env bash

# ==============================================================================
# ARCH LINUX DOTFILES SYNC (MANUAL SPEEDRUN REPLICA - FINAL FIX)
# Context: Hyprland / UWSM / Bash 5+
# Logic: Ask Intent -> Clone Bare -> Reset -> Sync via .git_dusky_list
# Updates:
#   1. Forces execution from $HOME to fix path errors.
#   2. Filters missing files to prevent 'pathspec' crash.
#   3. Supports interactive SSH passphrases.
#   4. Allows custom Repository Name input (matches 053 logic).
# ==============================================================================

# 1. STRICT SAFETY
set -euo pipefail
IFS=$'\n\t'

# 2. CONSTANTS
readonly DEFAULT_REPO_NAME="dusky"
readonly DOTFILES_DIR="$HOME/dusky"
readonly DOTFILES_LIST="$HOME/.git_dusky_list"
readonly SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
readonly SSH_DIR="$HOME/.ssh"
readonly REQUIRED_CMDS=(git ssh ssh-keygen ssh-agent grep mktemp)

# 3. VISUALS
readonly BOLD=$'\033[1m'
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly YELLOW=$'\033[0;33m'
readonly CYAN=$'\033[0;36m'
readonly NC=$'\033[0m'

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC}   %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERR]${NC}  %s\n" "$*" >&2; }
log_fatal()   { log_error "$*"; exit 1; }

# The Git Wrapper (Simulates your git_dusky alias)
dotgit() {
    /usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

cleanup() {
    if [[ -n "${SCRIPT_SSH_AGENT_PID:-}" ]]; then
        kill "$SCRIPT_SSH_AGENT_PID" >/dev/null 2>&1 || true
    fi
    # Remove temp file for clean list if it exists
    if [[ -n "${CLEAN_LIST:-}" && -f "${CLEAN_LIST:-}" ]]; then
        rm -f "$CLEAN_LIST"
    fi
}
trap cleanup EXIT

# ==============================================================================
# PRE-FLIGHT
# ==============================================================================

# CRITICAL FIX: Switch to HOME so relative paths in dotfiles_list work
cd "$HOME" || log_fatal "Could not change directory to HOME."

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        log_fatal "Missing dependency: $cmd"
    fi
done

# ==============================================================================
# 1. INITIAL PROMPT
# ==============================================================================

clear
printf "${BOLD}Arch Linux Dotfiles Linker${NC}\n"
printf "This script links $HOME to your GitHub bare repository (No Overwrites).\n\n"

# ASK THE USER IF THEY HAVE A REPO
read -r -p "Do you have an existing GitHub repository to commit changes to? (y/N): " HAS_REPO

if [[ ! "$HAS_REPO" =~ ^[yY] ]]; then
    printf "\n"
    log_info "Okay."
    printf "You can do so anytime by runing the: \n"
    printf "${CYAN}'0XX_new_github_repo_to_backup.sh'${NC} Script.\n\n"
    log_success "Exiting successfully."
    exit 0
fi

# ==============================================================================
# 2. INPUT GATHERING
# ==============================================================================

printf "\n${BOLD}--- Configuration ---${NC}\n"

ask() {
    local prompt="$1"
    local var_name="$2"
    local input
    while [[ -z "${input:-}" ]]; do
        read -r -p "   $prompt: " input
    done
    eval "$var_name=\"$input\""
}

printf "${CYAN}1. Identity${NC}\n"
ask "Git User Name (e.g., 'any_name')" GIT_NAME
ask "Git Email (e.g., 'xyz@gmail.com')" GIT_EMAIL

printf "\n${CYAN}2. Repository${NC}\n"
ask "GitHub Username (e.g., 'your_actual_github_name')" GH_USERNAME

# UPDATED: Interactive Repo Name selection matching script 053
printf "${CYAN}Repo Name${NC}\n"
printf "   The name of the repository on GitHub.\n"
read -r -p "   > [Default: $DEFAULT_REPO_NAME]: " INPUT_REPO_NAME
REPO_NAME="${INPUT_REPO_NAME:-$DEFAULT_REPO_NAME}"

printf "\n${CYAN}3. Commit${NC}\n"
ask "Initial Commit Message" COMMIT_MSG

# UPDATED: Uses REPO_NAME instead of hardcoded string
REPO_URL="git@github.com:${GH_USERNAME}/${REPO_NAME}.git"

printf "\n${BOLD}Review Configuration:${NC}\n"
printf "  User:   $GIT_NAME <$GIT_EMAIL>\n"
printf "  Repo:   $REPO_URL\n"
read -r -p "Proceed? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[yY] ]] || log_fatal "Aborted by user."

# ==============================================================================
# 3. SSH SETUP (Interactive Password Support)
# ==============================================================================

printf "\n${BOLD}--- SSH Configuration ---${NC}\n"

if [[ ! -d "$SSH_DIR" ]]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Key Generation
if [[ -f "$SSH_KEY_PATH" ]]; then
    log_warn "SSH key exists at $SSH_KEY_PATH"
    read -r -p "   Overwrite? (y/N): " OW
    if [[ "$OW" =~ ^[yY] ]]; then
        rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
        # Removed -N "" -q to allow interactive passphrase
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH"
        log_success "New key generated."
    else
        log_info "Using existing key."
    fi
else
    # Removed -N "" -q to allow interactive passphrase
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH"
    log_success "Key generated."
fi

# Agent Start
eval "$(ssh-agent -s)" >/dev/null
SCRIPT_SSH_AGENT_PID="$SSH_AGENT_PID"

# Add Key (Interactive handling)
log_info "Adding SSH key to agent..."
if ! ssh-add "$SSH_KEY_PATH" 2>/dev/null; then
    log_info "Passphrase required. Please enter it now:"
    ssh-add "$SSH_KEY_PATH"
fi

printf "\n${YELLOW}${BOLD}ACTION REQUIRED:${NC} Add this key to GitHub (Settings -> SSH Keys)\n"
printf "%s\n" "----------------------------------------------------------------"
cat "$SSH_KEY_PATH.pub"
printf "%s\n" "----------------------------------------------------------------"
read -r -p "Press [Enter] once you have added the key to GitHub..."

log_info "Testing connection..."
set +e
ssh -T -o StrictHostKeyChecking=accept-new git@github.com >/dev/null 2>&1
SSH_CODE=$?
set -e

if [[ $SSH_CODE -eq 1 ]]; then
    log_success "GitHub authentication verified."
else
    log_fatal "SSH Connection failed. Exit code: $SSH_CODE"
fi

# ==============================================================================
# 4. REPO SETUP (Clone -> Reset -> Sync)
# ==============================================================================

printf "\n${BOLD}--- Repository Setup ---${NC}\n"

# 1. Clean previous
if [[ -d "$DOTFILES_DIR" ]]; then
    log_warn "Removing existing dotfiles directory..."
    rm -rf "$DOTFILES_DIR"
fi

# 2. Global Config
log_info "Setting global git config..."
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

# 3. Clone Bare
log_info "Cloning bare repo..."
git clone --bare "$REPO_URL" "$DOTFILES_DIR"

# 4. Local Config
log_info "Configuring local settings..."
dotgit config --local status.showUntrackedFiles no

# 5. RESET (Ensures we sync to what is on disk without overwriting)
log_info "Resetting index to match HEAD (Mixed Reset)..."
dotgit reset

log_success "Repository linked. No files were overwritten."

# ==============================================================================
# 5. SYNC & PUSH (SMART FILTERED SYNC)
# ==============================================================================

printf "\n${BOLD}--- Final Sync ---${NC}\n"

# 6. Status Check
log_info "Current Git Status:"
dotgit status --short

# 7. Add Files from List (With Error Protection)
if [[ -f "$DOTFILES_LIST" ]]; then
    log_info "Processing .git_dusky_list..."
    
    CLEAN_LIST=$(mktemp)
    
    # Filter files that exist on disk to prevent 'pathspec' errors
    grep -vE '^\s*#|^\s*$' "$DOTFILES_LIST" | while read -r file; do
        # Trim whitespace
        file=$(echo "$file" | xargs)
        
        if [[ -e "$file" ]]; then
            echo "$file" >> "$CLEAN_LIST"
        else
            log_warn "Skipping missing file: $file"
        fi
    done
    
    if [[ -s "$CLEAN_LIST" ]]; then
        log_info "Staging validated files..."
        dotgit add --pathspec-from-file="$CLEAN_LIST"
    else
        log_warn "No valid files found in list. Using standard update (-u)..."
        dotgit add -u
    fi
else
    log_warn ".git_dusky_list not found. Falling back to updating tracked files..."
    dotgit add -u
fi

# 8. Commit
if ! dotgit diff-index --quiet HEAD; then
    log_info "Committing changes..."
    dotgit commit -m "$COMMIT_MSG"
    log_success "Committed."
else
    log_info "Nothing to commit."
fi

# 9. Remote Setup
log_info "Ensuring remote origin..."
if dotgit remote | grep -q origin; then
    dotgit remote set-url origin "$REPO_URL"
else
    dotgit remote add origin "$REPO_URL"
fi

# 10. Push
CURRENT_BRANCH=$(dotgit symbolic-ref --short HEAD)
log_info "Pushing to $CURRENT_BRANCH..."
dotgit push -u origin "$CURRENT_BRANCH"

printf "\n${GREEN}${BOLD}Speedrun Complete.${NC}\n"
