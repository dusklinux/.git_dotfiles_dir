# Enabling Modular Libvirt Daemons

In this step, we are configuring the "engine" that runs your virtual machines. We are switching from the old-school "Monolithic" mode to the modern "Modular" mode.

## Why are we doing this?

By default, many systems use a **Monolithic** daemon (`libvirtd`). This is like having one giant manager trying to do everyone's job at once—it handles storage, networks, and the VMs themselves. It works, but it can be heavy on system resources.

We are switching to **Modular** daemons. This is like having a team of specialists. If you aren't touching the network, the network manager sleeps. This makes your system faster and more efficient.

> [!INFO] Service Breakdown: What are we enabling?
> 
> You asked to see the individual services. Here is exactly what each piece of the puzzle does:
> 
> - **`virtqemud`** (QEMU Daemon): The most important one. It manages the actual "compute" part of the Virtual Machine (CPU/RAM).
>     
> - **`virtinterfaced`** (Interface Daemon): Manages the physical network interfaces on your host computer so the VM can see them.
>     
> - **`virtnetworkd`** (Network Daemon): Creates virtual networks (like a virtual router) inside your computer so VMs can talk to each other or the internet.
>     
> - **`virtnodedevd`** (Node Device Daemon): Handles physical hardware passthrough (like passing a USB drive or GPU directly to a VM).
>     
> - **`virtnwfilterd`** (Network Filter Daemon): Acts like a firewall, controlling network traffic rules for the VMs.
>     
> - **`virtsecretd`** (Secret Daemon): Safely stores passwords and encryption keys needed by your VMs.
>     
> - **`virtstoraged`** (Storage Daemon): Manages the virtual hard drives and storage pools.
>     

## Step 1: Enable the Services

We need to enable the service (`.service`) and the connection points (`.socket`) for every driver listed above.

Instead of typing 25+ commands manually, copy and paste this entire code block into your terminal. It loops through the list of drivers and enables them all at once.

```bash
for drv in qemu interface network nodedev nwfilter secret storage; do \
sudo systemctl enable virt${drv}d.service; \
sudo systemctl enable virt${drv}d{,-ro,-admin}.socket; \
done
```

then start it. yes do these sperately, enabling and starting not with the --now flag. and this will says some modules dont exist, you can safely ignore those. 
```bash
for drv in qemu interface network nodedev nwfilter secret storage; do \
sudo systemctl start virt${drv}d.service; \
sudo systemctl start virt${drv}d{,-ro,-admin}.socket; \
done
```

> [!NOTE]- This is what will output when you run it. 
> ```ini
> Created symlink '/etc/systemd/system/multi-user.target.wants/virtqemud.service' → '/usr/lib/systemd/system/virtqemud.service'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtqemud.socket' → '/usr/lib/systemd/system/virtqemud.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtqemud-ro.socket' → '/usr/lib/systemd/system/virtqemud-ro.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtqemud-admin.socket' → '/usr/lib/systemd/system/virtqemud-admin.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtlogd.socket' → '/usr/lib/systemd/system/virtlogd.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtlockd.socket' → '/usr/lib/systemd/system/virtlockd.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtlogd-admin.socket' → '/usr/lib/systemd/system/virtlogd-admin.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtlockd-admin.socket' → '/usr/lib/systemd/system/virtlockd-admin.socket'.
> Created symlink '/etc/systemd/system/multi-user.target.wants/virtinterfaced.service' → '/usr/lib/systemd/system/virtinterfaced.service'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtinterfaced.socket' → '/usr/lib/systemd/system/virtinterfaced.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtinterfaced-ro.socket' → '/usr/lib/systemd/system/virtinterfaced-ro.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtinterfaced-admin.socket' → '/usr/lib/systemd/system/virtinterfaced-admin.socket'.
> Created symlink '/etc/systemd/system/multi-user.target.wants/virtnetworkd.service' → '/usr/lib/systemd/system/virtnetworkd.service'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnetworkd.socket' → '/usr/lib/systemd/system/virtnetworkd.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnetworkd-ro.socket' → '/usr/lib/systemd/system/virtnetworkd-ro.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnetworkd-admin.socket' → '/usr/lib/systemd/system/virtnetworkd-admin.socket'.
> Created symlink '/etc/systemd/system/multi-user.target.wants/virtnodedevd.service' → '/usr/lib/systemd/system/virtnodedevd.service'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnodedevd.socket' → '/usr/lib/systemd/system/virtnodedevd.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnodedevd-ro.socket' → '/usr/lib/systemd/system/virtnodedevd-ro.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnodedevd-admin.socket' → '/usr/lib/systemd/system/virtnodedevd-admin.socket'.
> Created symlink '/etc/systemd/system/multi-user.target.wants/virtnwfilterd.service' → '/usr/lib/systemd/system/virtnwfilterd.service'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnwfilterd.socket' → '/usr/lib/systemd/system/virtnwfilterd.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnwfilterd-ro.socket' → '/usr/lib/systemd/system/virtnwfilterd-ro.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtnwfilterd-admin.socket' → '/usr/lib/systemd/system/virtnwfilterd-admin.socket'.
> Created symlink '/etc/systemd/system/multi-user.target.wants/virtsecretd.service' → '/usr/lib/systemd/system/virtsecretd.service'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtsecretd.socket' → '/usr/lib/systemd/system/virtsecretd.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtsecretd-ro.socket' → '/usr/lib/systemd/system/virtsecretd-ro.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtsecretd-admin.socket' → '/usr/lib/systemd/system/virtsecretd-admin.socket'.
> Created symlink '/etc/systemd/system/multi-user.target.wants/virtstoraged.service' → '/usr/lib/systemd/system/virtstoraged.service'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtstoraged.socket' → '/usr/lib/systemd/system/virtstoraged.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtstoraged-ro.socket' → '/usr/lib/systemd/system/virtstoraged-ro.socket'.
> Created symlink '/etc/systemd/system/sockets.target.wants/virtstoraged-admin.socket' → '/usr/lib/systemd/system/virtstoraged-admin.socket'.
> ```


Make sure the monolotic daemon is dead and not enabled
```bash
# Ensure the "old style" monolithic daemon is stopped and masked
sudo systemctl stop libvirtd
sudo systemctl disable libvirtd
sudo systemctl mask libvirtd
```

## Step 2: Apply Changes

For these changes to fully take effect and for the new daemons to replace the old ones, you must reboot your computer.

```
systemctl reboot
```

## Appendix: How to Undo (Disable)

> [!WARNING] Only run this if you messed up or want to stop using KVM.
> 
> If you need to revert these changes later, you can use the following commands to stop and disable the modular daemons.

**1. Stop the running services:**

```bash
for drv in qemu interface network nodedev nwfilter secret storage; do \
sudo systemctl stop "virt${drv}d.service" "virt${drv}d"{,-ro,-admin}.socket; \
done
```

**2. Disable them from starting on boot:**

```bash
for drv in qemu interface network nodedev nwfilter secret storage; do \
sudo systemctl disable virt${drv}d.service; \
sudo systemctl disable virt${drv}d{,-ro,-admin}.socket; \
done
```