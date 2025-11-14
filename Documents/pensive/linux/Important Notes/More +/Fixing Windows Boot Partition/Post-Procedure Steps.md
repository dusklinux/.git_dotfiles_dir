## 1. Finalizing the Windows Boot Repair

These steps will guide you out of the recovery environment and into your newly repaired Windows installation.

> [!NOTE] Completing the Repair
> Follow this sequence precisely to ensure your computer boots from the correct drive.

1.  **Close the Command Prompt**
    Click the 'X' in the top-right corner of the Command Prompt window or type `exit` and press Enter.

2.  **Exit Windows Setup**
    You will be returned to the initial Windows Setup screen. Click the 'X' in the top-right corner to close the wizard. A confirmation prompt will appear; click **Yes** to restart your computer.

3.  **Remove Installation Media**
    This is the most critical action during the restart process.

> [!WARNING] Eject Your USB/DVD Immediately
> You **must** remove the Windows installation media (USB drive or DVD) as the computer begins to restart.
>
> If you don't, the system may boot back into the installation environment instead of your internal hard drive, creating a loop.

Upon restarting, your machine should now load directly into the Windows Boot Manager, and your Windows installation will start normally.

---

## 2. Restoring the GRUB Menu (For Dual-Boot Systems)

If you dual-boot with Arch Linux (or another Linux distribution using GRUB), this repair will have reset your firmware's boot priority, making the Windows Boot Manager the default. To restore your familiar GRUB boot menu, you must update its configuration.

> [!TIP] Why this is necessary
> The UEFI firmware now points directly to Windows. You need to boot into Linux environment to tell GRUB where the repaired Windows installation is, which will add it back to the grub boot menu.

1.  **Regenerate the GRUB Configuration**
    This command scans for all bootable operating systems, including your newly fixed Windows installation, and creates a new configuration file.
    ```bash
    grub-mkconfig -o /boot/grub/grub.cfg
    ```
    You should see output confirming that it found "Windows Boot Manager".

## 3. Partition Cleanup (Optional but Recommended)

- Dont forget to re-unallocate partitions you formatted as f2fs or ext4 in the first step. If you didn't do that, then you can continue without doing anything. 

