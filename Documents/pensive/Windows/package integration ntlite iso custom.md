# Guide: Integrating WinFsp (MSI) into Windows 10 via NTLite


Objective: Integrate the WinFsp file system driver into a custom Windows 10 ISO so it installs silently and automatically during Windows Setup, before the user logs in.

> [!DANGER] CRITICAL WARNING - READ BEFORE STARTING
> 
> Do not use the "Integrate > Drivers" tab.
> 
> WinFsp is an application/driver hybrid installed via MSI. It is NOT a raw .inf driver. You MUST use the Post-Setup method described below. Failing to do this will result in an ISO that either fails to build or ignores the driver entirely.

## Phase 0: Preparation (Do this NOW before Internet is gone)

### 1. File Checklist

Ensure you have these three specific items locally on your drive:

- [ ] **NTLite (Free or Licensed):** Installed and ready.
    
- [ ] **Windows 10 ISO:** A standard ISO image.
    
- [ ] **WinFsp Installer (.msi):** - _Critical:_ You must have the **.msi** version, not the .exe.
    
    - If you have the exe, go to [winfsp.dev](https://winfsp.dev "null") and get the MSI. The MSI guarantees standard silent switches (`/qn`) will work.
        

### 2. Workspace Setup

_Don't work directly on the ISO file. Extract it first._

1. Create a folder on your root drive (e.g., `C:\Win10_Work`).
    
2. Right-click your Windows 10 ISO and choose **Mount** (or use 7-Zip to extract).
    
3. Copy **ALL** contents from the mounted ISO into `C:\Win10_Work`.
    
4. Copy your `winfsp-x.x.x.msi` file to a safe location (e.g., `C:\ISO_Assets\winfsp.msi`). Do _not_ put it inside the `Win10_Work` folder yet; NTLite will do that for you.
    

## Phase 1: Loading the Image

1. Open **NTLite** as Administrator.
    
2. Click **Add** (Top Left Toolbar) -> **Image Directory**.
    
3. Select your work folder (`C:\Win10_Work`).
    
4. You will see a list of Windows editions (Home, Pro, Education, etc.).
    
5. **Right-click** the edition you plan to install (e.g., "Windows 10 Pro").
    
6. Select **Load**.
    
    - _Wait:_ This process takes 1-5 minutes depending on your disk speed. The circle next to the edition will turn green when loaded.
        

## Phase 2: Post-Setup Integration (The Critical Steps)

This is the most important section. Follow exact button presses.

### 1. Enter Post-Setup

1. On the **Left Sidebar**, look under the "Integrate" section.
    
2. Click **Post-Setup**.
    

### 2. Select Machine Mode

> [!IMPORTANT]
> 
> You will see a toolbar or tabs labeled Machine and User.
> 
> You MUST select Machine.
> 
> - **Why?** `Machine` commands run as the `SYSTEM` account (highest privilege) _before_ any user logs in. WinFsp installs drivers; it requires SYSTEM privileges. If you run it as "User", it may prompt for UAC and hang the installation.
>     

### 3. Add the WinFsp MSI

1. Ensure the **Machine** tab/view is active.
    
2. Click **Add** (Top Toolbar) -> **File**.
    
3. Browse to and select your `winfsp.msi` file.
    
4. The file will appear in the list.
    

### 4. Configure Silent Parameters (Fail-Proofing)

Look at the row for WinFsp you just added. Locate the Parameters column. It might be empty or auto-filled.

You must edit the Parameters column to read EXACTLY:

```
/qn /norestart
```

**Breakdown of Flags:**

- `/qn`: **Q**uiet **N**o UI. This creates a completely invisible installation. No "Next" buttons, no progress bars.
    
- `/norestart`: **CRITICAL.** WinFsp might try to restart the computer after installing the driver. If it reboots during the Windows Setup phase, it will break the installation loop and verify "Corrupt Installation." This flag forces it to wait.
    

### 5. Verify the Row

Your row in NTLite should look like this:

- **Path:** `(Source path to your msi)`
    
- **Parameters:** `/qn /norestart`
    
- **Type:** `Installer` (NTLite should detect this automatically).
    

## Phase 3: Finalizing and Building

### 1. Apply Changes

1. Click **Apply** on the Left Sidebar.
    
2. Under "Saving Mode", select **Save the image**.
    
3. Under "Image Format", ensure **Standard WIM** (or ESD if you need space, but WIM is faster) is selected.
    

### 2. Create the ISO

1. Check the box labeled **Create ISO** (Top right of the Apply window).
    
2. Click the **...** button next to "Label" to name your ISO (e.g., `Win10_WinFsp_Custom`).
    
3. Select where to save the final `.iso` file.
    

### 3. Process

1. Click the green **Process** button in the top left toolbar.
    
2. **Disable Defender (Optional):** NTLite may ask to disable Windows Defender Real-time protection to speed up the build. Click **Yes**.
    
3. **Wait.** This will take 10-30 minutes.
    
4. Once it says "Completed", you are done.
    

## Phase 4: Offline Verification (Safety Check)

Since you won't have internet to debug, use this method to verify the ISO contains the file _before_ you try to install it.

1. **Open the ISO without mounting:** Use 7-Zip to right-click your new ISO -> **Open archive**.
    
2. Navigate deep into the folder structure:
    
    sources -> $OEM$ -> $$ -> Setup -> Files
    
    (Note: If you don't see $OEM$, the integration failed. Go back to Phase 2).
    
3. **Check for the file:** You should see `winfsp.msi` inside this folder.
    
4. **Check the Script:**
    
    - Go back to `sources` -> `$OEM$` -> `$$` -> `Setup` -> `Scripts`.
        
    - Open `SetupComplete.cmd` (Right-click -> Edit/View).
        
    - Look for a line resembling:
        
        start /wait %WINDIR%\Setup\Files\winfsp.msi /qn /norestart
        
    - If that line exists, your ISO is perfect.
        

## Troubleshooting Cheat Sheet

|   |   |
|---|---|
|**Issue**|**Solution**|
|**Install hangs at "Just a moment..."**|You likely forgot the `/qn` switch. The installer is waiting for a click that you can't see. Reboot and rebuild ISO with correct parameters.|
|**PC Reboots unexpectedly during install**|You forgot the `/norestart` switch. The driver forced a reboot before Windows finished setup.|
|**WinFsp is not installed on desktop**|You likely used "User" mode instead of "Machine" mode in Post-Setup, and the installer failed due to permissions or UAC blocking it silently.|
|**NTLite Error: "File not found"**|Ensure you didn't move the MSI file _while_ NTLite was open. Keep assets in a static folder like `C:\ISO_Assets`.|

> [!TIP] Final Offline Tip
> 
> If you are installing other apps (like SSHFS) that depend on WinFsp, make sure WinFsp is above them in the NTLite Post-Setup list. Use the Up/Down arrows on the toolbar to change the install order. WinFsp must run first.