# GPU Isolation and VFIO Binding Guide (Arch Linux)

This guide details the process of isolating a dedicated NVIDIA GPU on an Arch Linux laptop (with Intel iGPU) to prevent the host Linux kernel from touching it. This allows the GPU to be passed through to a Virtual Machine (KVM/QEMU).

> [!WARNING] CRITICAL: MUX Switch Configuration
> 
> Since this is a laptop with a MUX switch:
> 
> Ensure your BIOS/UEFI is set to Hybrid Mode (Optimus) or iGPU Mode.
> 
> If you set the MUX to "Discrete/NVIDIA only" and then follow this guide to isolate the NVIDIA card, you will boot into a black screen because the OS will have no GPU driver available to render the display.

## Phase 1: Identification & Preparation

Before changing configuration files, we must identify the specific hardware addresses of the GPU and ensure the hardware supports isolation.

### 1.1 Identify GPU PCI IDs

We need the hex codes (Vendor:Product) for the GPU and its associated Audio Controller.

```
lspci -nn | grep -E "NVIDIA|VGA"
```

> [!NOTE]- What you'll see. 
> ```ini
>  lspci -nn | grep -E "NVIDIA|VGA"
> 00:02.0 VGA compatible controller [0300]: Intel Corporation Alder Lake-P GT2 [Iris Xe Graphics] [8086:46a6] (rev 0c)
> 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA107M [GeForce RTX 3050 Ti Mobile] [10de:25a0] (rev a1)
> 01:00.1 Audio device [0403]: NVIDIA Corporation GA107 High Definition Audio Controller [10de:2291] (rev a1)
> ```

**What this does:**

- `lspci`: Lists all PCI devices.
    
- `-nn`: Shows both the device name and the numeric IDs (e.g., `[10de:25a0]`).
    
- `grep`: Filters for NVIDIA or VGA devices.
    

**Your IDs (Example based on input):**

- **3D Controller:** `10de:25a0` (RTX 3050 ti Mobile)
    
- **Audio Controller:** `10de:2291` (NVIDIA Audio)
    
- _Note: You must isolate both._
    

### 1.2 Check IOMMU Groups (Crucial)

Passthrough requires the GPU to be in its own "IOMMU Group". If it shares a group with the Ethernet card or USB controller, you cannot pass it through without patching the kernel (ACS Override).

Copy this script into your terminal to check:

for zsh 
```zsh
#!/bin/zsh
setopt NULL_GLOB
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

**OR**

for bash
```
#!/bin/bash
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

