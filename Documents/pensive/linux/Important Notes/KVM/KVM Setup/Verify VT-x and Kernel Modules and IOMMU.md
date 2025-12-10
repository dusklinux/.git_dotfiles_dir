# Prerequisites & Hardware Verification

Before installing any software, we need to ensure your computer's hardware is capable of virtualization and that these features are enabled in your BIOS/UEFI.

## Step 1: BIOS/UEFI Configuration

You must enter your BIOS/UEFI settings (usually by pressing `Del`, `F2`, or `F12` during boot) and enable the following settings. These are often found under **CPU Configuration**, **System Agent**, or **Advanced** tabs.

> [!tip] Settings to Enable
> 
> 1. **Virtualization Technology:** Often labeled as **Intel VT-x** (or _SVM_ for AMD users).
>     
> 2. **IOMMU:** Often labeled as **Intel VT-d** (or _AMD-Vi_ / _IOMMU_ for AMD users).
>     

Once enabled, save your changes and reboot into Arch Linux.

## Step 2: Verification

Open your terminal. We will run a few checks to confirm the hardware features are active and the Linux kernel is ready.

### 1. Verify CPU Virtualization Support

Check if the CPU flags are active.

```bash
lscpu | grep Virtualization
```

> [!check] Expected Output
> 
> You should see VT-x (for Intel) or AMD-V (for AMD). If this returns nothing, check your BIOS settings again.

### 2. Verify IOMMU Detection

Check the kernel ring buffer to ensure the Input-Output Memory Management Unit (IOMMU) groups are being detected.

```bash
sudo dmesg | grep -e DMAR -e IOMMU
```

> [!info] What to look for
> 
> You are looking for lines indicating that IOMMU or DMAR (DMA Remapping) is enabled and tables are being read. If you see no output, IOMMU might be disabled in BIOS or requires kernel parameters (which we will handle in later steps).

### 3. Verify Kernel Modules

We need to ensure your running Kernel was compiled with KVM and VFIO support.

```
zgrep CONFIG_KVM /proc/config.gz
```

> [!example] Understanding the Results
> 
> You will see lines ending in =y or =m.
>  - look for `CONFIG_KVM=` and `CONFIG_KVM_VFIO=` should either be set to y or m
> - **`=y`**: The feature is built directly into the kernel (Always active).
>     
> - **`=m`**: The feature is a **Loadable Module** (Can be loaded/unloaded as needed).
>     
> 
> _Arch Linux default kernels usually have these set to `m`._