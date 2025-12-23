
# Manual Setup: iPhone as Headless Hyprland Monitor (USB)

This guide documents the manual process of turning an iPhone into a secondary monitor for Arch Linux running Hyprland, using a wired USB connection (Tethering).

## 1. The Architecture

We are creating a **LAN over USB**.

1. **Physical Layer:** The iPhone connects via USB.
    
2. **Data Link/Network:** We enable "Personal Hotspot" (USB Tethering) to create a network interface (`ipheth` driver).
    
3. **Display Layer:** We tell Hyprland to create a "Headless" (virtual) GPU output.
    
4. **Transport Layer:** We run a VNC Server (`wayvnc`) attached specifically to that virtual output.
    
5. **Client Layer:** The iPhone connects to the VNC server via the USB network IP.
    

## 2. Prerequisites

Install the necessary networking and Wayland tools:

```
sudo pacman -S wayvnc hyprland usbmuxd libimobiledevice net-tools iproute2 dhcpcd
```

- **`usbmuxd`**: The daemon that handles the multiplexed USB connection to iOS devices.
    
- **`wayvnc`**: A VNC server for wlroots-based compositors (like Hyprland).
    
- **`ipheth`**: The kernel module (driver) that handles iPhone Ethernet (usually built-in).
    

## 3. Phase 1: The Network Handshake

This is the most common point of failure. The iPhone must act as the DHCP Server (Router), and your laptop is the Client.

1. **Connect iPhone via USB.**
    
2. **Enable Hotspot:** On iPhone, go to **Settings > Personal Hotspot** and toggle **"Allow Others to Join"**.
    
    - _Note:_ This triggers the iPhone to present itself as a Network Interface via USB.
        
3. Identify Interface:
    
    Run ip link or ls /sys/class/net. Look for a new interface (often named enp..., usb0, or eth1).
    
    - _Check Driver:_ You can verify it's an iPhone by checking the driver:
        
        ```
        readlink -f /sys/class/net/<interface_name>/device/driver
        # Output should end in 'ipheth'
        ```
        
4. **Bring Interface Up:**
    
    ```
    sudo ip link set <interface_name> up
    ```
    
5. Get IP Address:
    
    We need to ask the iPhone for an IP address. Using dhcpcd is often more reliable than NetworkManager for this specific manual task.
    
    ```
    sudo dhcpcd <interface_name>
    ```
    
6. Verify Connection:
    
    Check your IP. It will usually be in the 172.20.10.x range.
    
    ```
    ip -4 addr show <interface_name>
    ```
    

## 4. Phase 2: Creating the Virtual Monitor

Since we don't have a physical HDMI cable, we must force Hyprland to render a virtual screen.

1. **Create Headless Output:**
    
    ```
    hyprctl output create headless
    ```
    
    - _Result:_ Hyprland creates a monitor named `HEADLESS-1` (or -2, -3 depending on count).
        
2. Configure Resolution & Scale:
    
    For an iPhone, we want high DPI (Retina) scaling.
    
    - **Resolution:** `1080x960` (Half-height 1080p, leaves room for keyboard).
        
    - **Scale:** `3.0` (Makes UI large and touch-friendly).
        
    
    ```
    # Syntax: monitor=NAME,RES,POSITION,SCALE
    hyprctl keyword monitor "HEADLESS-1,1080x960,auto,3"
    ```
    

## 5. Phase 3: The VNC Server (Fork in the Road)

Here you must choose between **Stability** (CPU) and **Performance** (GPU).

### Option A: Software Rendering (CPU) - **RECOMMENDED**

- **Pros:** 100% Stable. Works on Hybrid GPUs (Intel/Nvidia). Zero crashes.
    
- **Cons:** Higher CPU usage.
    
- **Mechanism:** `wayvnc` copies the framebuffer using the CPU.
    

**Command:**

```
# Bind to the iPhone network IP (e.g., 172.20.10.2)
wayvnc 172.20.10.2 5900 --output=HEADLESS-1 --max-fps=30
```

- `--max-fps=30`: Crucial for Hybrid GPUs to prevent DRM page-flip crashes.
    

### Option B: Hardware Acceleration (GPU) - **ADVANCED**

- **Pros:** Lower CPU usage. "Zero-Copy" memory transfer (DMA-BUF).
    
- **Cons:** Can crash Hyprland (Aquamarine backend) on Hybrid GPUs. Prone to "Grey Screen" if the wrong GPU is picked.
    
- **Mechanism:** `wayvnc` accesses the GPU VRAM directly.
    

1. Find your Render Node:
    
    Hyprland runs on a specific GPU. wayvnc must use the same GPU.
    
    Check echo $AQ_DRM_DEVICES or list nodes:
    
    ```
    ls -l /dev/dri/renderD*
    ```
    
    - Integrated GPU is usually `renderD128`.
        
    - Dedicated GPU is usually `renderD129`.
        
2. **Command:**
    
    ```
    wayvnc 172.20.10.2 5900 --output=HEADLESS-1 --max-fps=60 --gpu=/dev/dri/renderD128
    ```
    

## 6. Phase 4: The Connection

1. **Phone App:** Open "VNC Viewer" (RealVNC) or "Mocha VNC" on iPhone.
    
2. **Address:** Enter the IP address you found in Phase 1 (e.g., `172.20.10.2`).
    
3. **Connect:** You should see your Hyprland desktop.
    

## 7. Troubleshooting / Critical Thinking

### The "Grey Screen" Issue

- **Cause:** `wayvnc` is reading from GPU A, but Hyprland is rendering on GPU B. The buffer is empty.
    
- **Fix:** Switch to **Option A (Software Rendering)**. Do not use the `--gpu` flag.
    

### The "Hyprland Crash" (Signal 6 / ABRT)

- **Log Error:** `[aquamarine] drm: Cannot commit when a page-flip is awaiting`.
    
- **Translation:** VNC is asking for frames faster than the kernel can flip them on the virtual display. This is a race condition.
    
- **Fix:** Cap the framerate. Use `--max-fps=30`.
    

### Connection Refused / Timeout

- **Cause 1:** **Firewall.** `ufw` or `firewalld` sees a new network connection (`enp...`) and blocks port 5900.
    
    - _Fix:_ `sudo ufw allow 5900/tcp` OR disable firewall temporarily.
        
- **Cause 2:** **Cloudflare Warp / VPN.** VPNs often route local traffic (`172.20...`) into a black hole.
    
    - _Fix:_ `warp-cli disconnect`.
        

### Persistence

Since `HEADLESS` outputs are virtual, they disappear when you restart Hyprland. You must re-run the creation command (Phase 2) every time you want to connect.