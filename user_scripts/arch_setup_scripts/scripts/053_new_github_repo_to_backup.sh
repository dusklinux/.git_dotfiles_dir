#!/usr/bin/env bash

# ==============================================================================
# ARCH LINUX DOTFILES CREATOR (FRESH UPLOAD - FINAL FIX)
# Context: Hyprland / UWSM / Bash 5+
# Fixes: 
#   1. Forces execution from $HOME to fix 'pathspec' errors.
#   2. Validates files exist before adding to prevent crash.
#   3. Supports interactive SSH passphrases.
# ==============================================================================

# 1. STRICT SAFETY
set -euo pipefail
IFS=$'\n\t'

# 2. CONSTANTS
readonly DEFAULT_REPO_NAME="dusky"
readonly LOCAL_REPO_PATH="$HOME/$DEFAULT_REPO_NAME"
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

# The Git Wrapper
dotgit() {
    /usr/bin/git --git-dir="$LOCAL_REPO_PATH" --work-tree="$HOME" "$@"
}

cleanup() {
    if [[ -n "${SCRIPT_SSH_AGENT_PID:-}" ]]; then
        kill "$SCRIPT_SSH_AGENT_PID" >/dev/null 2>&1 || true
    fi
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
# 1. INPUT GATHERING
# ==============================================================================

clear
printf "${BOLD}Arch Linux Dotfiles Repository Creator${NC}\n"
printf "This script initializes a NEW bare repository and pushes it to GitHub.\n\n"

# --- NEW CONDITIONAL LOGIC START ---

# Q1: Do you want to backup?
read -r -p "Do you want to backup your configs to a git repo? (y/N): " WANT_BACKUP
if [[ ! "$WANT_BACKUP" =~ ^[yY] ]]; then
    printf "\n"
    log_info "Okay, you've chosen to not backup your files to github."
    exit 0
fi

printf "\n"

# Q2: Do you already have a repo?
read -r -p "Do you already have an existing git repo? (y/N): " HAS_REPO
if [[ "$HAS_REPO" =~ ^[yY] ]]; then
    printf "\n"
    log_success "Great, please relink to the github repo with the next script."
    exit 0
fi

printf "\n"
# --- NEW CONDITIONAL LOGIC END ---

ask() {
    local prompt="$1"
    local desc="$2"
    local var_name="$3"
    local input
    
    printf "${CYAN}%s${NC}\n" "$prompt"
    printf "   %s\n" "$desc"
    while [[ -z "${input:-}" ]]; do
        read -r -p "   > " input
    done
    eval "$var_name=\"$input\""
    printf "\n"
}

ask "1. Git User Name" \
    "The name for your commits (e.g., 'any_name')." \
    GIT_NAME

ask "2. Git Email Address" \
    "The email linked to GitHub (for SSH key generation)." \
    GIT_EMAIL

ask "3. GitHub Username" \
    "Your GitHub username (e.g., 'your_actual_github_name')." \
    GH_USERNAME

printf "${CYAN}4. Repository Name${NC}\n"
printf "   The name of the repository on GitHub.\n"
read -r -p "   > [Default: $DEFAULT_REPO_NAME]: " INPUT_REPO_NAME
REPO_NAME="${INPUT_REPO_NAME:-$DEFAULT_REPO_NAME}"
printf "\n"

ask "5. Initial Commit Message" \
    "Message for the first commit (e.g., 'Initial dotfiles upload')." \
    COMMIT_MSG

REPO_URL="git@github.com:${GH_USERNAME}/${REPO_NAME}.git"

printf "${BOLD}Configuration Summary:${NC}\n"
printf "  User:       $GIT_NAME <$GIT_EMAIL>\n"
printf "  Target URL: $REPO_URL\n"
printf "  Local Path: $LOCAL_REPO_PATH\n"

read -r -p "Proceed with creation? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[yY] ]] || log_fatal "Aborted by user."

# ==============================================================================
# 2. LOCAL REPO INITIALIZATION
# ==============================================================================

printf "\n${BOLD}--- Phase 1: Local Setup ---${NC}\n"

# 1. Delete existing repo
if [[ -d "$LOCAL_REPO_PATH" ]]; then
    log_warn "Removing existing local bare repository..."
    rm -rf "$LOCAL_REPO_PATH"
fi

# 2. Global Config
log_info "Configuring global git settings..."
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

# 3. Init Bare Repo
log_info "Initializing bare repository..."
git init --bare "$LOCAL_REPO_PATH"

# 4. Local Config
log_info "Configuring local repository settings..."
dotgit config --local status.showUntrackedFiles no

# 5. SMART ADD (Filtered List)
if [[ -f "$DOTFILES_LIST" ]]; then
    log_info "Processing .git_dusky_list..."
    
    CLEAN_LIST=$(mktemp)
    
    # Filter files that exist on disk to prevent 'pathspec' errors
    grep -vE '^\s*#|^\s*$' "$DOTFILES_LIST" | while read -r file; do
        # Trim whitespace/CRLF using xargs
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
        log_warn "No valid files found in list. Adding script as placeholder."
        dotgit add "$0"
    fi
else
    log_warn "No .git_dusky_list found! Adding script as placeholder."
    dotgit add "$0"
fi

# 6. Status & Commit
log_info "Committing changes..."
dotgit commit -m "$COMMIT_MSG"

log_success "Local repository created and committed."

# ==============================================================================
# 3. REMOTE PREPARATION
# ==============================================================================

printf "\n${BOLD}--- Phase 2: GitHub Preparation ---${NC}\n"
printf "${YELLOW}IMPORTANT:${NC} You must now create an ${BOLD}EMPTY${NC} repository on GitHub.\n"
printf "1. Go to https://github.com/new\n"
printf "2. Repository name: ${BOLD}${REPO_NAME}${NC}\n"
printf "3. ${RED}DO NOT${NC} initialize with README, license, or .gitignore.\n"
printf "4. Click 'Create repository'.\n\n"

read -r -p "Press [Enter] once the EMPTY repository is created..."

# ==============================================================================
# 4. SSH KEY SETUP
# ==============================================================================

printf "\n${BOLD}--- Phase 3: SSH Security ---${NC}\n"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -f "$SSH_KEY_PATH" ]]; then
    log_warn "SSH key exists at $SSH_KEY_PATH"
    read -r -p "   Overwrite? (y/N): " OW
    if [[ "$OW" =~ ^[yY] ]]; then
        rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
        # Interactive passphrase
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH"
        log_success "New key generated."
    else
        log_info "Using existing key."
    fi
