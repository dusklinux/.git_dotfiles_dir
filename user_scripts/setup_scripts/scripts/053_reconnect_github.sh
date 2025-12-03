#!/usr/bin/env bash

# ==============================================================================
# ARCH LINUX DOTFILES SYNC (MANUAL SPEEDRUN REPLICA)
# Context: Hyprland / UWSM / Bash 5+
# Logic: Ask Intent -> Clone Bare -> Reset -> Sync (NO CHECKOUT/OVERWRITE)
# ==============================================================================

# 1. STRICT SAFETY
set -euo pipefail
IFS=$'\n\t'

# 2. CONSTANTS
readonly DOTFILES_DIR="$HOME/.git_dotfiles_dir"
readonly SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
readonly SSH_DIR="$HOME/.ssh"
readonly REQUIRED_CMDS=(git ssh ssh-keygen ssh-agent grep)

# 3. VISUALS
readonly BOLD='\033[1m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC}   %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERR]${NC}  %s\n" "$*" >&2; }
log_fatal()   { log_error "$*"; exit 1; }

# The Git Wrapper (Simulates your git_dotfiles alias)
dotgit() {
    /usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

cleanup() {
    if [[ -n "${SCRIPT_SSH_AGENT_PID:-}" ]]; then
        kill "$SCRIPT_SSH_AGENT_PID" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# ==============================================================================
# PRE-FLIGHT DEPENDENCY CHECK
# ==============================================================================

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
    printf "You can always create a GitHub bare repo by following the:\n"
    printf "${CYAN}'+ Speedrun New Fresh Repo Upload'${NC} obsidian note.\n\n"
    log_success "Exiting successfully."
    exit 0
fi

# ==============================================================================
# 2. INPUT GATHERING (Only runs if user said YES above)
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
ask "Git User Name (e.g., 'John Doe')" GIT_NAME
ask "Git Email (e.g., 'me@arch.linux')" GIT_EMAIL

printf "\n${CYAN}2. Repository${NC}\n"
ask "GitHub Username (e.g., 'torvalds')" GH_USERNAME
printf "   ${YELLOW}Repo Name:${NC} We assume '.git_dotfiles_dir'.\n"

printf "\n${CYAN}3. Commit${NC}\n"
ask "Initial Commit Message" COMMIT_MSG

REPO_URL="git@github.com:${GH_USERNAME}/.git_dotfiles_dir.git"

printf "\n${BOLD}Review Configuration:${NC}\n"
printf "  User:   $GIT_NAME <$GIT_EMAIL>\n"
printf "  Repo:   $REPO_URL\n"
read -r -p "Proceed? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[yY] ]] || log_fatal "Aborted by user."

# ==============================================================================
# 3. SSH SETUP
# ==============================================================================

printf "\n${BOLD}--- SSH Configuration ---${NC}\n"

if [[ ! -d "$SSH_DIR" ]]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

if [[ -f "$SSH_KEY_PATH" ]]; then
    log_warn "SSH key exists at $SSH_KEY_PATH"
    read -r -p "   Overwrite? (y/N): " OW
    if [[ "$OW" =~ ^[yY] ]]; then
        rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N "" -q
        log_success "New key generated."
    else
        log_info "Using existing key."
    fi
else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N "" -q
    log_success "Key generated."
fi

eval "$(ssh-agent -s)" >/dev/null
SCRIPT_SSH_AGENT_PID="$SSH_AGENT_PID"

if ! ssh-add "$SSH_KEY_PATH" 2>/dev/null; then
    log_warn "Automatic add failed (Passphrase?). Entering interactive mode:"
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
# 5. SYNC & PUSH
# ==============================================================================

printf "\n${BOLD}--- Final Sync ---${NC}\n"

# 6. Status Check
log_info "Current Git Status:"
dotgit status --short

# 7. Add Modified Files
log_info "Staging modified files (git add -u)..."
dotgit add -u

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
