#!/bin/bash

# Script to set up a persistent vsftpd FTP server on Arch Linux.
# Author: Gemini
# Version: 1.1
# Changes in 1.1:
# - Removed 'utf8_filesystem=YES' from vsftpd.conf as it caused startup errors on some systems.
#
# Features:
# - Removes/disables other common FTP servers (proftpd, pure-ftpd).
# - Installs vsftpd and firewalld if not present.
# - Prompts for the folder to share.
# - Configures vsftpd for local user access, chrooted to the shared folder.
# - Prompts for users to allow FTP access.
# - Configures firewalld to allow FTP traffic (port 21 and passive ports).
# - Makes the FTP server persistent across reboots.
# - Includes error handling and verbosity.

# --- Configuration ---
FTP_PASSIVE_MIN_PORT=40000
FTP_PASSIVE_MAX_PORT=40100
VSFTPD_CONF_FILE="/etc/vsftpd.conf"
VSFTPD_USERLIST_FILE="/etc/vsftpd.userlist"
LOG_FILE="/var/log/setup_ftp_server.log" # Log file for this script's actions

# --- Helper Functions ---
log_message() {
    # Logs a message to both stdout and the log file.
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    # Logs an error message and exits the script.
    log_message "ERROR: $1"
    exit 1
}

# --- Main Script ---

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
  error_exit "This script must be run as root. Please use sudo."
fi

# Start logging for this script execution
echo -e "\n--- FTP Server Setup Started on $(date) ---" >> "$LOG_FILE"
log_message "FTP Server Setup Script Initialized."

# 1. Dependency Installation Function
install_dependencies() {
    log_message "Step 1: Checking and installing dependencies..."
    
    # Update package database (important before installing packages)
    log_message "Updating package database (pacman -Syu)..."
    if ! pacman -Syu --noconfirm >> "$LOG_FILE" 2>&1; then
        # Don't exit if only Syu fails but packages might still install
        log_message "Warning: 'pacman -Syu' failed. Proceeding with package installation attempt. Check $LOG_FILE for details."
    else
        log_message "Package database updated successfully."
    fi

    # Install vsftpd
    if ! pacman -Qs vsftpd > /dev/null; then
        log_message "vsftpd not found. Installing vsftpd..."
        if ! pacman -S --noconfirm vsftpd >> "$LOG_FILE" 2>&1; then
            error_exit "Failed to install vsftpd. Check $LOG_FILE for details."
        fi
        log_message "vsftpd installed successfully."
    else
        log_message "vsftpd is already installed."
    fi

    # Install firewalld (if not already installed) and ensure it's running
    if ! pacman -Qs firewalld > /dev/null; then
        log_message "firewalld not found. Installing firewalld..."
        if ! pacman -S --noconfirm firewalld >> "$LOG_FILE" 2>&1; then
            error_exit "Failed to install firewalld. Check $LOG_FILE for details."
        fi
        log_message "firewalld installed successfully."
        log_message "Enabling and starting firewalld service..."
        if ! systemctl enable --now firewalld >> "$LOG_FILE" 2>&1; then
            error_exit "Failed to enable and start firewalld. Check $LOG_FILE for details."
        fi
        log_message "firewalld enabled and started."
    else
        log_message "firewalld is already installed."
        # Ensure firewalld is active if it's installed
        if ! systemctl is-active --quiet firewalld; then
            log_message "firewalld is installed but not active. Starting and enabling firewalld..."
            if ! systemctl enable --now firewalld >> "$LOG_FILE" 2>&1; then
                error_exit "Failed to enable and start firewalld. Check $LOG_FILE for details."
            fi
            log_message "firewalld enabled and started."
        else
            log_message "firewalld is active."
        fi
    fi
    log_message "Dependency check and installation complete."
}

