get the ids. 
```bash
lspci -nn | grep -E "NVIDIA"
```

kernal parambers with systemd boot or do grub. 
```bash
sudo nvim /boot/loader/entries/arch.conf
```

add these in teh same line as zswap.enabled=0
```ini
intel_iommu=on iommu=pt vfio-pci.ids=10de:25a0,10de:2291 module_blacklist=nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm,nouveau
```

```bash
sudo nvim /etc/mkinitcpio.conf
```
if you have any more moduels other than btrfs, keep them there. dont remove. 
```ini
MODULES=(btrfs vfio_pci vfio vfio_iommu_type1)
```

eg, modconf and kms are what matter
```ini
HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)
```

blacklisting nvidia, also add your ids. 
```bash
sudo nvim /etc/modprobe.d/vfio.conf
```

```ini
options vfio-pci ids=10de:25a0,10de:2291
softdep nvidia pre: vfio-pci
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
```

regerneage initramfs
```bash
sudo mkinitcpio -P 
```

check if vfio drivers are in use for nvidia. 

```bash
lspci -nnk -d 10de:25a0
```

```bash
lspci -k | grep -E "vfio-pci|NVIDIA"
```

```bash
sudo dmesg | grep -i vfio
```



===

---
---

```bash
sudo pacman --needed -S qemu-full libvirt virt-install virt-manager virt-viewer dnsmasq bridge-utils openbsd-netcat edk2-ovmf swtpm iptables-nft libosinfo
```
yes, remove and replace your iptables with iptables-nft if prompted. 

```bash
sudo systemctl enable --now libvirtd
```

```bash
sudo nvim /etc/libvirt/libvirtd.conf
```

```ini
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
```

```bash
sudo usermod -aG libvirt,kvm,input,disk "$(id -un)"
```

```bash
sudo virsh net-start default
sudo virsh net-autostart default
```



---
---

open virt manager. 

You should definitely install it using the **System (Root) Connection** (`qemu:///system`), NOT the User session (`qemu:///session`).
"QEMU/KVM User session". This will cause major headaches for GPU passthrough.

always choose bridge device for networking for easier sshing later. 
also always check,  Customize configuration before install

chipset q35, uefi. 