> [!NOTE]- What the output will look like
> ```zsh
> dusk  ~  #!/bin/zsh
> setopt NULL_GLOB
> for g in /sys/kernel/iommu_groups/*; do
>     echo "IOMMU Group ${g##*/}:"
>     for d in $g/devices/*; do
>         echo -e "\t$(lspci -nns ${d##*/})"
>     done;
> done;
> IOMMU Group 0:
> 	00:02.0 VGA compatible controller [0300]: Intel Corporation Alder Lake-P GT2 [Iris Xe Graphics] [8086:46a6] (rev 0c)
> IOMMU Group 1:
> 	00:00.0 Host bridge [0600]: Intel Corporation 12th Gen Core Processor Host Bridge/DRAM Registers [8086:4641] (rev 02)
> IOMMU Group 10:
> 	00:14.0 USB controller [0c03]: Intel Corporation Alder Lake PCH USB 3.2 xHCI Host Controller [8086:51ed] (rev 01)
> 	00:14.2 RAM memory [0500]: Intel Corporation Alder Lake PCH Shared SRAM [8086:51ef] (rev 01)
> IOMMU Group 11:
> 	00:14.3 Network controller [0280]: Intel Corporation Alder Lake-P PCH CNVi WiFi [8086:51f0] (rev 01)
> IOMMU Group 12:
> 	00:15.0 Serial bus controller [0c80]: Intel Corporation Alder Lake PCH Serial IO I2C Controller #0 [8086:51e8] (rev 01)
> 	00:15.2 Serial bus controller [0c80]: Intel Corporation Alder Lake PCH Serial IO I2C Controller #2 [8086:51ea] (rev 01)
> IOMMU Group 13:
> 	00:16.0 Communication controller [0780]: Intel Corporation Alder Lake PCH HECI Controller [8086:51e0] (rev 01)
> IOMMU Group 14:
> 	00:1f.0 ISA bridge [0601]: Intel Corporation Alder Lake PCH eSPI Controller [8086:5182] (rev 01)
> 	00:1f.3 Audio device [0403]: Intel Corporation Alder Lake PCH-P High Definition Audio Controller [8086:51c8] (rev 01)
> 	00:1f.4 SMBus [0c05]: Intel Corporation Alder Lake PCH-P SMBus Host Controller [8086:51a3] (rev 01)
> 	00:1f.5 Serial bus controller [0c80]: Intel Corporation Alder Lake-P PCH SPI Controller [8086:51a4] (rev 01)
> IOMMU Group 15:
> 	01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA107M [GeForce RTX 3050 Ti Mobile] [10de:25a0] (rev a1)
> 	01:00.1 Audio device [0403]: NVIDIA Corporation GA107 High Definition Audio Controller [10de:2291] (rev a1)
> IOMMU Group 16:
> 	02:00.0 Non-Volatile memory controller [0108]: Intel Corporation SSD 670p Series [Keystone Harbor] [8086:f1aa] (rev 03)
> IOMMU Group 17:
> 	03:00.0 Non-Volatile memory controller [0108]: Samsung Electronics Co Ltd NVMe SSD Controller 980 (DRAM-less) [144d:a809]
> IOMMU Group 2:
> 	00:01.0 PCI bridge [0604]: Intel Corporation 12th Gen Core Processor PCI Express x16 Controller #1 [8086:460d] (rev 02)
> IOMMU Group 3:
> 	00:04.0 Signal processing controller [1180]: Intel Corporation Alder Lake Innovation Platform Framework Processor Participant [8086:461d] (rev 02)
> IOMMU Group 4:
> 	00:06.0 PCI bridge [0604]: Intel Corporation 12th Gen Core Processor PCI Express x4 Controller #0 [8086:464d] (rev 02)
> IOMMU Group 5:
> 	00:06.2 PCI bridge [0604]: Intel Corporation 12th Gen Core Processor PCI Express x4 Controller #2 [8086:463d] (rev 02)
> IOMMU Group 6:
> 	00:07.0 PCI bridge [0604]: Intel Corporation Alder Lake-P Thunderbolt 4 PCI Express Root Port #0 [8086:466e] (rev 02)
> IOMMU Group 7:
> 	00:08.0 System peripheral [0880]: Intel Corporation 12th Gen Core Processor Gaussian & Neural Accelerator [8086:464f] (rev 02)
> IOMMU Group 8:
> 	00:0a.0 Signal processing controller [1180]: Intel Corporation Platform Monitoring Technology [8086:467d] (rev 01)
> IOMMU Group 9:
> 	00:0d.0 USB controller [0c03]: Intel Corporation Alder Lake-P Thunderbolt 4 USB Controller [8086:461e] (rev 02)
> 	00:0d.2 USB controller [0c03]: Intel Corporation Alder Lake-P Thunderbolt 4 NHI #0 [8086:463e] (rev 02)
> ```

**Analysis:**

- Look for the group containing your NVIDIA IDs.
    
- Ideally, **only** the NVIDIA Video and NVIDIA Audio devices should be in that group.
    
- _If the PCIe Root Port is in the same group, that is usually acceptable._
    

## Phase 2: Bootloader Configuration (Systemd-boot)

We need to tell the Linux Kernel to turn on hardware virtualization features and reserve the GPU device IDs specifically for the `vfio-pci` driver before the OS even fully loads.

### 2.1 Edit Loader Entry

Open your main Arch entry file.

```
sudo nvim /boot/loader/entries/arch.conf
```

### 2.2 Append Kernel Parameters

