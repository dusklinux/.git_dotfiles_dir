# Overview: Installing Windows on KVM

> [!SUMMARY] Goal
> 
> This guide provides a clear, linear path to installing and optimizing a Windows virtual machine using KVM (Kernel-based Virtual Machine) via Virt-Manager.
> 
> Follow the steps in order. Each section links to a detailed note with specific instructions.

## 1. [[Configure Windows Virtual Hardware]]

This initial phase involves setting up the physical "bones" of your virtual machine. We will configure the hardware before we even attempt to install the operating system to ensure best performance.

- **1.1. [[Configure Default Virtual Hardware Using the Wizard]]**
    
    - Use the **Virtual Machine Manager** wizard to create the base VM. You will select the Windows 11 ISO, allocate CPU/RAM, and create a virtual disk here.
        
- **1.2. [[Configure Chipset and Firmware]]**
    
    - Set the chipset to `Q35` and firmware to `UEFI`. This is required for modern features and Windows 11's Secure Boot.
        
- **1.3. [[Enable Hyper-V Enlightenments]]**
    
    - Add specific metadata to the VM's configuration. This tells Windows it is running inside a VM, allowing it to "cooperate" with the Linux host for better efficiency.
        
- **1.4. [[Enable CPU Host-Passthrough]]**
    
    - **Crucial for speed.** This allows the VM to see and use your actual CPU model and instruction sets rather than a generic, slower emulated CPU.
        
- **1.5. [[Configure the Storage]]** (USE virtio + Option 2)
    
    - Switch the hard drive bus to `VirtIO`. This is a specialized driver that is much faster than standard SATA emulation.
        
- **1.6. [[Mount the VirtIO-Win ISO Image]]**
    
    - Attach the "VirtIO Drivers" CD. Windows does not understand Linux virtual hardware by default; this CD contains the translators (drivers) it needs during installation.
        
- **1.7. [[Network Bridging for LAN access]]**
    
    - Change the network model to `virtio`. This reduces overhead and provides near-native internet speeds inside the VM.
        
- **1.8. [[Remove the USB Tablet Device]]**
    
    - A quick cleanup step. Removing this default input device can reduce idle CPU usage.
        
- **1.9. [[Add QEMU Guest Agent Channel]]** (Optional)
    
    - create a communication wire between the Host (Linux) and Guest (Windows). This allows you to issue shutdown commands gracefully from the Linux side.
        
- **1.10. [[Enable Trusted Platform Module (TPM)]]** **Win11 only**
    
    - **Requirement:** Add an emulated TPM 2.0 device.
        
    - This step is **not required** if you are using a custom "de-bloated" Windows ISO that has the TPM requirement patched out.
        

## 2. [[Install a Windows Virtual Machine on KVM]]

With the hardware ready, we proceed to the actual installation.

- This guide covers loading the **VirtIO drivers** so Windows can actually "see" your hard drive.
    
- It also covers installing the **Guest Tools** after Windows boots up for the first time.
    

## 3. **OPTIONAL** Recommanded to skip this step [[Optional Enable Hardware Security on Windows]]

> [!DANGER] Performance Warning
> 
> This step enables Core Isolation (Memory Integrity).
> 
> While it increases security against sophisticated malware, it incurs a significant performance penalty in a virtualized environment.
> 
> Status: NOT RECOMMENDED for gaming or daily driving unless you have strict security compliance needs.

## 4. [[Optimize Windows Performance]]

Windows 11 is heavy by default. These steps strip back unnecessary background processes to keep your VM snappy.

- **4.1. [[Disable SysMain]]**
    
    - Disable the `SysMain` service to stop Windows from constantly pre-loading apps into RAM.
        
- **4.2. [[Disable Windows Web Search]]**
    
    - Registry tweak to stop the Start Menu from searching Bing when you are just looking for a file.
        
- **4.3. [[Disable useplatformclock]]**
    
    - A command-line fix to ensure the VM's internal clock doesn't drift or cause stuttering.
        
- **4.4. [[Disable Unnecessary Scheduled Tasks]]**
    
    - Stop Windows from running defragmentation or telemetry tasks while you are trying to work.
        
- **4.5. [[Disable Unnecessary Startup Programs]]**
    
    - Reduce boot time by cleaning up the autostart list.
        
- **4.6. [[Adjust the Visual Effects in Windows 11]]**
    
    - Turn off transparency and animations to prioritize raw speed over aesthetics.
        

## 5. [[Setting up Shared Directory Between Guest_win11 and Host ]]

Learn how to create a folder that exists on your Linux Host but appears as a Network Drive inside Windows. This is the fastest way to move files back and forth.

## 6. [[Conclusion Win]]

A summary of what has been achieved. Your VM should now be installed, driver-optimized, and de-bloated.

## 7. [[Resize aka extend storage after os is already installed]]

> [!TIP] Future Maintenance
> 
> Use this guide if you run out of space later. It explains how to expand the virtual disk image (.qcow2) and then tell Windows to use the new empty space.