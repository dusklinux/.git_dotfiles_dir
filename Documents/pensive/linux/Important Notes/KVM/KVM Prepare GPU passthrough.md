Identify your NVIDIA GPU’s PCI IDs e.g. 
```bash
lspci -nn | grep NVIDIA
```

 Then bind it to VFIO so Linux won’t use it. You can do this by adding a module option or kernel parameter. For example, create /etc/modprobe.d/vfio.conf but (Use your GPU’s vendor:device IDs.)
 
> [!warning] use your gpu's vender: device ID , dont use the one in example command

```bash
options vfio-pci ids=10de:2481,10de:228b
```

Then regenerate initramfs so VFIO loads early:

```bash
sudo mkinitcpio -P
```

Also enable IOMMU in the kernel by editing your boot loader entry 

```bash
sudo nvim /etc/default/grub
```

add intel_iommu=on iommu=pt to GRUB_CMDLINE_LINUX) and regenerate grub and then reboot. 

Confirm vfio-pci is now driving your GPU (lspci -nnk should show Kernel driver in use: vfio-pci for the NVIDIA card)