Add the following to the end of the `options` line (same line as `root=...` and `rw`):

MAKE SURE TO CHANGE THE VFIO-CPI.IDS=  to match your specific ids for the gpu group. 
```
intel_iommu=on iommu=pt vfio-pci.ids=10de:25a0,10de:2291 module_blacklist=nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm,nouveau
```

**Explanation of parameters:**

- `intel_iommu=on`: Enables the IOMMU hardware feature on Intel CPUs (Required for mapping memory).
    
- `iommu=pt`: Sets "Passthrough" mode. This improves host performance by letting the host access devices directly without IOMMU translation overhead unless explicitly requested (by a VM).
    
- `vfio-pci.ids=xxxx:xxxx,yyyy:yyyy`: The "Silver Bullet". This tells the generic `vfio-pci` driver to grab these specific devices _immediately_ on boot.
    
- `module_blacklist=...`: Prevents the standard NVIDIA and Nouveau drivers from loading at the kernel level. This avoids "race conditions" where NVIDIA grabs the card before VFIO can.
    

> [!TIP] AMD Users
> 
> If you switch to an AMD CPU, change intel_iommu=on to amd_iommu=on. and remove nvidia.  If necessary, blacklist amd drivers.
> 
> If you switch to an AMD GPU, run lspci again to get the new IDs and update vfio-pci.ids=....

## Phase 3: Initramfs Configuration

The `initramfs` is the tiny filesystem loaded into RAM before the main disk is mounted. We need the VFIO modules to live here so they are available immediately.

### 3.1 Edit mkinitcpio.conf

```
sudo nvim /etc/mkinitcpio.conf
```

### 3.2 Update MODULES

Add the VFIO drivers to the `MODULES` array. Order matters slightly; put them early.

```
MODULES=(btrfs vfio_pci vfio vfio_iommu_type1)
```

**What these modules do:**

- `vfio`: The core Virtual Function I/O framework.
    
- `vfio_iommu_type1`: The specific IOMMU driver type used for x86 architecture.
    
- `vfio_pci`: The driver that actually binds to the PCI device (the GPU).
    

### 3.3 Verify HOOKS

Ensure `modconf` is present. This hook allows `mkinitcpio` to read the `.conf` files we are about to create in `/etc/modprobe.d/`.

```
HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)
```

## Phase 4: Modprobe Rules (The Safety Net)

Even though we added kernel parameters, configuring `modprobe` provides a secondary layer of configuration and allows us to set "Soft Dependencies" (load order).

### 4.1 Create/Edit VFIO Config

```bash
sudo nvim /etc/modprobe.d/vfio.conf
```

### 4.2 Add Configuration

Paste the following:


Explicitly assign IDs to vfio-pci (Redundant to kernel param, but good practice)
Ensure vfio-pci loads before nvidia (Just in case blacklist fails)
Disable proprietary drivers
```ini
options vfio-pci ids=10de:25a0,10de:2291
softdep nvidia pre: vfio-pci
softdep nouveau pre: vfio-pci
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
```
**Explanation:**

- `options`: passes arguments to the module when it loads.
    
- `softdep`: This says "If the system tries to load `nvidia`, load `vfio-pci` _first_." This ensures that even if you manually try to load NVIDIA drivers later, VFIO has already claimed the card.
    
- `blacklist`: Instructs the kernel not to load these modules automatically.
    

## Phase 5: Regeneration

Now that we have changed the recipes (`mkinitcpio.conf` and `modprobe.d`), we must bake the cake (the initramfs image).

```bash
sudo mkinitcpio -P
```

**What this does:**

- Generates a new initial ramdisk image based on your kernel version.
    
- `-P`: Process all installed presets (standard and fallback kernels).
    

**Action:** **Reboot your computer now.**
```bash
systemctl reboot
```
## Phase 6: Verification

After rebooting, verify that the isolation was successful.

### 6.1 Check Driver Binding

Run this to see which kernel driver is currently "In use" for your NVIDIA device ID.

```bash
lspci -nnk -d 10de:25a0
```

