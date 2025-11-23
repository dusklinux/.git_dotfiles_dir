# =============================================================================
# ~/.zshrc - Zsh Configuration
#
# This configuration is structured for clarity and performance.
# Sections are ordered logically:
# 1. Environment Variables & Path
# 2. History Configuration
# 3. Completion System
# 4. Keybindings (Vi-Mode)
# 5. Aliases and Functions
# 6. Plugin & Prompt Initialization
# 7. Auto login INTO UWSM HYPRLAND WITH TTY1
# =============================================================================


# -----------------------------------------------------------------------------
# [1] ENVIRONMENT VARIABLES & PATH
# -----------------------------------------------------------------------------
# Set core applications and configure the system's search path for executables.
# These are fundamental for defining your work environment.

# Set the default text editor for command-line tools. Neovim is a wise choice.
export EDITOR='nvim'
# Set the default terminal emulator.
export TERMINAL='kitty'
# Set the default web browser.
#export BROWSER='firefox'

# --- OpenMP Performance Tuning ---
# Instructs OpenMP-aware applications to use a number of threads matching
# the CPU's hardware thread count (e.g., Intel i7-12700H has 20 threads).
# This does NOT affect shell performance itself.
export OMP_NUM_THREADS=$(nproc)

# --- Pyenv (Python Version Management) ---
# Initializes pyenv to manage multiple Python versions.

##	export PYENV_ROOT="$HOME/.pyenv"
##	export PATH="$PYENV_ROOT/bin:$PATH"
##	if command -v pyenv 1>/dev/null 2>&1; then
##	  eval "$(pyenv init --path)"
##	  eval "$(pyenv init -)"
##	fi

# Configure the path where Zsh looks for commands.
# Uncomment and modify if you have local binaries (e.g., in ~/.local/bin).
# export PATH="$HOME/.local/bin:$PATH"


# -----------------------------------------------------------------------------
# [2] HISTORY CONFIGURATION
# -----------------------------------------------------------------------------
# Configure how Zsh records and manages your command history. Robust history
# settings are crucial for an efficient workflow.

# Set the number of history lines to keep in memory during the session.
HISTSIZE=50000
# Set the number of history lines to save in the history file (~/.zsh_history).
SAVEHIST=25000
# Specify the location of the history file.
HISTFILE=~/.zsh_history

# Use `setopt` to fine-tune history behavior.
setopt APPEND_HISTORY          # Append new history entries instead of overwriting.
setopt INC_APPEND_HISTORY      # Write history to file immediately after command execution.
setopt SHARE_HISTORY           # Share history between all concurrent shell sessions.
setopt HIST_IGNORE_ALL_DUPS    # If a new command is a duplicate, remove the older entry.
setopt HIST_IGNORE_SPACE       # Do not save commands that start with a leading space.
setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks from each command line.
setopt HIST_FIND_NO_DUPS       # When searching, do not display duplicates of a command.


# -----------------------------------------------------------------------------
# [3] COMPLETION SYSTEM
# -----------------------------------------------------------------------------
# Configure Zsh's powerful tab-completion system.

# Initialize the completion system. The -U flag prevents re-initialization,
# and `compinit` generates the completion function cache.
autoload -U compinit && compinit

# Load the `colors` module for styling.
autoload -U colors && colors

# Style the completion menu.
# ':completion:*' is a pattern that applies to all completion widgets.
zstyle ':completion:*' menu select                 # Enable menu selection on the first Tab press.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colorize the completion menu using LS_COLORS.
zstyle ':completion:*:descriptions' format '%B%d%b'  # Format descriptions for clarity (bold).
zstyle ':completion:*' group-name ''               # Group completions by type without showing group names.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive matching.


# -----------------------------------------------------------------------------
# [4] KEYBINDINGS & SHELL OPTIONS
# -----------------------------------------------------------------------------
# Define keybindings and enable various shell options for a better user experience.

# --- Vi Mode Keybindings ---
# Enables the use of Vim-like keybindings in the shell for modal editing.
bindkey -v
# Set the timeout for ambiguous key sequences (e.g., after pressing ESC).
# A low value makes the transition to normal mode in Vi mode feel instantaneous.
export KEYTIMEOUT=1

