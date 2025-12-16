# Windows Guest Setup & Software Downloads

This guide covers the necessary software to install inside your Windows Virtual Machine (VM) to enable Looking Glass and ensure the system runs smoothly.

> [!TIP] Workflow
> 
> Perform these steps inside your Windows VM. You can use the default SPICE view (Virt-Manager window) to download and install these files before Looking Glass is fully active.

## 1. Core Dependencies

Before installing the display drivers, you must ensure the C++ runtime is installed.

### Microsoft Visual C++ Redistributable

Required for the Virtual Display Driver and other tools to function.

1. Download the **latest supported Visual C++ Redistributable**.
    
2. Run the installer.
    

```http
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist
```

## 2. Virtual Display Driver (VDD)

This driver creates a "monitor" that exists only in memory, which Looking Glass allows you to view.

1. Download the latest release (zip file) from GitHub.
    
2. Extract the folder and instal. 

```http
https://github.com/VirtualDrivers/Virtual-Display-Driver
```

> [!DANGER] CRITICAL WARNING
> 
> Only install this driver ONCE.
> 
> Do not run the installer multiple times, or you will create multiple "ghost" monitors, which will cause  your cursor to constantly move to other invisible monitors when the cursor touches the screen edge. 

## 3. Looking Glass Host

This is the software that runs inside Windows and sends the video feed to your Linux host.

1. Download the **Windows Host Binary**
2. Run the installer.
    

**Official Website:**

```http
https://looking-glass.io/downloads
```
**GitHub (Alternative):**
```http
https://github.com/gnif/LookingGlass
```

## 4. Graphics Drivers

You must install the official NVIDIA drivers for your passed-through GPU.

1. Download the driver for your specific card.
    
2. Install it as you would on a normal PC.
    

```http
https://www.nvidia.com/en-us/drivers/
```

> [!WARNING] **DO NOT DISABLE DISPLAY DRIVERS**
> 
> - **Never** disable the NVIDIA Display Driver in Device Manager.
>     
> - **Never** disable the Virtual Display Driver (VDD) in Device Manager.
>     
> 
> If you somehow end up with _two_ Virtual Display Drivers, be extremely careful. If you disable the active one, you will lose video output. If you are unsure, restart the VM and check again before making changes.

## 5. System Utilities

### 7-Zip

A better file archiver (required for extracting some driver files).

```http
https://www.7-zip.org/
```

### O&O ShutUp10++

A free antispy tool to disable Windows telemetry and unwanted updates.

```http
https://www.oo-software.com/en/download/current/ooshutup10
```

### Windows Update MiniTool

Allows you to control exactly which Windows updates are installed, preventing Microsoft from overwriting your custom iso especially if you have it deblaoted of defender and other stuff. 

```http
https://www.majorgeeks.com/files/details/windows_update_minitool.html
```

### WinFSP should already have been installed in one of the previous steps, if not , here's the link. 
```http
https://github.com/winfsp/winfsp
```

## 6. Troubleshooting & Specific Quirks

### VirtIO-FS Service

If you configured filesystem sharing, the **VirtIO-FS Service** will only appear in your services list _after_ the `virtio-win` ISO drivers are fully installed.


### Cursor Disappearing

Sometimes, enabling the VirtIO mouse driver causes the cursor to vanish.

- **Fix:** Uninstall the mouse driver in Device Manager, then reinstall it while viewing the VM through the Looking Glass client.
or 
**(THIS ONE WORKS, TESTED!!)**
**uninstall the virio driver using the x64 file in cd drive virtio and then resintall it after restarting the vm.** 
