 Part 4: Generating the Final GRUB Configuration

The final step is to generate the `grub.cfg` file. This file contains the actual menu entries and settings that GRUB reads at boot time.

### 1. Run the `grub-mkconfig` Command

This command automatically generates the configuration file based on your settings in `/etc/default/grub`, the installed kernels on your system, and the output from `os-prober` (if enabled).

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

> [!WARNING]+ Do Not Edit `grub.cfg` Manually
> The `/boot/grub/grub.cfg` file is auto-generated and should never be edited by hand. Any manual changes will be overwritten the next time you run `grub-mkconfig` (for example, after a kernel update). Always make your changes in `/etc/default/grub` and regenerate the file.

### 2. Verify the Output

Carefully watch the output of the `grub-mkconfig` command. It should report the kernels it found, for example:
- "Found linux image: /boot/vmlinuz-linux"
- "Found initrd image: /boot/intel-ucode.img /boot/initramfs-linux.img"

If you are dual-booting, it should also report finding other systems, such as "Found Windows Boot Manager on /dev/sdXY".

If you see errors or if your kernel or other OS is not detected, you must troubleshoot the issue before rebooting. You can inspect the generated file with `less /boot/grub/grub.cfg` to see what was created.