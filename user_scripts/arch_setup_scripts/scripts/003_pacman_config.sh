#!/usr/bin/env bash
# Atomic overwrite of /etc/pacman.conf for Arch/Hyprland systems
# -----------------------------------------------------------------------------
# Description: Atomic overwrite of /etc/pacman.conf for Arch/Hyprland systems
# Author:      DevOps/System Architect
# Target:      /etc/pacman.conf
# -----------------------------------------------------------------------------

# --- Strict Error Handling ---
set -euo pipefail

# --- Presentation Constants ---
readonly COLOR_INFO=$'\033[1;34m' # Bold Blue
readonly COLOR_OK=$'\033[1;32m'   # Bold Green
readonly COLOR_ERR=$'\033[1;31m'  # Bold Red
readonly COLOR_NC=$'\033[0m'      # No Color

# --- Helper Functions ---
log_info() { printf "${COLOR_INFO}[INFO]${COLOR_NC} %s\n" "$1"; }
log_ok() { printf "${COLOR_OK}[OK]${COLOR_NC}   %s\n" "$1"; }
log_err() { printf "${COLOR_ERR}[ERR]${COLOR_NC}  %s\n" "$1" >&2; }

# --- Cleanup Trap ---
# Ensures terminal colors are reset even on failure
cleanup() {
  printf "${COLOR_NC}"
}
trap cleanup EXIT

# --- Root Privilege Check (Self-Elevation) ---
# If not root, re-execute the script with sudo immediately.
if [[ "${EUID}" -ne 0 ]]; then
  log_info "Privilege escalation required for /etc/pacman.conf."
  log_info "Re-executing with sudo..."
  exec sudo "$0" "$@"
fi

# --- Main Logic ---
TARGET_FILE="/etc/pacman.conf"

log_info "Preparing to overwrite ${TARGET_FILE}..."

# Writing content using a quoted Here-Document ('EOF')
# This prevents variable expansion and handles special characters safely.
cat >"${TARGET_FILE}" <<'EOF'
# /etc/pacman.conf
# See the pacman.conf(5) manpage for option and repository directives
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
Color
ILoveCandy
VerbosePkgLists
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
ParallelDownloads = 5
DownloadUser = alpm

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

# NOTE: You must run `pacman-key --init` before first using pacman; the local
# keyring can then be populated with the keys of all official Arch Linux
# packagers with `pacman-key --populate archlinux`.

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture
#
# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[core-testing]
#Include = /etc/pacman.d/mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

#[extra-testing]
#Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs
EOF

# --- Validation ---
if [[ -f "${TARGET_FILE}" ]]; then
  log_ok "Configuration written successfully to ${TARGET_FILE}."
else
  log_err "Failed to write to ${TARGET_FILE}."
  exit 1
fi
