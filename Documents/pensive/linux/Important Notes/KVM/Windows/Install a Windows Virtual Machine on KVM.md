# Windows Installation & VirtIO Drivers

Now that you have configured the virtual hardware and clicked **Begin Installation**, the Windows 11 setup will launch. You will encounter a step where you must select the installation drive, but the list will likely be empty.

This is expected behavior. You selected the **VirtIO** disk bus for better performance, but Windows does not recognize VirtIO devices natively. We must manually load the drivers from the attached `virtio-win` ISO.

## 1. Loading the Storage Driver

1. On the drive selection screen, click **Load driver**.
    
2. Click **Browse**.
    
3. Navigate to the **CD Drive (E:)** (This is the VirtIO ISO).
    
4. Expand the folders: `Viostor` -> `w10` or `w11` -> `amd64`.
    
5. With `amd64` selected, click **OK**.
    
6. Select the `Red Hat VirtIO SCSI controller` driver listed and click **Next** to install it.
    
 
## If for some reason you want access to the internet even during the setup process, You need to install the network driver. (Not recomanded to install)

## 2. Loading the Network Driver

Repeat the procedure above for the network interface:

1. Click **Load driver** again.
    
2. Click **Browse**.
    
3. Navigate to **CD Drive (E:)**.
    
4. Expand the folders: `NetKVM` -> `w10` or `w11` -> `amd64`.
    
5. Click **OK**.
    
6. Select the driver and install it.
    

Once both the Disk and Network drivers are loaded, your virtual disk should appear. Select it and click **Next** to proceed with the Windows installation.

## 3. Installing VirtIO Guest Tools

After Windows finishes installing and you boot into the desktop for the first time, you must install the **VirtIO Windows Guest Tools**. This package acts like "Guest Additions" in other hypervisors—it installs the QXL video driver and the SPICE guest agent, enabling features like:

- Copy and paste between host and guest. (although more configuration is needed for this)
    
- Automatic resolution switching.
    
- Improved mouse integration.
    

### Steps to Install:

1. Open **File Explorer** inside the VM.
    
2. Navigate to **CD Drive (E:)**.
    
3. Double-click the `virtio-win-guest-tools` executable to launch the installer.
    

> [!tip] Which file to choose?
> 
> Ensure you run the virtio-win-guest-tools package. Do not run the specific x64 or x86 MSI files unless you know exactly what you are doing; the guest tools installer handles everything automatically. if your curson disappears, you can remove the driver using the x64 pacakge. and then reinstall virtio drivers

## 4. Enabling Auto-Resize

Now that the Guest Tools are installed, you can enable the display to automatically adjust to your window size.

1. In the Virt-Manager window (the viewer window), look at the top menu bar.
    
2. Click **View** -> **Scale Display**.
    
3. Check the box for **Auto resize VM with window**.
    

Try resizing the window now; the Windows 11 resolution should snap to fit perfectly.

## 5. Cleanup: Removing Installation Media

The installation is complete. Shut down the Windows virtual machine to remove the installation media.

1. In the Virt-Manager main window, ensure the VM is **Shutoff**.
    
2. Click the **Lightbulb Icon** (Show virtual hardware details) in the toolbar.
    
3. Select the **SATA CDROM 2** (The VirtIO ISO). (recommended to leave it attached, dont remove.)
    
4. Click **Remove** (or unmount the ISO).
    
5. Select the **SATA CDROM 1** (The Windows Installer ISO).
    
6. Click **Disconnect** or remove the ISO path so the drive is empty.
    

![[Pasted image 20250726223648.png]]

You are now ready to use your optimized Windows 11 VM.