| Package          | Purpose                                                                                                                                            |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `qemu-full`      | Full qemu suite,  This is the QEMU hypervisor, responsible for actual VM emulation/execution.                                                      |
| `libvirt`        | Provides a daemon (`libvirtd`) and API for managing virtualization platforms. Abstracts VM creation, network, and storage.                         |
| `virt-install`   | Command line tool for creating new KVM, Linux<br>container guests using the libvirt hypervisor                                                     |
| `virt-manager`   | GUI frontend for libvirt. Simplifies VM management using a GTK interface.                                                                          |
| `virt-viewer`    | Lightweight graphical display tool for connecting to virtual machines via SPICE or VNC.                                                            |
| `dnsmasq`        | Provides DHCP/DNS services to VMs for `nat`-based libvirt networks. Essential for automatic IP assignment.                                         |
| vde2             |                                                                                                                                                    |
| `ebtables-git`   | paru -S ebtables-git but no longer needed, Ethernet bridge firewalling utility. Ensures correct filtering and NAT when VMs use bridged networking. |
| `bridge-utils`   | Tools for managing `br0` bridges, required for bridged networking (i.e., VMs sharing host’s NIC).                                                  |
| `openbsd-netcat` | Network debugging and scripting tool. Used by libvirt to handle certain socket-based communications.                                               |
| `edk2-ovmf`      | UEFI firmware for virtual machines. Required for booting Windows 11/macOS with Secure Boot & TPM.                                                  |
| `swtpm`          | Software TPM 2.0 emulator. Required for Windows 11 VM compliance and security testing.                                                             |
| `virtio-win`     | Contains VirtIO drivers for Windows (paravirtualized storage/network). Greatly enhances performance of Windows guests.                             |
| `tuned`          |                                                                                                                                                    |
| `qemu-img`       | QEMU tooling for manipulating disk images                                                                                                          |
| `guestfs-tools`  | Tools for accessing and modifying guest disk images                                                                                                |
| `iptables-nft`   |                                                                                                                                                    |
| `libosinfo`      |                                                                                                                                                    |
| `spice-vdagent`  | Spice agent for Linux guests (for better windows integration )                                                                                     |
|                  |                                                                                                                                                    |


```bash
sudo pacman -S --needed qemu-full libvirt virt-install virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat edk2-ovmf tuned qemu-img guestfs-tools iptables-nft libosinfo
```

```bash
paru -S virtio-win
```

>[!note]+ The downloaded virtio-win image is placed here. 
>```bash
>ls -lah /var/lib/libvirt/images
>```


windows specific

```bash
sudo pacman --needed -S qemu-full libvirt virt-install virt-manager virt-viewer dnsmasq bridge-utils openbsd-netcat edk2-ovmf swtpm iptables-nft libosinfo
```

```bash
sudo systemctl enable --now libvirtd
```

```bash
sudo usermod -aG libvirt,kvm,input,disk dusk
```

logout and relogin. 
macos specific

```bash

```