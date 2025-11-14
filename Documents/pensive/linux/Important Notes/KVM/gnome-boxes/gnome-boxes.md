### Installation
```bash
sudo pacman -Syyu --needed gnome-boxes spice spice-gtk spice-protocol spice-vdagent gvfs-dnssd
```


open gnome-boxes once. but dont' install anything yet.

change the temp directory for os installation to zram

```bash
mkdir -p /mnt/zram1/boxes_vm/ && rmdir ~/.local/share/gnome-boxes/images && ln -nfs /mnt/zram1/boxes_vm $HOME/.local/share/gnome-boxes/images
```