# 2. Stop and Disable Other Common FTP Servers
handle_other_ftp_servers() {
    log_message "Step 2: Checking for and disabling other common FTP servers..."
    local servers_to_check=("proftpd" "pure-ftpd") # Add other server names if needed
    
    for server_name in "${servers_to_check[@]}"; do
        # Check if the package is installed
        if pacman -Qs "$server_name" > /dev/null; then
            log_message "$server_name package is installed. Attempting to stop and disable its service."
            # Check if the service exists and is active
            if systemctl list-units --full -all | grep -Fq "$server_name.service"; then
                if systemctl is-active --quiet "$server_name.service"; then
                    if systemctl stop "$server_name.service" >> "$LOG_FILE" 2>&1; then
                        log_message "$server_name.service stopped."
                    else
                        log_message "Warning: Failed to stop $server_name.service. It might not be running or an error occurred."
                    fi
                fi
                # Check if the service is enabled
                if systemctl is-enabled --quiet "$server_name.service"; then
                    if systemctl disable "$server_name.service" >> "$LOG_FILE" 2>&1; then
                        log_message "$server_name.service disabled."
                    else
                        log_message "Warning: Failed to disable $server_name.service."
                    fi
                fi
            else
                 log_message "Service file for $server_name not found, no service actions taken."
            fi
        else
            log_message "$server_name package is not installed."
        fi
    done

    # Ensure vsftpd itself is stopped before major reconfigurations, if it was already running
    if systemctl list-units --full -all | grep -Fq "vsftpd.service"; then
        if systemctl is-active --quiet vsftpd.service; then
            log_message "Stopping existing vsftpd service before reconfiguration..."
            if ! systemctl stop vsftpd.service >> "$LOG_FILE" 2>&1; then
                log_message "Warning: Failed to stop existing vsftpd service. This might be okay if it wasn't fully configured."
            else
                log_message "Existing vsftpd service stopped."
            fi
        fi
    fi
    log_message "Handling of other FTP servers complete."
}

# 3. User Input for Shared Folder, Write Access, and Allowed Users
get_user_inputs() {
    log_message "Step 3: Gathering user preferences for FTP setup..."
    
    # Get shared directory path
    while true; do
        read -r -p "Enter the full path to the folder you want to share via FTP: " SHARED_FTP_DIR_INPUT
        if [[ -z "$SHARED_FTP_DIR_INPUT" ]]; then
            echo "Path cannot be empty. Please try again."
            continue
        fi
        
        # Attempt to resolve to an absolute path. -m allows non-existent paths for now.
        SHARED_FTP_DIR=$(realpath -m "$SHARED_FTP_DIR_INPUT")
        
        if [[ ! -d "$SHARED_FTP_DIR" ]]; then
            read -r -p "Directory '$SHARED_FTP_DIR' does not exist. Do you want to create it now? (y/N): " create_dir
            if [[ "$create_dir" =~ ^[Yy]$ ]]; then
                if mkdir -p "$SHARED_FTP_DIR"; then
                    log_message "Created directory: $SHARED_FTP_DIR"
                    # Set basic permissions (owner rwx, group rx, other rx).
                    # Ownership will be root:root by default.
                    # The user will be reminded to adjust permissions/ownership later.
                    chmod 755 "$SHARED_FTP_DIR"
                    log_message "Set permissions 755 for $SHARED_FTP_DIR. You may need to adjust ownership/permissions for specific FTP users to write."
                    break 
                else
                    # If mkdir fails, loop back to ask for path again.
                    echo "Error: Failed to create directory '$SHARED_FTP_DIR'. Please check permissions or choose a different path."
                    log_message "Failed to create directory '$SHARED_FTP_DIR'."
                    continue 
                fi
            else
                echo "Please enter a path to an existing directory or agree to create it."
                continue # Go back to asking for the path
            fi
        else
            log_message "Using existing directory: $SHARED_FTP_DIR"
            break 
        fi
    done

    # Get write access preference
    while true; do
        read -r -p "Allow FTP users to write to the shared folder (upload, delete, modify files)? (y/N): " allow_write_input
        if [[ "$allow_write_input" =~ ^[Yy]$ ]]; then
            WRITE_ENABLE="YES"
            log_message "Write access will be enabled for the shared folder."
            break
        elif [[ "$allow_write_input" =~ ^[Nn]$ ]]; then
            WRITE_ENABLE="NO"
            log_message "Write access will be disabled (read-only) for the shared folder."
            break
        else
            echo "Invalid input. Please enter 'y' or 'n'."
        fi
    done

    # Get users for FTP access
    log_message "Configuring user access list for FTP."
    # Create or truncate the userlist file
    echo "# vsftpd userlist - Created by setup_ftp_server.sh" > "$VSFTPD_USERLIST_FILE"
    echo "# Users listed here are allowed to log in if userlist_deny=NO in $VSFTPD_CONF_FILE" >> "$VSFTPD_USERLIST_FILE"
    log_message "Initialized $VSFTPD_USERLIST_FILE. Please add system users you want to grant FTP access."

    local user_added_flag=0
    while true; do
        read -r -p "Enter a system username to allow FTP access (or press Enter to finish adding users): " ftp_user
        if [[ -z "$ftp_user" ]]; then
            if [[ $user_added_flag -eq 0 ]]; then
                echo "Warning: No users have been added to the FTP access list."
                echo "If no users are listed in $VSFTPD_USERLIST_FILE, no one will be able to log in."
                read -r -p "Are you sure you want to continue without adding any users? (y/N): " confirm_no_users
                if [[ "$confirm_no_users" =~ ^[Yy]$ ]]; then
                    log_message "Warning: Proceeding without any users in $VSFTPD_USERLIST_FILE. FTP login will likely fail for all users."
                    break
                else
                    continue # Prompt again for a username
                fi
            else
                log_message "Finished adding users to the FTP access list."
                break # Exit loop if input is empty and at least one user was added or confirmed no users
            fi
        fi

        # Check if the user exists on the system
        if id "$ftp_user" &>/dev/null; then
            if grep -Fxq "$ftp_user" "$VSFTPD_USERLIST_FILE"; then
                log_message "User '$ftp_user' is already in the list. Not adding again."
            else
                echo "$ftp_user" >> "$VSFTPD_USERLIST_FILE"
                log_message "Added user '$ftp_user' to $VSFTPD_USERLIST_FILE."
                user_added_flag=1
            fi
        else
            echo "Error: System user '$ftp_user' does not exist. Please enter a valid, existing username."
        fi
    done
    log_message "User input gathering complete."
}


