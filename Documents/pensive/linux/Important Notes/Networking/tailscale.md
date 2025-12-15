# Elite Remote Access: Manual Tailscale Setup

> [!abstract] Overview
> 
> This guide details the manual process of setting up a high-performance, CGNAT-friendly remote access tunnel on Arch Linux running Hyprland.
> 
> **Goal:** Create a mesh VPN that allows you to SSH or Stream (Sunshine/Moonlight) to this machine from anywhere, without port forwarding.

## 🛑 Phase 1: Network Conflict Resolution

Before installing anything, ensure no other VPNs are fighting for control. VPNs like Cloudflare WARP or OpenVPN often conflict with Tailscale's initialization.

1. **Check for active VPN interfaces:**
    
    ```
    ip -o link show | grep -E 'tun|wg|ppp|Cloudflare'
    ```
    
2. Disconnect them:
    
    If you see CloudflareWARP, for example:
    
    ```
    warp-cli disconnect
    ```
    
    _Why?_ If traffic is routed through WARP, Tailscale cannot reach its coordination server to register your machine.
    

## 🏗️ Phase 2: System Foundation

Tailscale works best when the underlying OS networking is compliant.

### 1. DNS Configuration (systemd-resolved)

Tailscale uses "MagicDNS" to resolve device names. This requires a robust local resolver.

```
# Enable the service
sudo systemctl enable --now systemd-resolved

# Link the "stub" resolver (Crucial for VPN DNS handling)
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### 2. Hardening NetworkManager

NetworkManager loves to interfere with interfaces it doesn't own. We must tell it to explicitly ignore `tailscale0`.

```
# Create a config override
sudo mkdir -p /etc/NetworkManager/conf.d

# Write the ignore rule
echo -e "[keyfile]\nunmanaged-devices=interface-name:tailscale0" | sudo tee /etc/NetworkManager/conf.d/96-tailscale.conf

# Reload NetworkManager
sudo systemctl reload NetworkManager
```

### 3. Enable `uinput` (For Remote Control)

If you plan to use Moonlight/Sunshine later, the kernel needs `uinput` to simulate mouse/keyboard events.

```
# Load module immediately
sudo modprobe uinput

# Make it persistent across reboots
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf
```

## 🚀 Phase 3: Installation & Firewall

### 1. Install & Enable

```
# Install package
sudo pacman -S tailscale

# Enable the daemon (background service)
sudo systemctl enable --now tailscaled
```

### 2. Allow Firewall Traffic

Arch default firewalls block the VPN tunnel. Open it up.

**If using Firewalld:**

```
sudo firewall-cmd --zone=trusted --add-interface=tailscale0 --permanent
sudo firewall-cmd --reload
```

**If using UFW:**

```
sudo ufw allow in on tailscale0
```

## 🔐 Phase 4: Authentication

This links your machine to your private network.

```
# Start the engine and request a QR code for login
sudo tailscale up --qr
```

> [!tip] Troubleshooting
> 
> If the QR code doesn't appear or the command hangs, verify Phase 1 again. A hanging tailscale up almost always means another VPN is blocking the connection.

### Verification

Once logged in, check your new persistent IP:

```
tailscale ip -4
```

You can now ping this IP from your phone (if it also has Tailscale installed) from anywhere in the world.