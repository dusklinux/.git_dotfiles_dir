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
intel_iommu=on iommu=pt vfio-pci.ids=10de:25a0,10de:2291
```
create this line and add the ids. 
```bash
sudo nvim /etc/modprobe.d/vfio.conf
```

```ini
options vfio-pci ids=10de:25a0,10de:2291
softdep nvidia pre: vfio-pci
```

regerneage initramfs
```bash
sudo mkinitcpio -P 
```

check if vfio drivers are in use for nvidia. 
```bash
lspci -k | grep -E "vfio-pci|NVIDIA"
```