# --- General Shell Options (`setopt`) ---
setopt INTERACTIVE_COMMENTS # Allow comments (like this one) in an interactive shell.
setopt GLOB_DOTS            # Include dotfiles (e.g., .config) in globbing results.
setopt EXTENDED_GLOB        # Enable extended globbing features (e.g., `^` for negation).
setopt NO_CASE_GLOB         # Perform case-insensitive globbing.
setopt AUTO_PUSHD           # Automatically push directories onto the directory stack.
setopt PUSHD_IGNORE_DUPS    # Don't push duplicate directories onto the stack.


# -----------------------------------------------------------------------------
# [5] ALIASES & FUNCTIONS
# -----------------------------------------------------------------------------
# Define shortcuts (aliases) and small scripts (functions) to reduce typing
# and streamline common tasks.

# --- Aliases ---

# alias ls='ls --color=auto' # Always use color for `ls`.
# alias la='ls -A'           # List all entries except for . and ..
# alias ll='ls -alF'         # List all files in long format.
# alias l='ls -CF'           # List entries by columns.

alias ls='eza'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#alias cat='bat'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# alias for git dotfiles bear repo
alias git_dotfiles='/usr/bin/git --git-dir=$HOME/.git_dotfiles_dir/ --work-tree=$HOME'

# alias for automatically adding the list of files to the staging area.
alias git_dotfiles_add_list='git_dotfiles add --pathspec-from-file=.git_dotfiles_list'

# YAZI
#change the current working directory when exiting Yazi

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# --- sysbench benchmark ---
alias run_sysbench='~/user_scripts/performance/sysbench_benchmark.sh'

#-- LM- Studio-- 
alias llm='/mnt/media/Documents/do_not_delete_linux/appimages/LM-Studio*'

# --- Functions ---
# Creates a directory and changes into it.
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Find the 20 largest files/directories in the current directory.
sort_size() {
  du -h -x -s -- * | sort -r -h | head -20
}

# for unlocking drive with the scripts with just drive <name of the drive> eg drive fast or drive media or drive browser
unlock () {
    ~/user_scripts/unlock_drive/unlock_$1.sh
}

# for locking drive with the scripts with just drive <name of the drive> eg drive fast or drive media or drive browser
lock () {
    ~/user_scripts/lock_drive/lock_$1.sh
}
# List installed Arch packages, sorted by installation date.
list_installed() {
  awk 'NR==FNR { if (/\[ALPM\] installed/) { ts = $1; gsub(/^\[|\]$/, "", ts); pkg = $4; if (!(pkg in fit)) fit[pkg] = ts; } next; } { if ($0 in fit) print fit[$0], $0; }' /var/log/pacman.log <(pacman -Qq) | sort -k1,1 | awk '{print $2}'
}

# -----------------------------------------------------------------------------
# [6] PLUGINS & PROMPT INITIALIZATION
# -----------------------------------------------------------------------------
# Load external plugins and initialize the shell prompt.
# IMPORTANT: The order of sourcing matters. Syntax highlighting should be last.

# --- Fuzzy Finder (fzf) ---
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# --- Starship Prompt ---
# Hand off prompt rendering to Starship for a powerful, customizable prompt.
# `eval` executes the output of `starship init zsh`.
eval "$(starship init zsh)"


# --- Zsh Syntax Highlighting ---
# This plugin provides real-time syntax highlighting for the command line.
# NOTE: This MUST be the last plugin sourced to function correctly.
if [[ -f "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# -----------------------------------------------------------------------------
# [7] Auto login INTO UWSM HYPRLAND WITH TTY1
# -----------------------------------------------------------------------------

# Check if we are on tty1 and no display server is running

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  if uwsm check may-start; then
    exec uwsm start hyprland.desktop
  fi
fi

# =============================================================================
# End of ~/.zshrc
# =============================================================================

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/dusk/.lmstudio/bin"
# End of LM Studio CLI section

