# KVM Configuration: Overview & Firmware

This section covers the foundational architecture settings for your virtual machine. These settings are critical for modern operating system support (like Windows 11) and hardware performance.

## 1. Access the Overview Section

Open your virtual machine details in `virt-manager` and navigate to the **Overview** section in the left-hand sidebar.

## 2. Chipset Configuration

Locate the **Chipset** dropdown menu.

- **Action:** Change the Chipset to **Q35**.
    

> [!INFO] Why use Q35?
> 
> The Q35 chipset is the modern standard that natively supports PCIe. It provides significantly improved support for PCI-E pass-through, which is essential if you plan to pass physical hardware (like a GPU) to your virtual machine later.

## 3. Firmware Configuration

Locate the **Firmware** dropdown menu.

- **Action:** Change the Firmware to **UEFI** (often listed as `UEFI x86_64` or `OVMF`).
    

> [!TIP] Windows 11 Requirement
> 
> The UEFI firmware option is mandatory if you plan to install Windows 11, as it enables the required Secure Boot functionality.

### Important: Snapshot Limitations

Changing to UEFI affects how you can save the state of your virtual machine.

> [!WARNING] Snapshot Restriction
> 
> When using UEFI firmware, you cannot take internal snapshots while the Virtual Machine is running.
> 
> - **To take a snapshot:** You must fully **shut down** the guest VM first.
>