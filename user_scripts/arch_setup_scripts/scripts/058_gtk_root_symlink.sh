#!/usr/bin/env bash
set -euo pipefail

# 1. Ensure we are root
if [[ $EUID -ne 0 ]]; then
   echo "Escalating to root..."
   exec sudo "$0" "$@"
fi

# 2. Get the Real User and Home Directory
REAL_USER="${SUDO_USER:-}"
if [[ -z "$REAL_USER" ]]; then
    echo "Error: Run this via sudo from your normal user."
    exit 1
fi

REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
echo "Syncing GTK themes from: $REAL_HOME"

# 3. Prepare Root Directory
mkdir -p /root/.config

# 4. GTK 3.0: Delete & Link
echo "Processing GTK 3.0..."
if [[ -d "$REAL_HOME/.config/gtk-3.0" ]]; then
    rm -rf /root/.config/gtk-3.0
    ln -sfT "$REAL_HOME/.config/gtk-3.0" /root/.config/gtk-3.0
    echo " -> Linked GTK 3.0"
else
    echo " -> Skipping GTK 3.0 (Not found in user home)"
fi

# 5. GTK 4.0: Delete & Link
echo "Processing GTK 4.0..."
if [[ -d "$REAL_HOME/.config/gtk-4.0" ]]; then
    rm -rf /root/.config/gtk-4.0
    ln -sfT "$REAL_HOME/.config/gtk-4.0" /root/.config/gtk-4.0
    echo " -> Linked GTK 4.0"
else
    echo " -> Skipping GTK 4.0 (Not found in user home)"
fi

echo "Success. Root themes are synced."
