# Ultimate Lean Windows 10 ISO Guide for Adobe After Effects (KVM/QEMU Edition)

This guide details how to create a stripped-down, high-performance Windows 10 ISO specifically for running Adobe Creative Cloud apps (After Effects, Premiere, Photoshop) inside a **KVM/QEMU Virtual Machine with GPU Passthrough** on Arch Linux.

> **⚠️ BUILD ENVIRONMENT NOTE:** NTLite runs only on Windows. You must perform **Phase 2** inside a temporary Windows VM or a separate Windows machine to generate the ISO before moving it to your Arch host.

## 🛠️ Phase 1: Prerequisites & Tools

1. **Windows 10 ISO**: Download the official ISO (preferably 21H2 or 22H2 Pro).
    
2. **NTLite (Free or Licensed)**: To modify the ISO.
    
3. **VirtIO Drivers ISO (Critical)**: Download the latest stable `virtio-win.iso` from the Fedora Project. Extract the contents to a folder named `VirtIO_Drivers`.
    
    - _You need these integrated, or the Windows installer will NOT see your virtual hard drive._
        
4. **WinFSP MSI Installer**: Download the latest `.msi` installer for WinFSP (Windows File System Proxy).
    
5. **Adobe Offline Installers**: Creative Cloud offline installer.
    
6. **NVIDIA Studio Drivers**: The standard Windows `.exe` installer.
    

## ⚙️ Phase 2: NTLite Configuration (The Build)

### 1. Setup

1. Extract your Windows 10 ISO to a folder (e.g., `C:\Win10_Mod`).
    
2. Open **NTLite** -> "Add" -> "Image Directory" -> Select `C:\Win10_Mod`.
    
3. Load **Windows 10 Pro**.
    

### 2. Driver Integration (KVM Specific)

**This is the most important step for KVM users.**

1. Go to the **Drivers** tab.
    
2. Click **Add** -> **Driver Files** (or Directory).
    
3. Navigate to your extracted `VirtIO_Drivers` folder and add the following specific drivers for **w10 \ amd64**:
    
    - `viostor` (Storage - Required to see the disk)
        
    - `netkvm` (Network - Required for Ethernet)
        
    - `vioserial` (VirtIO Serial - Required for copy/paste & Guest Agent)
        
    - `qxldod` (Display - Required for initial boot before NVIDIA driver takes over)
        
    - `viogpu` (Alternative Display)
        
    - `vioscsi` (If you plan to use SCSI pass-through)
        
    - `vioinput` (Input optimization)
        

### 3. Components Removal (Debloating)

Go to the **Components** tab.

> **✅ KEEP THESE (Do NOT Remove)**
> 
> - **Multimedia > Windows Media Player** (Codecs)
>     
> - **System > .NET Framework** (Critical for Adobe)
>     
> - **System > VC++ Runtimes** (Critical for Adobe)
>     
> - **System > WoW64** (32-bit plugin support)
>     
> - **System > Hyper-V Guest Components** (Keep these! KVM mimics Hyper-V enlightenments to improve Windows performance. Removing them can increase CPU overhead).
>     

#### 🗑️ SAFE TO REMOVE:

**Apps (UWP/Store):**

- $$ $$
    
    Apps > Microsoft Store
    
- $$ $$
    
    Apps > Xbox (All)
    
- $$ $$
    
    Apps > OneDrive
    
- $$ $$
    
    Apps > Cortana
    
- $$ $$
    
    Apps > Photos, Weather, News, etc.
    
- $$ $$
    
    Apps > Edge (Legacy & Chromium)
    

**Privacy & Telemetry:**

- $$ $$
    
    Privacy > Customer Experience Improvement Program (CEIP)
    
- $$ $$
    
    Privacy > Telemetry Client
    
- $$ $$
    
    Privacy > Windows Error Reporting
    
- $$ $$
    
    System > Feedback Hub
    

**Services:**

- $$ $$
    
    System > Windows Defender (**Performance Killer** - Ensure your Linux host firewall is strict)
    
- $$ $$
    
    System > Windows Search (Disable Indexing)
    

### 4. Configuration

Go to **Services** tab in NTLite:

- **SysMain**: `Disabled`
    
- **Windows Update**: `Disabled`
    

### 5. Post-Setup (WinFSP & Integrations)