# 4. Configure vsftpd Server
configure_vsftpd() {
    log_message "Step 4: Configuring vsftpd server ($VSFTPD_CONF_FILE)..."
    
    # Backup existing vsftpd.conf if it exists
    if [[ -f "$VSFTPD_CONF_FILE" ]]; then
        local backup_file="$VSFTPD_CONF_FILE.bak.$(date +%Y%m%d-%H%M%S)"
        cp "$VSFTPD_CONF_FILE" "$backup_file"
        log_message "Backed up existing $VSFTPD_CONF_FILE to $backup_file"
    fi

    # Create new vsftpd.conf using a heredoc
    # Variables $WRITE_ENABLE, $SHARED_FTP_DIR, $VSFTPD_USERLIST_FILE, 
    # $FTP_PASSIVE_MIN_PORT, $FTP_PASSIVE_MAX_PORT are expanded here.
    cat > "$VSFTPD_CONF_FILE" <<EOF
# $VSFTPD_CONF_FILE
# Configuration for vsftpd, managed by setup_ftp_server.sh
# Date: $(date)

# --- Access Control ---
# Allow anonymous FTP? (NO for security)
anonymous_enable=NO
# Allow local users to log in? (YES)
local_enable=YES
# Enable any form of write commands? (YES/NO based on user input)
write_enable=${WRITE_ENABLE}

# --- Chroot and Directory Settings ---
# Restrict local users to their chroot jail after login.
chroot_local_user=YES
# If chroot_local_user is YES, and the chroot directory (local_root) is writable by the user,
# this option must be YES. This is a common requirement.
allow_writeable_chroot=YES
# Specify the directory to which local users will be chrooted.
# This becomes their FTP root directory.
local_root=${SHARED_FTP_DIR}

# --- User Authentication and Listing ---
# Enable the use of a userlist file.
userlist_enable=YES
# Path to the userlist file.
userlist_file=${VSFTPD_USERLIST_FILE}
# When userlist_deny=NO, the userlist_file acts as an allow list.
# Only users explicitly listed in userlist_file can log in.
userlist_deny=NO

# --- Logging ---
# Enable transfer logging.
xferlog_enable=YES
# Use standard log file format.
xferlog_std_format=YES
# Path to the vsftpd log file.
xferlog_file=/var/log/vsftpd.log
# Log all FTP protocol commands and responses (can be verbose, useful for debugging).
log_ftp_protocol=YES

# --- Connection Handling ---
# Standalone mode. listen=NO is needed if listen_ipv6=YES for dual-stack.
listen=NO
# Listen on IPv6 (implies IPv4 as well on modern systems).
listen_ipv6=YES
# PAM service name for authentication.
pam_service_name=vsftpd

# --- Passive Mode (Essential for NAT/Firewalls) ---
# Enable passive mode.
pasv_enable=YES
# Minimum port for passive connections.
pasv_min_port=${FTP_PASSIVE_MIN_PORT}
# Maximum port for passive connections.
pasv_max_port=${FTP_PASSIVE_MAX_PORT}
# You can optionally set pasv_address=YOUR_EXTERNAL_IP if behind NAT,
# but for a local laptop, this is usually not needed.

# --- Banners and Messages ---
# Display a login banner.
ftpd_banner=Welcome to this Arch Linux FTP service.

# --- Performance and Security Tweaks ---
# Use sendfile() system call for transferring files (efficient).
use_sendfile=YES
# Ensure PORT transfer connections originate from port 20 (ftp-data) on the server.
connect_from_port_20=YES
# Optional: Hide user and group information in directory listings (shows 'ftp ftp').
# hide_ids=YES

# --- Filesystem Encoding ---
# The utf8_filesystem option was removed as it caused errors on some systems.
# Modern systems generally handle UTF-8 well by default.
# utf8_filesystem=YES 

# --- End of vsftpd.conf ---
EOF

    log_message "$VSFTPD_CONF_FILE configured successfully."
    log_message "Shared FTP root directory set to: $SHARED_FTP_DIR"
    log_message "Write access for FTP users: $WRITE_ENABLE"

    # Final check and reminder for shared directory permissions
    if [ ! -d "$SHARED_FTP_DIR" ]; then
        log_message "CRITICAL WARNING: Shared directory $SHARED_FTP_DIR does not exist even after attempting creation. vsftpd will fail."
        error_exit "Shared directory creation/validation failed."
    fi
    log_message "Reminder: Ensure users listed in $VSFTPD_USERLIST_FILE have appropriate read/write filesystem permissions on $SHARED_FTP_DIR and its contents."
    log_message "vsftpd configuration complete."
}