else
    # Interactive passphrase
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH"
    log_success "Key generated."
fi

eval "$(ssh-agent -s)" >/dev/null
SCRIPT_SSH_AGENT_PID="$SSH_AGENT_PID"

log_info "Adding SSH key to agent..."
if ! ssh-add "$SSH_KEY_PATH" 2>/dev/null; then
    log_info "Please enter your SSH key passphrase:"
    ssh-add "$SSH_KEY_PATH"
fi

printf "\n${YELLOW}${BOLD}ACTION REQUIRED:${NC} Add this key to GitHub:\n"
printf "1. Go to https://github.com/settings/keys\n"
printf "2. Click 'New SSH Key'\n"
printf "3. Paste the key below:\n"
printf "%s\n" "----------------------------------------------------------------"
cat "$SSH_KEY_PATH.pub"
printf "%s\n" "----------------------------------------------------------------"
read -r -p "Press [Enter] once you have added the key to GitHub..."

# ==============================================================================
# 5. REMOTE LINKING & PUSH
# ==============================================================================

printf "\n${BOLD}--- Phase 4: Linking & Push ---${NC}\n"

log_info "Adding remote origin..."
if dotgit remote | grep -q "origin"; then
    dotgit remote set-url origin "$REPO_URL"
else
    dotgit remote add origin "$REPO_URL"
fi

log_info "Testing SSH connection..."
set +e
ssh -T -o StrictHostKeyChecking=accept-new git@github.com >/dev/null 2>&1
SSH_CODE=$?
set -e

if [[ $SSH_CODE -eq 1 ]]; then
    log_success "Authentication successful."
else
    log_fatal "SSH authentication failed. Did you add the key?"
fi

log_info "Renaming branch to 'main'..."
dotgit branch -m main

log_info "Pushing to GitHub..."
if dotgit push -u origin main; then
    printf "\n${GREEN}${BOLD}Repository Created and Synced Successfully!${NC}\n"
else
    log_fatal "Push failed. Did you create an EMPTY repository on GitHub?"
fi