This step ensures WinFSP is installed automatically when Windows boots for the first time.

1. Go to the **Post-Setup** tab in NTLite.
    
2. Click **Add** -> **File**.
    
3. Select your `winfsp-x.x.x.msi` file.
    
4. It will appear in the list. Look for the **Parameters** column on the right side of the WinFSP entry.
    
5. Enter the following silent install flags in the Parameters field:
    
    ```
    /qn /norestart
    ```
    
    - `/qn`: Quiet mode, No UI.
        
    - `/norestart`: Prevents the installer from triggering a reboot mid-setup.
        
6. **Execution Mode**: Ensure it is set to **Machine - Execution** (This runs it as System/Admin before the user even logs in).
    

## 💉 Phase 3: Post-Installation Optimization (Registry)

After installing Windows in KVM, copy this into a file named `KVM_Optimize.reg` and run it. This includes fixes for common virtualization latency.

```
Windows Registry Editor Version 5.00

; --- VISUAL & UI SPEED ---
[HKEY_CURRENT_USER\Control Panel\Desktop]
"MenuShowDelay"="0"
"AutoEndTasks"="1"
"HungAppTimeout"="1000"
"WaitToKillAppTimeout"="2000"

; --- GPU STABILITY (TDR FIX) ---
; Critical for Passthrough to prevent driver resets during renders
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers]
"TdrDelay"=dword:00000010
"TdrLevel"=dword:00000003

; --- SYSTEM PRIORITY ---
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl]
"Win32PrioritySeparation"=dword:00000026

; --- DISABLE FULLSCREEN OPTIMIZATIONS ---
[HKEY_CURRENT_USER\System\GameConfigStore]
"GameDVR_Enabled"=dword:00000000
"GameDVR_FSEBehaviorMode"=dword:00000002

; --- POWER MANAGEMENT ---
; Force High Performance
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes]
"ActivePowerScheme"="8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

; --- DISABLE HIBERNATION ---
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power]
"HibernateEnabled"=dword:00000000

; --- NETWORK THROTTLING ---
; Fixes slow network speeds often seen in VirtIO drivers
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"NetworkThrottlingIndex"=dword:ffffffff

```

## ⚡ Phase 4: KVM/Passthrough Specific Fixes (Mandatory)

These steps are unique to GPU passthrough and **must** be done to prevent audio crackling and stuttering in After Effects.

### 1. Enable MSI Mode (Message Signaled Interrupts)

Windows often defaults NVIDIA GPUs to "Line-based" interrupts in VMs, which causes high DPC latency.

1. Download **MSI Util v2** (or use the manual registry method).
    
2. Run as Administrator.
    
3. Locate your **NVIDIA GeForce/RTX** card in the list.
    
4. Check the box **"MSI"** on the right.
    
5. Set "Limit" to `Undefined`.
    
6. Click **Apply**.
    
7. _Do NOT enable MSI for the VirtIO drivers (viostor/netkvm) unless you know they support it, they usually handle it automatically._
    

### 2. Disable Link State Power Management

1. Control Panel -> Power Options -> High Performance -> Change plan settings -> Change advanced power settings.
    
2. **PCI Express > Link State Power Management**: Set to **Off**.
    
    - _Why:_ This prevents the host/guest negotiation from trying to sleep the GPU bus, which causes massive lag spikes in VMs.
        

### 3. Install QEMU Guest Agent

1. Inside the VM, mount the `virtio-win.iso` again.
    
2. Navigate to `guest-agent`.
    
3. Install `qemu-ga-x86_64.msi`.
    
    - _Why:_ Allows the Arch host to issue clean shutdown commands and improves time synchronization.
        

## 🎨 Phase 5: Adobe Specific Setup

1. **NVIDIA Control Panel**:
    
    - **Manage 3D Settings**:
        
    - Power Management Mode: **Prefer Maximum Performance**.
        
    - Texture Filtering: **High Performance**.
        
    - Vertical Sync: **Off**.
        
2. **After Effects Memory**:
    
    - Edit -> Preferences -> Memory.
        
    - RAM reserved for other apps: **3GB** (Windows needs very little now).
        
3. **Process Lasso**:
    
    - Install Process Lasso in the VM.
        
    - Set `AfterFX.exe` -> CPU Affinity -> **Select All Cores**.
        
    - Set `AfterFX.exe` -> Priority -> **High**.