# 5. Configure Firewall (firewalld)
configure_firewall() {
    log_message "Step 5: Configuring firewall (firewalld) for FTP..."
    
    if ! systemctl is-active --quiet firewalld; then
        log_message "Warning: firewalld is not active. Attempting to start it..."
        if ! systemctl start firewalld >> "$LOG_FILE" 2>&1; then
             error_exit "firewalld is not active and failed to start. Cannot configure firewall rules."
        fi
        log_message "firewalld started."
    fi

    # Add FTP service (port 21/tcp) permanently
    log_message "Allowing FTP control port (21/tcp) via firewalld..."
    if ! firewall-cmd --permanent --add-service=ftp >> "$LOG_FILE" 2>&1; then
        error_exit "Failed to add FTP service (port 21) to firewalld. Check $LOG_FILE."
    fi

    # Add passive port range permanently
    local passive_port_range="${FTP_PASSIVE_MIN_PORT}-${FTP_PASSIVE_MAX_PORT}/tcp"
    log_message "Allowing FTP passive port range (${passive_port_range}) via firewalld..."
    if ! firewall-cmd --permanent --add-port="${passive_port_range}" >> "$LOG_FILE" 2>&1; then
        error_exit "Failed to add passive port range ${passive_port_range} to firewalld. Check $LOG_FILE."
    fi

    # Reload firewalld to apply permanent rules
    log_message "Reloading firewalld to apply new rules..."
    if ! firewall-cmd --reload >> "$LOG_FILE" 2>&1; then
        # A reload failure can sometimes be transient or due to other issues.
        # We'll log it as a warning but continue, as rules might still be partially applied or apply on next reboot.
        log_message "Warning: 'firewall-cmd --reload' failed. The firewall rules might not be immediately active. A reboot or manual reload might be needed. Check $LOG_FILE."
    else
        log_message "Firewall reloaded successfully. Rules are active."
    fi
    log_message "Firewall configuration for FTP complete."
}

# 6. Start and Enable vsftpd Service for Persistence
start_enable_vsftpd() {
    log_message "Step 6: Starting and enabling vsftpd service..."
    
    # Reload systemd daemon, in case any unit files changed (though not directly by this script for vsftpd)
    log_message "Reloading systemd daemon configuration..."
    if ! systemctl daemon-reload >> "$LOG_FILE" 2>&1; then
        log_message "Warning: 'systemctl daemon-reload' failed. This is usually not critical."
    fi

    # Restart vsftpd service to apply new configuration
    log_message "Restarting vsftpd service..."
    if ! systemctl restart vsftpd.service >> "$LOG_FILE" 2>&1; then
        # Provide detailed error information if restart fails
        log_message "ERROR: Failed to restart vsftpd service."
        log_message "Check vsftpd status with: systemctl status vsftpd.service"
        log_message "Check vsftpd logs with: journalctl -u vsftpd.service"
        log_message "Also check vsftpd's own log: /var/log/vsftpd.log"
        log_message "And this script's log: $LOG_FILE"
        error_exit "vsftpd service could not be restarted. Please check logs and configuration."
    fi

    # Enable vsftpd service to start automatically on boot
    log_message "Enabling vsftpd service to start on boot..."
    if ! systemctl enable vsftpd.service >> "$LOG_FILE" 2>&1; then
        error_exit "Failed to enable vsftpd service for boot start. Check $LOG_FILE."
    fi
    
    log_message "vsftpd service has been restarted and enabled for boot."
}

