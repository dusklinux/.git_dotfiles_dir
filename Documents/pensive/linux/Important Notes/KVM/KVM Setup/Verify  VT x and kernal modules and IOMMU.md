Before beginning, enable virtualization and IOMMU in your BIOS/UEFI (Intel VT-x and VT-d on your Intel CPU). Verify support with:

```bash
lscpu | grep Virtualization   # should show "VT-x" for Intel CPU:contentReference[oaicite:0]{index=0} 
sudo dmesg | grep -e DMAR -e IOMMU # on reboot should indicate IOMMU enabled
```

kernal modules 
```bash
zgrep CONFIG_KVM /proc/config.gz
```

look for `CONFIG_KVM=` and `CONFIG_KVM_VFIO=` should either be set to y or m
`Yes (always installed)`
`Loadable module (can install and uninstall as needed)`
