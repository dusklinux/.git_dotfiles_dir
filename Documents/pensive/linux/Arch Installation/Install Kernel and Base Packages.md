This crucial step uses the `pacstrap` script to install the base system, a Linux kernel, essential development tools, and firmware into your new Arch installation directory (`/mnt`).

### 1. Install Essential Packages

Run the following command to install the core components. We are including `nvim` (Neovim) as a text editor, but you can substitute it with `vim`, `nano`, or omit it.

```bash
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware nvim
```

> [!NOTE] Package Breakdown
> A brief explanation of the packages being installed:
> | Package | Description |
> |---|---|
> | `base` | The minimal set of packages for a functional base system. |
> | `base-devel` | Tools required for building packages (e.g., from the AUR). |
> | `linux` | The latest stable Arch Linux kernel. |
> | `linux-headers` | Header files for the kernel, needed to compile modules or drivers. |
> | `linux-firmware`| Contains firmware files required by many hardware devices. |
> | `nvim` | A modern, command-line text editor. |

> [!TIP] For Wired Ethernet Users
> If you only use a wired network connection, you can add `systemd-networkd` and `systemd-resolved` for a simple and effective network manager. Just add them to the end of the `pacstrap` command.

### 2. (Optional) Install Alternative Kernels

You can install other kernels alongside or instead of the default one. This is useful for specific use cases like performance tuning or long-term stability.

> [!WARNING]
> If you choose an alternative kernel *instead of* the default, remember to replace `linux-zen` and `linux-zen-headers` in the main command with your chosen kernel and its corresponding headers (e.g., `linux` and `linux-headers`).

#### Official Kernel

```bash
pacstrap /mnt linux linux-headers
```

#### Long-Term Support (LTS) Kernel
A good choice for servers or systems where stability is more important than having the latest features.

```bash
pacstrap /mnt linux-lts linux-lts-headers
```
