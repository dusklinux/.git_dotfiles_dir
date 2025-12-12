# Arch Linux KVM/QEMU Setup: Installation & Permissions

This guide outlines the process of setting up a Type-1 Hypervisor environment on Arch Linux using KVM (Kernel-based Virtual Machine). This is specifically tailored for running Windows guests with near-native performance.

## 1. Package Installation

We need a specific suite of tools to handle the hypervisor (KVM), the emulator (QEMU), and the management interface (Virt-Manager).

Run the following command in your terminal:

```bash
sudo pacman --needed -S qemu-full libvirt virt-install virt-manager virt-viewer dnsmasq iproute2 openbsd-netcat edk2-ovmf swtpm iptables-nft libosinfo
```

> [!TIP] Firewall Selection
> 
> If prompted to replace iptables with iptables-nft, answer YES (type y and hit Enter). Arch Linux is moving to nftables as the backend, and this package ensures libvirt can correctly manage network rules using the modern standard.

### 📦 Understanding the Packages

If you are curious about what you just installed, expand the section below.

> [!INFO]- Package Breakdown
> 
> - **`qemu-full`**: The core emulator. It performs the actual hardware emulation for the Guest OS.
>     
> - **`libvirt`**: The backend daemon (service) that manages virtualization technologies. It provides the "brain" for the operation.
>     
> - **`virt-manager`**: The GUI frontend. This is the app you will open to click buttons and manage VMs.
>     
> - **`virt-install`**: A command-line tool to provision new VMs (used by the GUI in the background).
>     
> - **`virt-viewer`**: Utility for displaying the graphical screen of the VM.
>     
> - **`dnsmasq`**: Required by libvirt to provide internet access (DNS/DHCP) to VMs via NAT.
>     
> - **`bridge-utils`**: Utilities for configuring Linux ethernet bridges (useful for advanced networking).
>     
> - **`openbsd-netcat`**: Allows for remote management of KVM over SSH.
>     
> - **`edk2-ovmf`**: The UEFI Firmware. **Essential** for modern Windows 11 setups (requires Secure Boot/UEFI support).
>     
> - **`swtpm`**: Software TPM emulator. **Mandatory for Windows 11**, which requires a Trusted Platform Module to install.
>     
> - **`iptables-nft`**: The firewall backend used for network address translation (NAT).
>     
> - **`libosinfo`**: A database that allows `virt-manager` to automatically configure optimal defaults (like drivers and RAM) when you select "Windows 11".
>     

## 2. Permission Configuration

By default, only the `root` user can manage virtual machines. To use `virt-manager` as your normal user without typing your password constantly, we need to configure `libvirt` permissions.

### Step A: Edit Libvirt Configuration

We need to tell `libvirt` to allow a specific group of users to manage the system.

1. Open the configuration file using `nvim` (or your preferred editor):

```bash
sudo nvim /etc/libvirt/libvirtd.conf
```

2. You need to add specific permissions to this file.

The easiest way is to scroll to the very bottom of the file and paste the following block:

```bash
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
```
    
> [!NOTE] Explanation of Settings
    > - **`unix_sock_group`**: Defines that the system group named "libvirt" owns the management socket.
    >     
    > - **`unix_sock_rw_perms`**: Sets permissions to "0770". This means the Owner and the Group have Read/Write access, while strangers have none.
    >     
    
3. Save and exit the file (`:wq` in nvim).