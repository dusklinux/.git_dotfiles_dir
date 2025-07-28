# Overview: Installing Windows 11 on KVM

This guide provides a clear, step-by-step path to installing and optimizing a Windows 11 virtual machine using KVM. Each step links to a detailed note for more in-depth instructions, ensuring a smooth and successful setup.

---

### 1. [[Configure Windows 11 Virtual Hardware]]
This initial phase involves setting up the foundational hardware for your virtual machine to ensure optimal performance and compatibility.

*   **1.1. [[Configure Default Virtual Hardware Using the Wizard]]**
    > Use the Virtual Machine Manager wizard to create the initial VM. This includes selecting the Windows 11 ISO, allocating CPU and RAM, and creating a virtual disk.

*   **1.2. [[Configure Chipset and Firmware]]**
    > Set the chipset to `Q35` and firmware to `UEFI`. This is crucial for modern features and is a requirement for Windows 11's Secure Boot.

*   **1.3. [[Enable Hyper-V Enlightenments]]**
    > Enhance performance by adding specific Hyper-V features to the VM's XML configuration, allowing the guest OS to work more efficiently with the KVM hypervisor.

*   **1.4. [[Enable CPU Host-Passthrough]]**
    > Maximize processing speed by allowing the virtual machine to directly use the host CPU's features and instruction sets.

*   **1.5. [[Configure the Storage]]**
    > Switch the virtual disk bus to `VirtIO` for faster storage I/O. You'll also configure cache and discard settings for better efficiency.

*   **1.6. [[Mount the VirtIO-Win ISO Image]]**
    > Attach the VirtIO drivers ISO as a second CDROM. These drivers are essential for Windows to recognize the virtual hardware during installation.

*   **1.7. [[Configure Virtual Network Interface]]**
    > Change the network card's device model to `virtio` to achieve near-native network speeds by reducing virtualization overhead.

*   **1.8. [[Remove the USB Tablet Device]]**
    > A simple tweak to improve performance by removing the default virtual tablet, which can reduce idle CPU usage.

*   **1.9. [[Add QEMU Guest Agent Channel]]**
    > Establish a communication channel between the host and guest. This enables features like graceful shutdowns and retrieving guest information from the host.

*   **1.10. [[Enable Trusted Platform Module (TPM)]]**
    > Activate the emulated TPM 2.0 module, a mandatory security requirement for installing and running Windows 11.

### 2. [[Install a Windows 11 Virtual Machine on KVM]]
With the hardware configured, this step walks you through the actual OS installation. This includes loading the necessary `VirtIO` drivers for storage and networking and installing the guest tools package post-installation for a seamless experience.

### 3. [[Optional Enable Hardware Security on Windows 11]]
For those seeking maximum security, this optional guide shows you how to enable Core Isolation (Memory Integrity). This provides an extra layer of protection against malware by modifying the VM's CPU configuration.

### 4. [[Optimize Windows 11 Performance]]
After installation, apply these tweaks to make your Windows 11 VM run faster and smoother.

*   **4.1. [[Disable SuperFetch]]**
    > Turn off the `SysMain` service to reduce background CPU and RAM usage.

*   **4.2. [[Disable Windows Web Search]]**
    > Modify the registry to prevent the Start Menu from showing web results, speeding up local searches.

*   **4.3. [[Disable useplatformclock]]**
    > Run a simple command to disable a clock setting that can cause performance issues with Hyper-V enlightenments enabled.

*   **4.4. [[Disable Unnecessary Scheduled Tasks]]**
    > Free up resources by disabling non-essential background tasks like automatic defragmentation.

*   **4.5. [[Disable Unnecessary Startup Programs]]**
    > Improve boot times and reduce resource consumption by managing which applications launch when Windows starts.

*   **4.6. [[Adjust the Visual Effects in Windows 11]]**
    > Turn off animations and other graphical effects to prioritize performance over aesthetics.

### 5. [[Setting up Shared Directory Between Guest_win11 and Host ]]
This step guides you on creating a shared folder accessible by both your host machine and the Windows 11 guest, making file transfers between them effortless.

### 6. [[Conclusion Win]]
A final wrap-up of the process, acknowledging that while the guide covers the most critical steps, further optimizations are always possible for power users.


### 7. [[Resize aka extend storage after os is already installed]]