# Elite Remote Desktop: Arch Linux + Hyprland

**Objective:** Create a low-latency (<5ms), high-fidelity (60fps+) remote desktop experience accessible from anywhere (4G/5G/WiFi) without port forwarding. for Carrier-Grade NAT (CGNAT) Networks. 

**The Stack:**

- **Network:** Tailscale (WireGuard Mesh VPN) - Bypasses CGNAT.
    
- **Server:** Sunshine (Self-hosted GameStream) - Hardware encoded video stream.
    
- **Client:** Moonlight (iOS/Android/Laptop) - Decodes stream.
    
- **Environment:** Hyprland v0.52+ (Wayland).
    

## Phase 0: The Foundation (System & Network)

**CRITICAL:** We fix DNS, Persistence, and Conflicts before installing anything.

### 1. Enable System Resolver

Tailscale needs a robust DNS resolver.

```
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### 2. NetworkManager Fix

Prevent NetworkManager from breaking the VPN interface.

```
echo -e "[keyfile]\nunmanaged-devices=interface-name:tailscale0" | sudo tee /etc/NetworkManager/conf.d/96-tailscale.conf
sudo systemctl restart NetworkManager
```

### 3. Make `uinput` Persistent

Required for mouse/keyboard control to survive a reboot.

```
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf
```

### 4. Remove Portal Conflicts

Hyprland fights with the generic wlroots portal. Remove it if present.

```
# Ignore error if package is not found
sudo pacman -Rns xdg-desktop-portal-wlr 2>/dev/null || true
```

## Phase 1: The Network Tunnel (Tailscale)

### 1. Installation & Service

```
sudo pacman -S --needed tailscale
sudo systemctl enable --now tailscaled
```

### 2. Authentication

Use `--qr` to avoid browser permission issues.

```
sudo tailscale up --qr
```

- **Action:** Scan QR with phone.
    
- **Verify:** Run `tailscale ip -4`. This is your permanent IP.
    

### 3. Firewall

Allow the tunnel traffic.

```
sudo firewall-cmd --zone=trusted --add-interface=tailscale0 --permanent
sudo firewall-cmd --reload
```

## Phase 2: The Streaming Server (Sunshine)

### 1. Installation (Source Build)

We use `sunshine-git` to ensure compatibility with Arch libraries. We add `--needed` to skip recompilation if you already have the latest commit.

```
paru -S --needed sunshine-git
```

### 2. Permissions (Groups & Rules)

We use both udev rules AND group membership for maximum reliability.

```
# 1. Add user to input/video groups
sudo usermod -aG input,video $USER

# 2. Create udev rule for virtual input
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/85-sunshine.rules

# 3. Apply changes
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo modprobe uinput
```

### 3. Install Portals

```
sudo pacman -S --needed xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

### 4. Enable Service

```
systemctl --user enable --now sunshine
```

## Phase 3: Intel iGPU Optimization (Battery Saver)

We force Sunshine to use the efficient Intel iGPU so your Nvidia card can sleep.

### 1. Install Drivers & Verify

```
sudo pacman -S --needed intel-media-driver libva-utils
```

Verification:

Run this to confirm Intel VAAPI is working. It should NOT say "Failed".

```
vainfo --display drm --device /dev/dri/renderD128
```

### 2. Force Driver in Hyprland

Tell Hyprland to look for the modern Intel driver.

Add this to your ~/.config/hypr/hyprland.conf:

```
env = LIBVA_DRIVER_NAME,iHD
```

### 3. Configure Sunshine

1. Open `https://localhost:47990` -> **Configuration** -> **Audio/Video**.
    
2. **Hardware Encoder:** `VAAPI`.
    
3. **Adapter Name:** `/dev/dri/renderD128`.
    
4. Click **Save** & **Apply**.
    

## Phase 4: System Configuration

### 1. Prevent "Lid Close" Sleep

```
sudo nvim /etc/systemd/logind.conf
# Change to: HandleLidSwitch=ignore
sudo systemctl restart systemd-logind
```

### 2. Setup Clients

1. **Laptop:** Open `https://localhost:47990`. Create User/Pass. Go to **PIN** tab.
    
2. **Phone:** Open Tailscale (ensure active). Open Moonlight. Add Host `100.x.y.z`.
    
3. **Pair:** Enter PIN on laptop.
    

## Phase 5: The "Pre-Flight" Check (CRITICAL)

**Do not skip this.** You must authorize the stream locally before you leave.

1. **Reboot your laptop** (`sudo reboot`). This applies all group/module changes.
    
2. Login to Hyprland.
    
3. Open Moonlight on your phone (on WiFi).
    
4. **Start a Stream.**
    
5. **Look at your Laptop Screen:** A popup will appear saying _"Sunshine is trying to capture your screen"_.
    
6. **Click "Allow" / "Share".**
    
    - _Note: Hyprland usually remembers this choice, but clicking it once locally is mandatory._
        

## Troubleshooting

### Issue: "PIN Incorrect" Loop

**Fix:** Delete the pairing from **BOTH** the Phone (Long press icon -> Delete) and the Sunshine Web UI (PIN Tab -> Delete). Then re-pair.

### Issue: No QR Code

**Fix:** Run `sudo tailscale logout` then `sudo tailscale up --qr`.

### Issue: Black Screen

**Fix:** Sunshine Web UI -> Configuration -> Audio/Video -> Capture Method -> **Wayland** (NOT KMS).

### Issue: Input not working

**Fix:** Ensure you rebooted after running the `usermod` and `udev` commands in Phase 2. Check with `groups $USER`.