# Arch Linux KVM/QEMU Setup Guide for Windows

This guide outlines the complete process of setting up a Type-1 Hypervisor environment on Arch Linux using KVM (Kernel-based Virtual Machine) specifically tailored for running Windows guests.

## 1. Package Installation

We need a suite of tools to handle the hypervisor (KVM), the emulator (QEMU), and the management interface (Libvirt/Virt-Manager).

```bash
sudo pacman --needed -S qemu-full libvirt virt-install virt-manager virt-viewer dnsmasq bridge-utils openbsd-netcat edk2-ovmf swtpm iptables-nft libosinfo
```

### Breakdown of Packages:

> [!NOTE]-
> - **`qemu-full`**: The core emulator. It performs the actual hardware emulation for the Guest OS.
>     
> - **`libvirt`**: The backend daemon that manages virtualization technologies (KVM, QEMU, Xen, etc.). It provides the API.
>     
> - **`virt-manager`**: The GUI frontend for managing VMs (what you'll actually click on).
>     
> - **`virt-install`**: Command-line tool to provision new VMs.
>     
> - **`virt-viewer`**: Utility for displaying the graphical console of the VM (SPICE/VNC).
>     
> - **`dnsmasq`**: Required by libvirt to provide DNS and DHCP services to the VMs (NAT networking).
>     
> - **`bridge-utils`**: Utilities for configuring the Linux ethernet bridge (needed if you ever want Bridged networking).
>     
> - **`openbsd-netcat`**: Allows for remote management of KVM over SSH.
>     
> - **`edk2-ovmf`**: The UEFI Firmware. Essential for modern Windows 11 setups (requires Secure Boot/UEFI support).
>     
> - **`swtpm`**: Software TPM emulator. **Mandatory for Windows 11**, which requires a Trusted Platform Module.
>     
> - **`iptables-nft`**: The firewall backend. Libvirt uses firewall rules to handle NAT.
> 
> - **`libosinfo`**: Database of OS information that allows `virt-manager` to automatically configure optimal defaults for specific Windows versions.    

If prompted to replace `iptables` with `iptables-nft`, answer **YES**. Arch is moving to nftables as the backend, and this package provides the translation layer._

## 2. Permission Configuration

By default, only `root` can manage VMs. We need to configure `libvirt` to allow your user account to manage the system via a UNIX socket.

### Edit Libvirt Configuration

Open the configuration file:

```bash
sudo nvim /etc/libvirt/libvirtd.conf
```

Find and uncomment (remove the `#`) the following lines to set the group ownership and permissions for the socket: or just copy the text below and paste it in the file. without needing to find where the lines are and then uncommenting them. 

```ini
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
```

- **Why:**
- `unix_sock_group`: Defines which system group owns the socket.
- `unix_sock_rw_perms`: Gives Read/Write (7) permission to Owner and Group, and None (0) to Others.





