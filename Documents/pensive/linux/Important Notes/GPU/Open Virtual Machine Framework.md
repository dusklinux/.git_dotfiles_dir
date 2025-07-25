“Open Virtual Machine Firmware” (OVMF) is basically a UEFI-style “BIOS” for virtual machines. Here are the core ideas, in simple terms:
What OVMF Is

Just like a physical PC has BIOS or UEFI firmware that runs first and starts your operating system, a VM needs firmware too.

OVMF is an open-source implementation of UEFI (the modern replacement for legacy BIOS) designed specifically for QEMU/KVM virtual machines.

Why Use UEFI in a VM?

Larger disks & modern features: UEFI supports booting from disks larger than 2 TB, GPT partition tables, and Secure Boot—things legacy BIOS can’t do.

Better compatibility: Many modern guest OSes (like recent versions of Windows and Linux distributions) expect or prefer UEFI.

How OVMF Fits into PCI Passthrough

When you give a VM its own physical PCI device (e.g., a GPU), some graphics cards check for UEFI firmware on the host before they’ll initialize.

If you boot the VM with OVMF, the card “sees” UEFI and wakes up properly inside the VM. Without it, the card might refuse to turn on or show nothing.