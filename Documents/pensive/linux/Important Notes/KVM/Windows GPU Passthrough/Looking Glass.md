# 🖥️ Ultimate Guide: Muxless Laptop GPU Passthrough

> [!abstract] Objective
> 
> Goal: Achieve near-native gaming performance in a Windows 11 KVM Guest on an Arch Linux Host.
> 
> **The Challenge:** Laptops route the high-performance NVIDIA GPU through the weaker Intel iGPU in hybrid/optimus mode. When we pass the NVIDIA card to a VM, it becomes "Headless"—it has no physical video output connected to it.
> 
> **The Solution:**
> 
> 1. **Virtual Display Driver (IDD):** Tricks Windows into thinking a monitor is plugged in.
>     
> 2. **IVSHMEM (Shared Memory):** A block of RAM shared between Linux and Windows. Windows copies video frames here.
>     
> 3. **Looking Glass:** A Linux application that reads that RAM and puts the Windows screen on your Linux desktop.
>     

## 🏗️ Phase 1: Host Preparation (Arch Linux)

We need the viewer application (`looking-glass`) and a generic remote desktop tool (`freerdp`) to access the VM while we configure the video drivers.

### 1. Install Dependencies

Run the following in your host terminal:

```bash
# 1. Install Looking Glass Client (AUR)
# This is the high-performance viewer we will use for gaming.
paru -S --needed looking-glass

# 2. Install FreeRDP v3 (Official Repo)
# We need this as a "Rescue Bridge" to access the VM later when we disable
# the default video adapter. Without it, you would see a black screen.
sudo pacman -S --needed freerdp
```

### 2. Configure Shared Memory

Looking Glass uses a file in RAM (`/dev/shm`) as a "whiteboard." Windows draws on it, Linux reads it. By default, regular users cannot access this memory, so we must create a permission rule.

## Make sure to replace `dusk` with YOUR username. 
```bash
echo "f /dev/shm/looking-glass 0660 dusk kvm -" | sudo tee /etc/tmpfiles.d/10-looking-glass.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf
```

> [!NOTE] Explination
>  Create a systemd temporary file configuration
>  Syntax: type | path | mode | user | group | age
>  'f': Create file if missing.
>  '0660': User/Group can Read+Write.
>  'dusk kvm': Owned by user 'dusk', group 'kvm'.
>  Apply the rule immediately

> [!check] Verify the File
> 
> Ensure the file was created with the correct permissions.
> 
> ```
> ls -l /dev/shm/looking-glass
> ```
> 
> **Output should look like:** `0 dusk kvm` (0 bytes is normal right now).

## 🔌 Phase 2: The XML Bridge (QEMU Configuration)

Now we must tell the Virtual Machine to "mount" the shared memory file we just prepared. This acts as the physical link between the two systems.

### 1. Edit the VM Configuration

Open your VM configuration file in the terminal. Replace `win10` with your VM name if different.

```bash
# Check your VM name
sudo virsh list --all
```

```bash
# Edit the XML using Neovim (or your default editor)
sudo EDITOR=nvim virsh edit win10
```

### 2. Add the Shared Memory Device

Scroll to the bottom of the `<devices>` section (usually near `<memballoon>`). Paste the following block exactly as shown.

> [!danger] CRITICAL: The Size Parameter
> 
> You MUST specify <size unit='M'>32</size>.
> 
> If you omit this, QEMU defaults to 4MB. A 1080p or 4K screen requires much more space (approx 16MB+).
> 
> Result of failure: Looking Glass will crash immediately with an "Invalid Argument" error.

```ini
<shmem name='looking-glass'>
  <model type='ivshmem-plain'/>
  <size unit='M'>32</size>
</shmem>
```

> [!example]- Context: Where to paste
> 
> ```
>     <memballoon model='virtio'>
>       <alias name='balloon0'/>
>       <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
>     </memballoon>
>     
>     <!-- PASTE THE SHMEM BLOCK HERE -->
>     
>   </devices>
> </domain>
> ```

### 3. The "Clean Slate" Reset

XML changes regarding memory are not applied on a simple reboot. You must perform a **Hard Reset** and clear the old file to prevent permission errors.

```bash
# 1. Kill the VM
sudo virsh destroy win10

# 2. Delete the old 0-byte/bad file.
# If we don't do this, QEMU might fail to resize it or inherit bad permissions.
sudo rm /dev/shm/looking-glass

# 3. Start the VM
sudo virsh start win10
```

