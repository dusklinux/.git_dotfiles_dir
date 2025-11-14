# Fixing the Windows Boot Menu: A Step-by-Step Guide

This guide provides a high-level overview of the manual process to repair the Windows bootloader. Each step corresponds to a detailed note that you can reference for specific commands and instructions.

---

### 1. [[Critical Prerequisite]]
> [!NOTE] **Goal: Prepare the Disk**
> Before beginning the repair, you must prepare the target disk. This involves using a partition manager (like GParted from a live Linux USB) to create a specific, small unallocated space for the new EFI partition. To ensure Windows uses this exact spot, you will temporarily format any other unallocated spaces with a filesystem that Windows won't recognize, such as `ext4`.

### 2. [[Prepare a Windows Installation Media]]
> [!NOTE] **Goal: Create a Bootable Repair Tool**
> You need a bootable Windows installation USB to access the recovery tools. This step guides you through creating one using Ventoy, a tool that lets you simply drag-and-drop the Windows ISO onto the USB drive.

### 3. [[Open Command Prompt in Windows Setup]]
> [!NOTE] **Goal: Access the Command Line**
> Boot your computer from the prepared USB. When the first "Windows Setup" screen appears, press the <kbd>Shift</kbd> + <kbd>F10</kbd> shortcut. This opens a Command Prompt window, which is the environment where you will perform the entire repair.

### 4. [[Preliminary Identification]]
> [!NOTE] **Goal: Locate Your Windows Installation**
> Inside the Command Prompt, you will use the `diskpart` utility to identify two key pieces of information: the physical disk number where Windows is installed and the drive letter assigned to your main Windows partition in the recovery environment (e.g., `C:`, `D:`, etc.). This information is critical for the following steps.

### 5. [[EFI partition synthesis]]
> [!NOTE] **Goal: Create the New EFI Partition**
> Using `diskpart`, you will now create the new home for your boot files. This involves carving out a 512 MB partition, formatting it with the required `FAT32` filesystem, and assigning it a temporary drive letter (like `S:`) so you can access it.

### 6. [[Boot File Reconstruction]]
> [!NOTE] **Goal: Rebuild the Bootloader**
> This is the core of the repair. You will use the `bcdboot` command to copy the essential boot files from your existing Windows installation onto the new EFI partition (`S:`). This command builds a new, functional Boot Configuration Data (BCD) store, which tells your computer how to load Windows.

### 7. [[Post-Procedure Steps]]
> [!NOTE] **Goal: Finalize and Clean Up**
> After the boot files are created, you will exit the Command Prompt and restart your computer, making sure to remove the installation USB. Your computer should now boot directly into Windows. This final step also covers restoring the GRUB menu for dual-boot systems and cleaning up the temporary partitions you created in Step 1.

