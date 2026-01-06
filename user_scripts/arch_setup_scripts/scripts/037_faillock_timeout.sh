#!/usr/bin/env bash
# increase timout for wrong password attempts
# -----------------------------------------------------------------------------
# Description: Configures /etc/security/faillock.conf for Arch Linux
# Author:      DevOps Architect
# Context:     Arch / Hyprland / UWSM
# Standards:   Bash 5+, Strict Mode, Atomic Writes
# -----------------------------------------------------------------------------

# --- Strict Safety Mode ---
set -euo pipefail

# --- Presentation Constants ---
readonly C_RESET=$'\e[0m'
readonly C_INFO=$'\e[34m'    # Blue
readonly C_SUCCESS=$'\e[32m' # Green
readonly C_ERR=$'\e[31m'     # Red

# --- Logging Functions ---
log_info()    { printf "${C_INFO}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_SUCCESS}[OK]${C_RESET}   %s\n" "$1"; }
log_err()     { printf "${C_ERR}[ERR]${C_RESET}  %s\n" "$1" >&2; }

# --- Privilege Check (Self-Elevate) ---
if [[ "${EUID}" -ne 0 ]]; then
    log_info "Root privileges required. Elevating..."
    # Preserves the original script environment and arguments
    if command -v sudo &>/dev/null; then
        exec sudo "$0" "$@"
    else
        log_err "Sudo not found. Please run as root."
        exit 1
    fi
fi

# --- Main Logic ---
main() {
    local target_file="/etc/security/faillock.conf"
    local target_dir
    target_dir="$(dirname "${target_file}")"

    # Ensure directory exists (rare edge case in Arch, but safe practice)
    if [[ ! -d "${target_dir}" ]]; then
        log_info "Creating directory: ${target_dir}"
        mkdir -p "${target_dir}"
    fi

    log_info "Writing configuration to ${target_file}..."

    # Write content using quoted heredoc to prevent variable expansion.
    # This truncates the file if it exists (replaces content), or creates it.
    cat << 'EOF' > "${target_file}"
# Configuration for locking the user after multiple failed
# authentication attempts.
#
# The directory where the user files with the failure records are kept.
# The default is /var/run/faillock.
# dir = /var/run/faillock
#
# Will log the user name into the system log if the user is not found.
# Enabled if option is present.
# audit
#
# Don't print informative messages.
# Enabled if option is present.
# silent
#
# Don't log informative messages via syslog.
# Enabled if option is present.
# no_log_info
#
# Only track failed user authentications attempts for local users
# in /etc/passwd and ignore centralized (AD, IdM, LDAP, etc.) users.
# The `faillock` command will also no longer track user failed
# authentication attempts. Enabling this option will prevent a
# double-lockout scenario where a user is locked out locally and
# in the centralized mechanism.
# Enabled if option is present.
# local_users_only
#
# Deny access if the number of consecutive authentication failures
# for this user during the recent interval exceeds n tries.
# The default is 3.
deny = 6
#
# The length of the interval during which the consecutive
# authentication failures must happen for the user account
# lock out is <replaceable>n</replaceable> seconds.
# The default is 900 (15 minutes).
# fail_interval = 900
#
# The access will be re-enabled after n seconds after the lock out.
# The value 0 has the same meaning as value `never` - the access
# will not be re-enabled without resetting the faillock
# entries by the `faillock` command.
# The default is 600 (10 minutes).
unlock_time = 90
#
# Root account can become locked as well as regular accounts.
# Enabled if option is present.
# even_deny_root
#
# This option implies the `even_deny_root` option.
# Allow access after n seconds to root account after the
# account is locked. In case the option is not specified
# the value is the same as of the `unlock_time` option.
root_unlock_time = 300
#
# If a group name is specified with this option, members
# of the group will be handled by this module the same as
# the root account (the options `even_deny_root>` and
# `root_unlock_time` will apply to them.
# By default, the option is not set.
# admin_group = <admin_group_name>
EOF

    # Enforce strict permissions (Security best practice)
    # Owner: Root (RW), Group: Root (R), Others: (R)
    chmod 644 "${target_file}"
    chown 0:0 "${target_file}"

    log_success "Configuration applied successfully."
}

# --- Execute ---
# Trap cleanup is not required as we are not creating temporary files on disk.
main