### 4. Verify the Hardware Link

Check the file size on the host again. This confirms QEMU successfully allocated the memory.

```
ls -l /dev/shm/looking-glass
```

|   |   |   |
|---|---|---|
|**Result**|**Size in Bytes**|**Status**|
|✅ **Success**|**~33,554,432**|(34MB) Ready for High Res.|
|❌ **Failure**|**4,194,304**|(4MB) XML size tag is missing/wrong.|
|❌ **Failure**|**0**|VM is not running or XML is invalid.|
# Disable the Display driver (Two options)
### [[The RDP method to disable display driver]] (complicated but safe)

**OR** 
### Disable the Basic Adapter right from virt manager window (Easier but sometimes causes major issues if wrong display disabled (black screen))

1. Open **Device Manager**.
    
2. Expand **Display Adapters**.
    
3. Right-click **Microsoft Basic Display Adapter** (or Red Hat QXL).
    
4. Select **Disable Device**.

_Result:_ Windows stops rendering to the Virt-Manager window. It scans for the next available GPU and wakes up the NVIDIA card.

### 3. Wake the Virtual Monitor

If RDP is the _only_ monitor Windows sees, Looking Glass will see nothing. We need to activate the IDD (Virtual Display) driver you installed previously.

1. Open **Command Prompt (Admin)** inside Windows.
    
2. Run the IDD enable command (e.g., `deviceinstaller64 enableidd 1`).
    
3. **Verify:** Right-click desktop -> Display Settings. You should see **Monitor 1 (RDP)** and **Monitor 2 (Virtual/NVIDIA)**.

## 🚀 Phase 4: Launching Looking Glass

We are ready to view the shared memory buffer.

### 1. Fix Permissions (The Race Condition)

When QEMU started in Phase 2, it recreated `/dev/shm/looking-glass` as the user `root` (or `libvirt-qemu`). Your user `dusk` cannot write to it anymore. We must reclaim it manually.

```bash
# Give ownership back to dusk
sudo chown dusk:kvm /dev/shm/looking-glass

# Ensure Group (kvm) can read/write
sudo chmod 660 /dev/shm/looking-glass
```

### 2. Launch Client

Since laptop keyboards often lack a **Scroll Lock** key (the default capture key), we remap the capture key to **Right Ctrl**.

-f: Force use of the specific shared memory file
-m: Remap the "Capture Key" to Right Control
```bash
looking-glass-client -f /dev/shm/looking-glass -m KEY_RIGHTCTRL
```

## 🧠 Phase 5: Troubleshooting

### "Black Screen" on Connect

If Looking Glass opens but the window remains black, Windows has "forgotten" to enable the Virtual Monitor output.

**The Fix:**

1. **Hard Reset:** Force shutdown the VM via Virt-Manager. Start it again.
    
2. **Launch:** Run the Looking Glass command (from Phase 4, Step 2).
    
3. **Focus:** Click the Looking Glass window (it will be black).
    
4. **Capture:** Press **Right Ctrl** (to capture keyboard input).
    
5. **The Blind Shortcut:**
    
    - Press `Win` + `P`
        
    - Wait 1 second
        
    - Press `Down Arrow`
        
    - Press `Down Arrow`
        
    - Press `Enter`
        

> [!info] What did that do?
> 
> This blindly navigates the Windows "Project" menu to switch from "PC Screen Only" to "Extend" or "Duplicate". This forces the NVIDIA driver to wake up and start filling the shared memory with frames.

## 📚 Technical Summary (The "Why")

|   |   |   |
|---|---|---|
|**Component**|**Role**|**Why it fails**|
|**/dev/shm**|**RAM Disk.** Used for zero-copy data transfer between Linux and Windows.|If file is 0 bytes, XML `<size>` is missing. If "Permission Denied", `chown` is needed.|
|**IVSHMEM**|**Virtual PCI Device.** Connects Guest RAM to Host RAM.|Needs `ivshmem-plain` model in XML to function.|
|**IDD Driver**|**Fake Monitor.** Plugs a "ghost" monitor into the GPU.|Essential for Muxless laptops. Without it, the NVIDIA GPU goes to sleep (Code 43).|
|**RDP**|**Rescue Bridge.** Remote Desktop Protocol.|Used to configure Windows drivers when the main display is disabled.|
|**Basic Adapter**|**Emulated GPU.** The slow software graphics card.|Must be DISABLED to force games to run on the NVIDIA GPU.|
