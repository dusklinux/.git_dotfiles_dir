

Enable IOMMU in the kernel by editing your boot loader entry 

```bash
sudo nvim /etc/default/grub
```

add 

```bash
intel_iommu=on iommu=pt
```
to GRUB_CMDLINE_LINUX) and regenerate grub and then reboot. 



Regenerated Grub 
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```