Enable the Modular libvirt Daemon

There are two types of libvirt daemons: monolithic and modular. The type of daemon(s) you use affects how granularly you can configure individual virtualization drivers.

The traditional monolithic libvirt daemon, libvirtd, manages a wide range of virtualization drivers via centralized hypervisor configuration. However, this may result in inefficient use of system resources.

In contrast, the newly introduced modular libvirt provides a specific daemon for each virtualization driver. As a result, modular libvirt daemons offer more flexibility in fine-tuning libvirt resource management.

While most Linux distributions have started to offer a modular option, at the time of writing, Ubuntu and Debian continue to offer only a monolithic daemon.

Arch Linux:

```bash
for drv in qemu interface network nodedev nwfilter secret storage; do \
sudo systemctl enable virt${drv}d.service; \
sudo systemctl enable virt${drv}d{,-ro,-admin}.socket; \
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

reboot
```bash
systemctl reboot
```


if you want to disable it later run these commands 


```bash
for drv in qemu interface network nodedev nwfilter secret storage; do \
sudo systemctl stop "virt${drv}d.service" "virt${drv}d"{,-ro,-admin}.socket; \
sudo systemctl disable "virt${drv}d.service" "virt${drv}d"{,-ro,-admin}.socket; \
done
```

```bash
for drv in qemu interface network nodedev nwfilter secret storage; do \
sudo systemctl disable virt${drv}d.service; \
sudo systemctl disable virt${drv}d{,-ro,-admin}.socket; \
done
```