1. Make sure to Enable the Bios Options for vt-d iommu and stuff. 
2. [[Virt_Manager Packages for Windows]]
3. [[KVM preperation and Optimization]]
4. [[Host PC  Preparation for GPU isolation]]
5.  [[VirtIO win driver iso]]
6. [[+ MOC Windows Installation Through Virt Manager]]
7. [[Windows Configurations for Passthrough]]
8. [[Looking Glass]]
9. Verification
> [!danger] VERY IMPORTANT TO CHECK THIS
Run this command to check if everything is configured correctly:
> 
> ```bash
> virt-host-validate
> ```
> 
> You should see `PASS` for QEMU and KVM hardware virtualization. (Warnings for IOMMU are expected if you haven't enabled GPU passthrough parameters in your kernel bootloader).