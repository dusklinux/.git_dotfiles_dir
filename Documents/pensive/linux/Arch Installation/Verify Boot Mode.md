---
step: 
subject: 
context:
  - setup
  - arch install
type: guide
status: in-progress
---

Before proceeding with partitioning, it is crucial to confirm that the Arch Linux installation media has booted in **UEFI mode**. The method used for disk partitioning and bootloader installation depends heavily on the system's boot mode.

### Verification Commands

To check the boot mode, open a terminal and run one of the following commands. The existence of the `/sys/firmware/efi` directory is the key indicator of a UEFI boot.

#### Method 1: Check Firmware Platform Size

This command displays the bitness of the UEFI firmware.

```sh
cat /sys/firmware/efi/fw_platform_size
```

- **Expected Output:** The command should output `64` for a 64-bit UEFI boot or `32` for a 32-bit UEFI boot.

#### Method 2: List EFI Variables

This command attempts to list the contents of the `efivars` directory, which only exists in a UEFI environment.

```sh
ls /sys/firmware/efi/efivars
```

- **Expected Output:** The command should successfully list a series of files and directories.

> [!TIP]
> You only need one of these commands to succeed. If either one produces the expected output, you have successfully booted in UEFI mode and can proceed to the next step.

> [!WARNING] What if the commands fail?
> If you receive an error such as `No such file or directory`, your system has likely booted in legacy **BIOS** or **Compatibility Support Module (CSM)** mode.
>
> To fix this, you must:
> 1. Reboot the system.
> 2. Enter the firmware setup utility (often by pressing `F2`, `F10`, or `Del` during startup).
> 3. Disable CSM / Legacy Boot mode.
> 4. Ensure UEFI Boot is enabled and set as the priority.
> 5. Save changes and boot from the installation media again.
