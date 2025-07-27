#!/bin/bash

# Script to install asusctl and rog-control-center on Fedora
# Recommended for ASUS TUF F15 laptops

# --- Configuration ---
# COPR repository for asus-linux project
ASUS_COPR_REPO="lukenukem/asus-linux"

# --- Safety Checks ---
# Exit immediately if a command exits with a non-zero status.
set -e

# Check if running as root, prompt if not
if [ "$(id -u)" -ne 0 ]; then
  echo "This script needs to be run with root privileges."
  echo "Please run it using 'sudo bash $0'"
  exit 1
fi

echo "Starting asusctl installation..."

# --- Dependency Installation ---
echo "Updating package repository information..."
dnf check-update || echo "Proceeding despite check-update issues..." # Continue even if some repos fail temporarily

echo "Installing necessary dependencies (dnf-plugins-core for COPR)..."
dnf install -y dnf-plugins-core

# --- Enable COPR Repository ---
echo "Enabling the '$ASUS_COPR_REPO' COPR repository..."
# Check if repo is already enabled
if ! dnf copr list --enabled | grep -q "$ASUS_COPR_REPO"; then
    dnf copr enable -y "$ASUS_COPR_REPO"
    echo "COPR repository enabled."
else
    echo "COPR repository '$ASUS_COPR_REPO' is already enabled."
fi

# --- Installation ---
echo "Installing asusctl and rog-control-center..."
# Install the main service and the GUI
# Use --refresh flag to ensure we get the latest package list from the newly enabled COPR
dnf install --refresh -y asusctl rog-control-center

# --- Service Management ---
echo "Enabling and starting the asusd service..."
systemctl enable asusd.service
systemctl start asusd.service

# Check service status
echo "Checking asusd service status..."
if systemctl is-active --quiet asusd.service; then
    echo "asusd service is active and running."
else
    echo "WARNING: asusd service failed to start. Check logs with 'journalctl -u asusd.service'" >&2
fi

# --- Final Instructions ---
echo ""
echo "-----------------------------------------------------"
echo " Installation Complete!"
echo "-----------------------------------------------------"
echo ""
echo "What was installed:"
echo "  - asusctl: Command-line tool and background service (asusd)."
echo "  - rog-control-center: Graphical user interface."
echo ""
echo "How to use:"
echo "  - Search for 'ROG Control Center' in your Activities overview to launch the GUI."
echo "  - Use 'asusctl --help' in the terminal for command-line options."
echo "  - Fan profiles can often be controlled via the GUI or system power profiles (e.g., Performance, Balanced, Quiet) in GNOME Settings."
echo ""
echo "Rebooting your system is recommended to ensure all components are loaded correctly."
echo "-----------------------------------------------------"

exit 0

