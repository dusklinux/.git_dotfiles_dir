# 🖥️ Ultimate Guide: Muxless Laptop GPU Passthrough & Looking Glass

> [!abstract] Objective
> 
> Achieve near-native gaming performance in a Windows 11 KVM Guest on an Arch Linux Host (Hyprland).
> 
> The Challenge: Muxless laptops (like ASUS TUF F15) route the NVIDIA GPU through the Intel iGPU. When passed through to a VM, the NVIDIA card has no physical video output connected to it. It is "Headless."
> 
> The Solution:
> 
> 1. **Virtual Display Driver (IDD):** Tricks Windows into rendering frames for a monitor that doesn't exist.
>     
> 2. **IVSHMEM (Inter-VM Shared Memory):** A block of RAM shared between Linux and Windows. Windows copies the video frames here.
>     
> 3. **Looking Glass:** A Linux client that reads that RAM and displays it on your screen.
>     

## 🏗️ Phase 1: Host Preparation (Arch Linux)

We need the viewer application (`looking-glass`) and a way to control the VM (`freerdp`) before the viewer is fully configured.

### 1. Install Dependencies

```bash
# Looking Glass Client (AUR)
# This is the window that will display the VM output.
paru -S --needed looking-glass

# FreeRDP v3 (Official Repo)
# We need RDP to access the VM when we disable the "Basic Display Adapter" 
# later. Without this, we would be locked out of a black screen.
sudo pacman -S --needed freerdp
```

> [!info] Why FreeRDP?
> 
> Arch uses FreeRDP v3, which renames the binary to xfreerdp3. It is a Wayland-compatible Remote Desktop client. We use it as a "Rescue Bridge" to configure the Windows video drivers.

### 2. Configure Shared Memory (`/dev/shm`)

Looking Glass needs a file in RAM to use as a "whiteboard." Windows writes to it, Linux reads from it. By default, standard users cannot read QEMU memory. We must create a permissions rule.

```bash
# Create a systemd temporary file configuration
# Syntax: type | path | mode | user | group | age
# 'f': Create a file if it doesn't exist.
# '0660': User/Group can Read/Write. (rw-rw----)
# 'dusk kvm': Owned by user 'dusk', group 'kvm'.
echo "f /dev/shm/looking-glass 0660 dusk kvm -" | sudo tee /etc/tmpfiles.d/10-looking-glass.conf

# Apply the rule immediately
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf
```

> [!check] Verification
> 
> Running ls -l /dev/shm/looking-glass should show a 0-byte file owned by dusk (if the VM is off).

```bash
ls -l /dev/shm/looking-glass
```



## 🔌 Phase 2: The XML Bridge (QEMU Configuration)

We must tell the Virtual Machine to "mount" the shared memory file we just prepared. This is the hardware link.

### 1. Edit the VM Configuration

First find out what your vm is called

```bash
sudo virsh list --all
```

Use `sudo` (system VM) and `nvim` (as `vi` might be missing).

```
sudo EDITOR=nvim virsh edit win11
```

### 2. Add the Shared Memory Device

Scroll to the bottom of the `<devices>` section (usually near `<memballoon>`). Insert the following block.

> [!danger] CRITICAL: The Size Parameter
> 
> You MUST specify <size unit='M'>32</size>.
> 
> If you omit this, QEMU defaults to 4MB. A 1080p/4K framebuffer requires ~16MB+.
> 
> Result of failure: Looking Glass will crash with Invalid Argument because the bucket is too small for the water.


> [!NOTE]- context
> ```ini
> <memballoon model='virtio'>
>       <alias name='balloon0'/>
>       <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
>     </memballoon>
> 
> 
>   PASTE HERE...
>    
>    
> </devices>
> ```

```ini
<shmem name='looking-glass'>
  <model type='ivshmem-plain'/>
  <size unit='M'>32</size>
</shmem>
```

### 3. The "Clean Slate" Reset

XML changes regarding memory are not applied on a simple reboot. You must perform a **Hard Reset** and clear the old file to prevent "poisoning."

```BASH
# 1. Kill the VM
sudo virsh destroy win11

# 2. Delete the old 0-byte/bad file.
# If we don't do this, QEMU might fail to resize it or inherit bad permissions.
sudo rm /dev/shm/looking-glass

# 3. Start the VM
sudo virsh start win11
```

### 4. Verify the Hardware Link

Check the file size on the host. This confirms QEMU successfully allocated the 32MB block.

```
ls -l /dev/shm/looking-glass
```

- **Success:** Size is approx **33,554,432** (34MB).
    
