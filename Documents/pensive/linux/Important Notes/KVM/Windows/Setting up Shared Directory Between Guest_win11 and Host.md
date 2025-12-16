# Setting up File Sharing with Virtiofs

This guide covers how to share a directory from your Host Linux system to your Windows Guest VM using **Virtiofs**.

> [!abstract] What is Virtiofs?
> 
> Virtiofs is a shared file system that lets virtual machines access a directory tree on the host machine. Unlike network shares (SMB), it is designed specifically for virtualization, offering performance similar to a local file system.

## Prerequisites

Before proceeding, ensure the following requirements are met:

> [!warning] Critical Requirements
> 
> 1. **VirtIO Guest Tools**: You must have the VirtIO Windows guest drivers installed in your Windows VM (completed in previous steps).
>     
> 2. **VM State**: The VM should be **powered off** while configuring the Host settings.
>     

## Part 1: Host Configuration (Virt-Manager)

We need to configure the virtual hardware to allow memory sharing and define the folder we want to share.

### 1. Enable Shared Memory

Virtiofs requires shared memory to function, allowing the guest to access host memory pages directly.

1. Open **Virtual Machine Manager**.
    
2. Select your Windows Guest and click **Open**.
    
3. Click the **Lightbulb icon** (Show virtual hardware details) in the toolbar.
    
4. On the left sidebar, select **Memory**. (RAM)
    
5. Check the box for **Enable shared memory**.
    
6. Click **Apply**.
    

![[Pasted image 20250727150813.png]]

### 2. Add the Filesystem Hardware

Now we define which folder on the Linux machine will be visible to Windows.

1. Click the **Add Hardware** button (bottom left).
    
2. Select **Filesystem** from the left panel.
    
3. Configure the settings as follows:
    
    - **Driver**: Select `virtiofs`.
        
    - **Source path**: The actual path on your Linux Host you want to share.
        
        - _Example_: `/mnt/zram1`
            
    - **Target path**: A "tag" name used to identify this share inside Windows.
        
        - _Example_: `host_zram1`
            
4. Click **Finish**.
    

> [!tip] Naming the Target Path
> 
> The Target path is not a Windows path (like C:\). It is just a label string. You can name it whatever you like, but keep it simple (no spaces is usually safer, though quotes work).

Once configured, start your Windows VM.

## Part 2: Guest Configuration (Windows)

Windows does not natively understand Linux file systems. We need to install a proxy driver (WinFsp) and enable the VirtIO service.

### 1. Update Windows

Before installing system drivers, ensure the OS is stable.

- **OPTIONAL** , (not recommanded )Run **Windows Update**  with the mini update tool so.
    
- Ensure your **VirtIO drivers** (installed in previous guides) are working correctly.
    

### 2. Install WinFsp (Windows File System Proxy)

WinFsp allows Windows to create custom file systems, functioning similarly to FUSE on Linux.

1. Download the latest stable WinFsp installer (.msi) from the official GitHub:
    
    GitHub: WinFsp Releases
    
2. Run the installer and click through the default options (Next > Next > Install).
if you dont have a browser and want to downlaoded it driectly from the website using command prompt you can do this, make sure where the path is and thats where it'll be saved. 
```bash
Invoke-WebRequest -Uri "https://github.com/winfsp/winfsp/releases/download/v2.1/winfsp-2.1.25156.msi" -OutFile "winfsp.msi"
```

or from github
```bash
https://github.com/winfsp/winfsp/releases
```

### 3. Enable the VirtIO-FS Service

The VirtIO drivers include a specific service for handling these file shares, but it might not start automatically by default.

1. Click the Windows + R type `services.msc`, and press **Enter**.
    
2. Scroll down the list and locate **VirtIO-FS Service**.
    
3. **Right-click** the service and select **Properties**.
    
4. Change the **Startup type** to `Automatic`.
    
5. Click the **Start** button to run the service immediately.
    
6. Click **Apply** and **OK**.
    

> [!info] Can't find the Service?
> 
> If VirtIO-FS Service is missing from the list, it means the VirtIO Guest Tools (specifically the drivers from the ISO) were not installed correctly in the earlier steps. Re-install the VirtIO drivers.

## Part 3: Accessing the Files

If the service started successfully, the drive is now mounted.

1. Open **File Explorer** in Windows.
    
2. Look under "This PC".
    
3. You should see a new Network Drive or System Drive (often mapped to `Z:`), labeled with the **Target path** name you chose earlier (e.g., `host zram1`).
    

> [!success] Setup Complete
> 
> You now have high-performance, low-latency file sharing between your Arch Linux host and Windows guest.