**Expected Output:**

```ini
Kernel driver in use: vfio-pci
Kernel modules: nouveau, nvidia_drm, nvidia
```

_If it says `Kernel driver in use: nvidia`, the isolation failed._

**OR**
```bash
lspci -k | grep -E "vfio-pci|NVIDIA"
```

> [!NOTE]- Expected outcome similar to this. 
> ```bash
>  lspci -k | grep -E "vfio-pci|NVIDIA"
> 01:00.0 VGA compatible controller: NVIDIA Corporation GA107M [GeForce RTX 3050 Ti Mobile] (rev a1)
> 	Kernel driver in use: vfio-pci
> 01:00.1 Audio device: NVIDIA Corporation GA107 High Definition Audio Controller (rev a1)
> 	Kernel driver in use: vfio-pci
> ```

### 6.2 Check IOMMU Grouping

Ensure the `vfio-pci` driver is correctly categorized in IOMMU groups.

```
sudo dmesg | grep -i vfio
```

> [!NOTE]- Expected Output
> ```ini
> sudo dmesg | grep -i vfio
> [sudo] password for dusk: 
> [    0.000000] Command line: initrd=\intel-ucode.img initrd=\initramfs-linux.img root=PARTUUID=8310a096-b9cf-4246-9fd8-91555a279f04 rw quiet zswap.enabled=0 rootfstype=btrfs rootflags=subvol=@ fsck.mode=skip pcie_aspm=force intel_iommu=on iommu=pt vfio-pci.ids=10de:25a0,10de:2291 module_blacklist=nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm,nouveau
> [    0.082317] Kernel command line: initrd=\intel-ucode.img initrd=\initramfs-linux.img root=PARTUUID=8310a096-b9cf-4246-9fd8-91555a279f04 rw quiet zswap.enabled=0 rootfstype=btrfs rootflags=subvol=@ fsck.mode=skip pcie_aspm=force intel_iommu=on iommu=pt vfio-pci.ids=10de:25a0,10de:2291 module_blacklist=nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm,nouveau
> [ 6106.148012] VFIO - User Level meta-driver version: 0.3
> [ 6106.156096] vfio-pci 0000:01:00.0: vgaarb: VGA decodes changed: olddecodes=io+mem,decodes=io+mem:owns=none
> [ 6106.156248] vfio_pci: add [10de:25a0[ffffffff:ffffffff]] class 0x000000/00000000
> [ 6106.156251] vfio_pci: add [10de:2291[ffffffff:ffffffff]] class 0x000000/00000000
> [ 6124.455667] vfio-pci 0000:01:00.0: enabling device (0000 -> 0003)
> [ 6124.455753] vfio-pci 0000:01:00.0: resetting
> ```

restart

## 7.0 Attach vfio-pci driver to nvidia

if vfio-pci drivers wherent  attached to the pcie devcies. you can add them with this command. 
```bash
sudo modprobe vfio-pci
```

## Appendix: Future Scenarios

### Changing to AMD GPU

If you swap hardware:

1. **Get IDs:** `lspci -nn` to get new AMD Vendor/Product IDs.
    
2. **Edit Bootloader:** Update `/boot/loader/entries/arch.conf` with new IDs.
    
3. **Edit Modprobe:** Update `/etc/modprobe.d/vfio.conf` with new IDs.
    
4. **Edit Blacklist:** Remove `blacklist nvidia` lines. Add `blacklist amdgpu` and `blacklist radeon` **ONLY** if you are passing through the primary card (unlikely on a laptop setup). usually, you just need the IDs for `vfio-pci`.
    
5. **Regenerate:** `sudo mkinitcpio -P`.
    

### Reverting (Undoing Isolation)

To give the GPU back to the host (e.g., for gaming on Linux):

1. Remove `vfio-pci.ids` and `module_blacklist` from `/boot/loader/entries/arch.conf`.
    
2. Remove (or comment out) contents of `/etc/modprobe.d/vfio.conf`.
    
3. Run `sudo mkinitcpio -P`.
    
4. Reboot.


