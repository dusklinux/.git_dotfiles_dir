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


reboot
```bash
systemctl reboot
```