- **Failure:** Size is **0** or **4,194,304** (4MB). _Check your XML size tag again._
    
this is what it shoudl show. 
`.rw-rw---- 34M dusk  9 Dec 16:26 󰡯 /dev/shm/looking-glass`

## 🔄 Phase 3: The "Headless" Switch

This is the most critical step. We must disable the Emulated GPU (Microsoft Basic Display) to force Windows to use the Passthrough NVIDIA GPU.

### 1. Connect via RDP (The Rescue Line)

Do **not** disable the display via Virt-Manager, or you will lose mouse control. Use RDP. 

MAKE SURE TO ENTER THE IP ADDRESS and USERNAME FROM WINDOWS
```bash
# /u:dusk = The ACTUAL Windows username (checked via 'whoami' or prompt)
# /cert:ignore   = Bypass certificate warnings
# /dynamic-resolution = Allow resizing
xfreerdp3 /v:192.168.122.29 /u:dusk /cert:ignore /dynamic-resolution
```
**OR**
```bash
xfreerdp3 /v:192.168.122.29 /u:dusk /dynamic-resolution
```
### 2. Disable the Basic Adapter

Inside the RDP Session:

1. Open **Device Manager**.
    
2. Right-click **Microsoft Basic Display Adapter** (or Red Hat QXL).
    
3. **Disable Device.**
    
    - _Under the hood:_ Windows stops rendering to the QEMU window (Virt-Manager). It now looks for the next available GPU. It finds the NVIDIA card.
        

### 3. Wake the Virtual Monitor

If RDP is the _only_ monitor, Looking Glass will see nothing. We need a second monitor (the NVIDIA one).

1. Open Command Prompt (Admin).
    
2. Run the IDD command (e.g., `deviceinstaller64 enableidd 1`).
    
3. **Verify:** Check Display Settings. You should see **Monitor 1 (RDP)** and **Monitor 2 (Virtual/NVIDIA)**.
    

## 🚀 Phase 5: Launching Looking Glass

We are ready to view the shared memory buffer.

### 1. Fix Permissions (The Race Condition)

When QEMU started in Phase 2, it recreated `/dev/shm/looking-glass` as user `libvirt-qemu` (root). Your user `dusk` cannot write to it anymore. We must reclaim it.

```bash
# Give ownership back to dusk
sudo chown dusk:kvm /dev/shm/looking-glass

# Ensure Group (kvm) can read/write
sudo chmod 660 /dev/shm/looking-glass
```

### 2. Launch Client

Since your laptop lacks a **Scroll Lock** key (the default capture key), we remap it to **Right Ctrl**.

```bash
# -f: Force use of the specific shared memory file
# -m: Remap the "Capture Key"
looking-glass-client -f /dev/shm/looking-glass -m KEY_RIGHTCTRL
```

### 🧠 Troubleshooting: "Black Screen" on Connect

If Looking Glass opens but remains black:

1. Windows has "forgotten" to enable the Virtual Monitor.
    
2. **The Fix:**
		- First shutdown/force shutdown your vm through virt-manager. and then turn it back on. it'll get stuck, dont hit any keys. 
		- 
		and then enter the looking glass command 
```bash
looking-glass-client -f /dev/shm/looking-glass -m KEY_RIGHTCTRL
```


Focus Looking Glass.
        
 Press **Right Ctrl** (to capture keyboard).
        
Press **Win + P**, wait 1 sec, press **Down**, press **Down**, press **Enter**.
        
_Explanation:_ This blindly switches Windows Projection Mode to "Extend" or "Duplicate," forcing the NVIDIA driver to wake up and output frames.
        

## 📚 Technical Summary (The "Why")

|                             |                                                          |                                                                                            |
| --------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **Component**               | **Role**                                                 | **Why it fails**                                                                           |
| **/dev/shm**                | RAM Disk. Used for zero-copy data transfer.              | If file is 0 bytes, XML `<size>` is missing. If Permission Denied, `chown` is needed.      |
| **IVSHMEM**                 | The virtual PCI device connecting Guest RAM to Host RAM. | Needs `ivshmem-plain` model in XML.                                                        |
| **IDD Driver**              | Fakes a monitor plug.                                    | Essential for Muxless laptops. Without it, NVIDIA GPU goes to sleep (Code 43 or Headless). |
| **RDP**                     | Remote Desktop Protocol.                                 | Used as a temporary display to configure drivers when the main display is disabled.        |
| **Microsoft Basic Adapter** | The emulated GPU.                                        | Must be DISABLED to force apps/games to run on the NVIDIA GPU.                             |