# --- Execute Main Logic ---
# Each function includes logging and error handling.
install_dependencies
handle_other_ftp_servers
get_user_inputs # This function defines SHARED_FTP_DIR and WRITE_ENABLE globally for the script
configure_vsftpd
configure_firewall
start_enable_vsftpd

# 7. Final Instructions and Summary
log_message "Step 7: FTP Server setup process completed!"
echo ""
echo "---------------------------------------------------------------------"
echo " Arch Linux FTP Server Setup Summary"
echo "---------------------------------------------------------------------"
echo "Shared Folder (FTP Root): $SHARED_FTP_DIR"
echo "Write Access for FTP Users: $WRITE_ENABLE"
echo ""
echo "Allowed FTP Users (from $VSFTPD_USERLIST_FILE):"
if grep -qvE '^#|^$' "$VSFTPD_USERLIST_FILE"; then
    cat "$VSFTPD_USERLIST_FILE" | grep -vE '^#|^$' | sed 's_^_  - _'
else
    echo "  - No users were added to the allow list. FTP login will likely fail."
fi
echo ""
echo "Firewall Configuration (firewalld):"
echo "  - FTP Control Port (21/tcp): Allowed"
echo "  - FTP Passive Ports (${FTP_PASSIVE_MIN_PORT}-${FTP_PASSIVE_MAX_PORT}/tcp): Allowed"
echo ""
echo "Service Status:"
echo "  - vsftpd service is now running."
echo "  - vsftpd service is enabled to start on system boot."
echo ""
echo "Log Files:"
echo "  - This script's log: $LOG_FILE"
echo "  - vsftpd service log: /var/log/vsftpd.log (and 'journalctl -u vsftpd.service')"
echo ""
echo "How to Connect to Your FTP Server:"
# Attempt to find non-loopback IPv4 addresses
IP_ADDRESSES=$(ip -4 addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1')
if [[ -n "$IP_ADDRESSES" ]]; then
    echo "  You can likely connect using one of these addresses:"
    for ip_addr in $IP_ADDRESSES; do
        echo "    ftp://$ip_addr"
    done
else
    echo "  Could not automatically determine your laptop's IP address."
    echo "  Use the command 'ip addr' in your terminal to find your IP address(es)."
    echo "  Then connect using: ftp://<your_laptop_ip_address>"
fi
echo "  Use one of the allowed usernames and their corresponding system password."
echo ""
echo "---------------------------------------------------------------------"
echo " IMPORTANT NOTES & TROUBLESHOOTING:"
echo "---------------------------------------------------------------------"
echo "1. File Permissions: For users to read or write files in '$SHARED_FTP_DIR',"
echo "   they must have the necessary Linux file system permissions on that directory"
echo "   and its contents. This script sets basic permissions if it creates the"
echo "   directory, but you may need to adjust ownership (e.g., 'sudo chown user:group \"$SHARED_FTP_DIR\"')"
echo "   and permissions (e.g., 'sudo chmod ug+rw \"$SHARED_FTP_DIR\"') to match your needs."
echo ""
echo "2. User Passwords: FTP users authenticate with their normal system account passwords."
echo ""
echo "3. Testing: Test connecting from another device on your network or locally using an FTP client."
echo "   (e.g., 'ftp localhost' or 'ftp <your_ip_address>')."
echo ""
echo "4. Issues: If you encounter problems:"
echo "   - Check 'systemctl status vsftpd.service'"
echo "   - Review vsftpd logs: 'journalctl -u vsftpd.service' and '/var/log/vsftpd.log'"
echo "   - Review this script's log: '$LOG_FILE'"
echo "   - Verify firewall status: 'sudo firewall-cmd --list-all'"
echo "   - Ensure the $VSFTPD_USERLIST_FILE contains the correct usernames."
echo "---------------------------------------------------------------------"

exit 0
