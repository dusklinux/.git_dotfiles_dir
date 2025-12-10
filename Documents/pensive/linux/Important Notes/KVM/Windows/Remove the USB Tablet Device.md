# Performance Tuning: Removing the USB Tablet Device

In a Windows virtual machine, the default **USB Tablet** input device is often added to allow the mouse cursor to move seamlessly between the host and the guest without "clicking" into the window.

However, this device can cause significant performance overhead because it constantly polls the CPU to check the cursor position, even when the system is idle.

> [!abstract] Performance Impact
> 
> Removing the USB Tablet device reduces idle CPU usage and unnecessary context switches. This results in a smoother, more responsive Windows experience.

### Instructions

Follow these steps to remove the device:

1. In the left sidebar, locate and click on **Tablet** (usually listed under Input).
    
2. Click the **Remove** button at the bottom right of the window.
    

> [!warning] Important: Mouse Behavior Change
> 
> Once the Tablet device is removed, your mouse might be "captured" inside the VM window when you click on it.
> 
> To release your mouse cursor back to your host Linux system, press the release key combination (usually `Left Ctrl` + `Left Alt` by default).